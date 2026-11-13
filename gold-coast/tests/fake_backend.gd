class_name FakeBackend
extends RefCounted
## A pretend Gold Coast server for tests, with the same functions as
## NakamaBackend. It keeps accounts in memory, with no internet, and its
## mistakes go through NakamaBackend.message_for(), like the real server's.
## Set `reachable` to false to pretend the server can't be reached. In its
## pretend town, a test plays the other players (someone_moved(), someone_left()).
## Its pretend cloud keeps each account's save (`saves`), with versions like
## Nakama's storage; a test plays another computer with put_save().

signal player_moved(id: String, username: String, move: Dictionary)
signal player_left(id: String)
signal world_clock(minutes: float)

var accounts := {} # email -> {"password", "username", "display_name"}
var reachable := true
## What it's been asked, in order: "sign_up", "log_in", "restore", "log_out",
## "read_save", "write_save", ...
var calls: Array[String] = []
## The extra details the last sign-up sent (name, birthdate, terms).
var last_vars := {}
## Whether she's in the pretend town, and every move she's told it.
var in_town := false
var moves: Array[Dictionary] = []
## Each account's save in the pretend cloud: username -> {"text": the saved
## game's file, "version": its version}.
var saves := {}
## How long each trip to the pretend cloud takes, in seconds (0: none at all).
var delay := 0.0
## Something that happens just before the next save arrives in the pretend
## cloud, once: a test plays another computer whose save gets there first.
var before_next_write := Callable()


func sign_up(email: String, password: String, username: String, vars: Dictionary) -> Dictionary:
	calls.append("sign_up")
	last_vars = vars
	if not reachable:
		return _problem("HTTPRequest failed!", -1, -1, true)
	for account: Dictionary in accounts.values():
		if account.username == username:
			return _problem("Username is already in use.", 409, NakamaBackend.ALREADY_EXISTS, true)
	if accounts.has(email):
		return _problem("Invalid credentials.", 401, NakamaBackend.UNAUTHENTICATED, true)
	if Online.age_on_today(String(vars.get("birthdate", ""))) < Online.MIN_AGE:
		return _problem("Gold Coast is for players 18 and older.", 403, NakamaBackend.PERMISSION_DENIED, true)
	accounts[email] = {"password": password, "username": username, "display_name": vars.get("name", "")}
	return _session(email)


func log_in(email: String, password: String) -> Dictionary:
	calls.append("log_in")
	if not reachable:
		return _problem("HTTPRequest failed!", -1, -1, false)
	if not accounts.has(email):
		return _problem("User account not found.", 404, NakamaBackend.NOT_FOUND, false)
	if accounts[email].password != password:
		return _problem("Invalid credentials.", 401, NakamaBackend.UNAUTHENTICATED, false)
	return _session(email)


func restore(token: String, _refresh_token: String) -> Dictionary:
	calls.append("restore")
	if not reachable:
		return _problem("HTTPRequest failed!", -1, -1, false)
	for email: String in accounts:
		if token == "token-" + String(accounts[email].username):
			return _session(email)
	return _problem("Refresh token invalid or expired.", 401, NakamaBackend.UNAUTHENTICATED, false)


func log_out(_token: String, _refresh_token: String) -> void:
	calls.append("log_out")


func read_save(token: String, _refresh_token: String) -> Dictionary:
	calls.append("read_save")
	await _trip()
	var username := _username_for(token)
	if not reachable:
		return _problem("HTTPRequest failed!", -1, -1, false)
	if username == "":
		return _problem("Auth token invalid", 401, NakamaBackend.UNAUTHENTICATED, false)
	if not saves.has(username):
		return {"ok": true, "save": null, "version": "", "token": token, "refresh_token": _refresh_token}
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(saves[username].text) == OK else {}
	return {"ok": true, "save": parsed, "version": saves[username].version, "token": token,
			"refresh_token": _refresh_token}


func write_save(token: String, _refresh_token: String, text: String, version: String) -> Dictionary:
	calls.append("write_save")
	await _trip()
	var username := _username_for(token)
	if not reachable:
		return _problem("HTTPRequest failed!", -1, -1, false)
	if username == "":
		return _problem("Auth token invalid", 401, NakamaBackend.UNAUTHENTICATED, false)
	if before_next_write.is_valid():
		var first := before_next_write
		before_next_write = Callable()
		first.call()
	var there: String = saves[username].version if saves.has(username) else ""
	if (version == "*" and there != "") or (version != "" and version != "*" and version != there):
		var rejected := _problem("Storage write rejected - version check failed.", 400,
				NakamaBackend.INVALID_ARGUMENT, false)
		rejected["conflict"] = true
		return rejected
	put_save(username, text)
	return {"ok": true, "version": saves[username].version, "token": token, "refresh_token": _refresh_token}


## Puts a save in an account's pretend cloud, as another computer would (or
## as write_save() does): `save` is the saved game's file, or its Dictionary.
func put_save(username: String, save: Variant) -> void:
	var text: String = save if save is String else JSON.stringify(save, "\t")
	saves[username] = {"text": text, "version": text.md5_text()} # like Nakama's: a code made from the save


func join_town(_token: String, _refresh_token: String) -> String:
	calls.append("join_town")
	if not reachable:
		return NakamaBackend.message_for(NakamaException.new("HTTPRequest failed!", -1, -1), false)
	in_town = true
	return ""


func leave_town() -> void:
	calls.append("leave_town")
	in_town = false


func send_move(move: Dictionary) -> void:
	moves.append(move)


## Another (pretend) player in the town moves, as the server would say.
func someone_moved(id: String, username: String, move: Dictionary) -> void:
	player_moved.emit(id, username, move)


## The (pretend) town tells the time: `minutes` since midnight.
func tell_time(minutes: float) -> void:
	world_clock.emit(minutes)


## Another (pretend) player leaves the town.
func someone_left(id: String) -> void:
	player_left.emit(id)


func _session(email: String) -> Dictionary:
	var account: Dictionary = accounts[email]
	return {"ok": true, "token": "token-" + String(account.username), "refresh_token": "refresh-" + String(account.username),
			"user_id": "id-" + String(account.username), "username": account.username,
			"display_name": account.display_name, "email": email}


# The username a pretend login's token belongs to ("" if nobody's).
func _username_for(token: String) -> String:
	for account: Dictionary in accounts.values():
		if token == "token-" + String(account.username):
			return account.username
	return ""


# A trip to the pretend cloud: none at all, or `delay` seconds (even while the
# game is paused, like the real client).
func _trip() -> void:
	if delay > 0.0:
		await (Engine.get_main_loop() as SceneTree).create_timer(delay, true).timeout


func _problem(message: String, status: int, grpc: int, signing_up: bool) -> Dictionary:
	return NakamaBackend.failure(NakamaException.new(message, status, grpc), signing_up)
