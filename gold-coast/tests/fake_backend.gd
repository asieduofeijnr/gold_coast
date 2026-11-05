class_name FakeBackend
extends RefCounted
## A pretend Gold Coast server for tests, with the same functions as
## NakamaBackend. It keeps accounts in memory, with no internet, and its
## mistakes go through NakamaBackend.message_for(), like the real server's.
## Set `reachable` to false to pretend the server can't be reached. In its
## pretend town, a test plays the other players (someone_moved(), someone_left()).

signal player_moved(id: String, username: String, move: Dictionary)
signal player_left(id: String)
signal world_clock(minutes: float)

var accounts := {} # email -> {"password", "username", "display_name"}
var reachable := true
## What it's been asked, in order: "sign_up", "log_in", "restore", "log_out".
var calls: Array[String] = []
## The extra details the last sign-up sent (name, birthdate, terms).
var last_vars := {}
## Whether she's in the pretend town, and every move she's told it.
var in_town := false
var moves: Array[Dictionary] = []


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
			"username": account.username, "display_name": account.display_name, "email": email}


func _problem(message: String, status: int, grpc: int, signing_up: bool) -> Dictionary:
	return NakamaBackend.failure(NakamaException.new(message, status, grpc), signing_up)
