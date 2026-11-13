class_name NakamaBackend
extends RefCounted
## Online's way to the real server, through the Nakama client
## (addons/com.heroiclabs.nakama). Tests use a pretend backend instead
## (tests/fake_backend.gd) with the same functions.
##
## The account functions return a Dictionary: {"ok": true, "token": ...,
## "refresh_token": ..., "user_id": ..., "username": ..., "display_name": ...,
## "email": ...} when it worked, or {"ok": false, "error": what went wrong, in
## plain words, "unreachable": whether that was because the server couldn't be
## reached}.
##
## Cloud saves (see Online and CloudSave) keep her saved game in the server's
## storage: one object for each account, in the "saves" collection, that only
## she can read or change. read_save() and write_save() return the login's
## tokens too, in case the client renewed them on the way.
##
## The shared town (server/modules/town.lua) goes over a live connection (a
## socket): join_town(), send_move(), and leave_town(), and the signals say
## where the other players are.

## Another player in the town moved (or was there when she joined). `id` is
## their connection's, `move` what their game sent (see TownPlayers.move_of()).
signal player_moved(id: String, username: String, move: Dictionary)
## Another player left the town.
signal player_left(id: String)
## The town's clock: its time of day, in game minutes since midnight.
signal world_clock(minutes: float)

# gRPC error codes the server sends back.
const ALREADY_EXISTS := 6
const NOT_FOUND := 5
const UNAUTHENTICATED := 16
const INVALID_ARGUMENT := 3
const PERMISSION_DENIED := 7
## The town's messages: "here's where I am", and the town's time of day.
const OP_MOVE := 1
const OP_CLOCK := 2
## Where her save is kept in the server's storage: the collection, and its key there.
const SAVES := "saves"
const SAVE_KEY := "game"
## Storage permissions: OWNER_ONLY (1) means only the account that owns it can
## read it (or change it); 0 would be the server alone, 2 everyone.
const OWNER_ONLY := 1

var _client: NakamaClient
var _socket: NakamaSocket
var _town_id := ""
var _me := "" # this connection's id in the town


func _init(host: String, port: int, scheme: String, server_key: String) -> void:
	_client = Nakama.create_client(server_key, host, port, scheme, 10, NakamaLogger.LOG_LEVEL.ERROR)


## Makes an account (the server checks `vars`: see server/modules/gold_coast.lua).
func sign_up(email: String, password: String, username: String, vars: Dictionary) -> Dictionary:
	var session: NakamaSession = await _client.authenticate_email_async(email, password, username, true, vars)
	return await _finish(session, true)


func log_in(email: String, password: String) -> Dictionary:
	var session: NakamaSession = await _client.authenticate_email_async(email, password, null, false)
	return await _finish(session, false)


## Logs in again with a login kept from before, renewing it if it's run out.
func restore(token: String, refresh_token: String) -> Dictionary:
	var session := NakamaSession.new(token, false, refresh_token)
	if session.is_expired():
		session = await _client.session_refresh_async(session)
	return await _finish(session, false)


func log_out(token: String, refresh_token: String) -> void:
	await _client.session_logout_async(NakamaSession.new(token, false, refresh_token))


## Her save in the cloud: {"ok": true, "save": the saved game (a Dictionary),
## or null if there isn't one, "version": its version ("" if there isn't one),
## "token": ..., "refresh_token": ...}, or a failure.
func read_save(token: String, refresh_token: String) -> Dictionary:
	var session := NakamaSession.new(token, false, refresh_token)
	var read: NakamaAPI.ApiStorageObjects = await _client.read_storage_objects_async(session,
			[NakamaStorageObjectId.new(SAVES, SAVE_KEY, session.user_id)])
	if read.is_exception():
		return failure(read.get_exception(), false)
	var result := {"ok": true, "save": null, "version": "", "token": session.token,
			"refresh_token": session.refresh_token}
	for stored: NakamaAPI.ApiStorageObject in read.objects:
		var json := JSON.new()
		result.save = json.data if json.parse(stored.value) == OK else {} # {}: not a saved game
		result.version = stored.version
	return result


## Puts `text` (the saved game's file) in the cloud as her save, if the copy
## there is still `version` ("*": if there isn't one yet), so it never writes
## over a save another computer put there in the meantime. Returns {"ok": true,
## "version": the new copy's version, "token": ..., "refresh_token": ...}, or a
## failure, with "conflict": true if the copy there had changed.
func write_save(token: String, refresh_token: String, text: String, version: String) -> Dictionary:
	var session := NakamaSession.new(token, false, refresh_token)
	var wrote: NakamaAPI.ApiStorageObjectAcks = await _client.write_storage_objects_async(session,
			[save_object(text, version)])
	if wrote.is_exception():
		var problem := wrote.get_exception()
		var result := failure(problem, false)
		# Nakama: "Storage write rejected - version check failed."
		result["conflict"] = problem.grpc_status_code == INVALID_ARGUMENT and "version" in problem.message
		return result
	var new_version := ""
	for ack: NakamaAPI.ApiStorageObjectAck in wrote.acks:
		new_version = ack.version
	return {"ok": true, "version": new_version, "token": session.token, "refresh_token": session.refresh_token}


## The storage object her save goes up as: in SAVES, at SAVE_KEY, that only she
## can read or change.
static func save_object(text: String, version: String) -> NakamaWriteStorageObject:
	return NakamaWriteStorageObject.new(SAVES, SAVE_KEY, OWNER_ONLY, OWNER_ONLY, text, version)


## Connects to the server and joins the shared town. Returns "" if it worked,
## or what went wrong.
func join_town(token: String, refresh_token: String) -> String:
	_socket = Nakama.create_socket_from(_client)
	_socket.received_match_state.connect(_on_town_message)
	_socket.received_match_presence.connect(_on_town_comings_and_goings)
	var connected: NakamaAsyncResult = await _socket.connect_async(NakamaSession.new(token, false, refresh_token))
	if connected.is_exception():
		return message_for(connected.get_exception(), false)
	var found: NakamaAPI.ApiRpc = await _socket.rpc_async("town")
	if found.is_exception():
		return message_for(found.get_exception(), false)
	var reply: Variant = JSON.parse_string(found.payload)
	if not reply is Dictionary or not reply.has("match_id"):
		return "Something went wrong on the server. Please try again."
	var town: NakamaRTAPI.Match = await _socket.join_match_async(reply.match_id)
	if town.is_exception():
		return message_for(town.get_exception(), false)
	_town_id = town.match_id
	_me = town.self_user.session_id
	return ""


func leave_town() -> void:
	if _socket == null:
		return
	if _town_id != "":
		_socket.leave_match_async(_town_id)
	_socket.close()
	_socket = null
	_town_id = ""


## Tells the town where she is (not waiting for an answer).
func send_move(move: Dictionary) -> void:
	if _socket != null and _town_id != "":
		_socket.send_match_state_async(_town_id, OP_MOVE, JSON.stringify(move))


func _on_town_message(message: NakamaRTAPI.MatchData) -> void:
	if message.op_code == OP_CLOCK:
		var clock: Variant = JSON.parse_string(message.data)
		if clock is Dictionary and clock.has("minutes"):
			world_clock.emit(float(clock.minutes))
		return
	if message.op_code != OP_MOVE or message.presence == null or message.presence.session_id == _me:
		return
	var move: Variant = JSON.parse_string(message.data)
	if move is Dictionary:
		player_moved.emit(message.presence.session_id, message.presence.username, move)


func _on_town_comings_and_goings(event: NakamaRTAPI.MatchPresenceEvent) -> void:
	for presence: NakamaRTAPI.UserPresence in event.leaves:
		player_left.emit(presence.session_id)


func _finish(session: NakamaSession, signing_up: bool) -> Dictionary:
	if session.is_exception():
		return failure(session.get_exception(), signing_up)
	var account: NakamaAPI.ApiAccount = await _client.get_account_async(session)
	if account.is_exception():
		return failure(account.get_exception(), signing_up)
	return {"ok": true, "token": session.token, "refresh_token": session.refresh_token, "user_id": account.user.id,
			"username": account.user.username, "display_name": account.user.display_name, "email": account.email}


## What a function returns when it didn't work.
static func failure(problem: NakamaException, signing_up: bool) -> Dictionary:
	return {"ok": false, "error": message_for(problem, signing_up), "unreachable": problem.grpc_status_code == -1}


## What went wrong, in plain words, for the account screen.
static func message_for(problem: NakamaException, signing_up: bool) -> String:
	match problem.grpc_status_code:
		ALREADY_EXISTS:
			if "sername" in problem.message:
				return "That username is taken. Try another one."
			return "There's already an account with that email. Log in instead."
		UNAUTHENTICATED:
			if signing_up:
				return "There's already an account with that email. Log in instead."
			return "That email and password don't match."
		NOT_FOUND:
			return "There's no account with that email. Make one in Create account."
		INVALID_ARGUMENT, PERMISSION_DENIED:
			return problem.message # the server's rules say what's wrong
		-1:
			return "Can't reach the Gold Coast server. Check your internet, or play offline."
	return "Something went wrong on the server. Please try again."
