extends Node
## Gold Coast's link to its server (Nakama: see server/README.md). It makes
## accounts, logs players in and out, remembers the login in the browser
## (ACCOUNT_FILE), so they stay logged in between visits, and joins the shared
## town. (Cloud saves come next.)
##
## It reaches the server through a "backend": NakamaBackend for the real one,
## or a pretend one in tests (tests/fake_backend.gd). Nothing in the game waits
## for it: with no server, no internet, or "Play offline", the game still runs
## and saves in the browser.

## Sent when the player logs in or out, or chooses to play offline.
signal account_changed
## Another player in the shared town moved (or was there when she joined), or
## left it. `id` is their connection's; `move` is what their game sent.
signal town_player_moved(id: String, username: String, move: Dictionary)
signal town_player_left(id: String)
## The town told the time again (see world_minutes()).
signal world_clock_changed

## The terms a new account agrees to. The server checks for the same
## (server/modules/gold_coast.lua), so change both together.
const TERMS_VERSION := "2026-10-30"
const MIN_AGE := 18
const ACCOUNT_FILE := "user://gold_coast_account.json"
## Passwords too easy to guess, even with 8 characters.
const EASY_PASSWORDS := ["12345678", "123456789", "1234567890", "password", "password1", "qwertyui",
		"qwerty123", "11111111", "00000000", "iloveyou", "goldcoast", "abcd1234"]

## Where the server is: this computer while we build it, or the online one
## (LiveServer) for the game on the internet (see use_server_for()).
var host := "127.0.0.1"
var port := 7350
var scheme := "http"
var server_key := "defaultkey"

## How it reaches the server (tests give it a pretend one).
var backend: Object:
	set(value):
		backend = value
		backend.player_moved.connect(_on_player_moved)
		backend.player_left.connect(_on_player_left)
		backend.world_clock.connect(_on_world_clock)
## Where it remembers the login (tests use their own file).
var account_file := ACCOUNT_FILE
## The logged-in player's username (her name in town), name, and email, or "".
var username := ""
var display_name := ""
var email := ""
## Whether the player chose to play offline, without an account, this time.
var offline := false
## Whether she's in the shared town, and who else is: their id -> {"username",
## "move"} (the latest one).
var in_town := false
var town_players := {}
## Whether the town has told the time since she joined (see world_minutes()).
var world_clock_known := false

var _token := ""
var _refresh_token := ""
var _joining := false
# The town's time of day when it last told it, and when that was (in msec).
var _world_minutes := 0.0
var _world_told_at := 0


func _ready() -> void:
	var page_host := String(JavaScriptBridge.eval("location.hostname")) if OS.has_feature("web") else ""
	if OS.has_feature("web"):
		use_server_for(page_host)
	if backend == null:
		backend = NakamaBackend.new(host, port, scheme, server_key)
	# Without an online server, the game on itch.io can't reach the one on the
	# computer that made it, so there it plays offline.
	if OS.has_feature("web") and not can_reach(host, page_host):
		offline = true


## Points the game at the online server when it's a web page on the internet
## (like itch.io's) and there is one (LiveServer.HOST). A page served on this
## computer keeps this computer's server.
func use_server_for(page_host: String, live_host: String = LiveServer.HOST, live_key: String = LiveServer.SERVER_KEY) -> void:
	if live_host == "" or page_host in ["127.0.0.1", "localhost", ""]:
		return
	host = live_host
	port = 443
	scheme = "https"
	server_key = live_key


func is_logged_in() -> bool:
	return username != ""


## Whether a login from before is kept in this browser.
func has_saved_login() -> bool:
	return FileAccess.file_exists(account_file)


## Whether the player has chosen how to play: logged in, or offline.
func is_ready_to_play() -> bool:
	return is_logged_in() or offline


## Makes an account from the sign-up form, and logs in. `form` has "name",
## "username", "password", "email", "birthdate" ("YYYY-MM-DD"), and "agreed"
## (the terms box). Returns "" if it worked, or what went wrong, in plain
## words. (Check the form with check_sign_up() first.)
func sign_up(form: Dictionary) -> String:
	var result: Dictionary = await backend.sign_up(String(form.email).strip_edges(), form.password,
			String(form.username).strip_edges(),
			{"name": String(form.name).strip_edges(), "birthdate": form.birthdate, "terms": TERMS_VERSION})
	return _use(result)


## Logs in to an account. Returns "" if it worked, or what went wrong.
func log_in(login_email: String, password: String) -> String:
	return _use(await backend.log_in(login_email.strip_edges(), password))


## Logs in again with the login kept from last time. Returns "" if it worked,
## or what to tell the player: if the server can't be reached, that (and the
## login is kept for next time); if the login no longer works, to log in
## again (and the login is forgotten).
func restore() -> String:
	var saved: Variant = null
	if has_saved_login():
		saved = JSON.parse_string(FileAccess.get_file_as_string(account_file))
	if not saved is Dictionary or not saved.has("token"):
		DirAccess.remove_absolute(account_file)
		return "Please log in again."
	var result: Dictionary = await backend.restore(saved.token, saved.get("refresh_token", ""))
	if _use(result) == "":
		return ""
	if result.get("unreachable", false):
		return String(result.error)
	DirAccess.remove_absolute(account_file)
	return "Please log in again."


## Joins the shared town, if she's logged in (and not there already). If the
## server can't be reached, she just isn't in it: the game carries on.
func join_town() -> void:
	if in_town or _joining or not is_logged_in():
		return
	_joining = true
	var problem: String = await backend.join_town(_token, _refresh_token)
	_joining = false
	in_town = problem == ""


func leave_town() -> void:
	if not in_town:
		return
	backend.leave_town()
	in_town = false
	world_clock_known = false
	GameState.shared_clock = false
	for id: String in town_players.keys():
		town_player_left.emit(id)
	town_players.clear()


## The shared town's time of day now, in game minutes since midnight: what it
## last told, plus the time since (its clock goes at a game minute for each
## real second).
func world_minutes() -> float:
	return fposmod(_world_minutes + (Time.get_ticks_msec() - _world_told_at) / 1000.0, GameState.MINUTES_PER_DAY)


## Tells the town where she is (see TownPlayers.move_of()).
func send_move(move: Dictionary) -> void:
	if in_town:
		backend.send_move(move)


## Logs out, and forgets the login in this browser.
func log_out() -> void:
	leave_town()
	if is_logged_in():
		backend.log_out(_token, _refresh_token) # not waited for: the game carries on
	_token = ""
	_refresh_token = ""
	username = ""
	display_name = ""
	email = ""
	offline = false
	DirAccess.remove_absolute(account_file)
	account_changed.emit()


## Plays without an account this time: single player, saved in the browser.
func play_offline() -> void:
	offline = true
	account_changed.emit()


## Whether a game in a browser, on a page from `page_host`, can reach a server
## at `server_host`. A server on "this computer" (127.0.0.1) can only be
## reached by a page from this computer too.
static func can_reach(server_host: String, page_host: String) -> bool:
	var here := ["127.0.0.1", "localhost", ""]
	return server_host not in here or page_host in here


## What's wrong with the sign-up form, field by field (its keys are the form's
## keys), in plain words. Empty if it's all fine.
static func check_sign_up(form: Dictionary) -> Dictionary:
	var problems := {}
	if String(form.get("name", "")).strip_edges() == "":
		problems["name"] = "Please give your name."
	var wanted := String(form.get("username", "")).strip_edges()
	var valid_username := RegEx.create_from_string("^[a-z0-9_]{3,20}$")
	if valid_username.search(wanted) == null:
		problems["username"] = "3 to 20 small letters, numbers, or underscores, like ama_osu."
	var password := String(form.get("password", ""))
	if password.length() < 8:
		problems["password"] = "8 or more characters, please."
	elif password.to_lower() in EASY_PASSWORDS:
		problems["password"] = "That one's too easy to guess. Try another."
	var valid_email := RegEx.create_from_string("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")
	if valid_email.search(String(form.get("email", "")).strip_edges()) == null:
		problems["email"] = "That doesn't look like an email address."
	var age := age_on_today(String(form.get("birthdate", "")))
	if age < 0:
		problems["birthdate"] = "Please give your date of birth."
	elif age < MIN_AGE:
		problems["birthdate"] = "Gold Coast is for players 18 and older."
	if not form.get("agreed", false):
		problems["agreed"] = "Please tick the box to agree."
	return problems


## How old someone born on `birthdate` ("YYYY-MM-DD") is today, in whole
## years, or -1 if it isn't a real date.
static func age_on_today(birthdate: String) -> int:
	var parts := birthdate.split("-")
	if parts.size() != 3 or not parts[0].is_valid_int() or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return -1
	var year := parts[0].to_int()
	var month := parts[1].to_int()
	var day := parts[2].to_int()
	if month < 1 or month > 12 or day < 1 or day > days_in_month(month, year):
		return -1
	var today := Time.get_date_dict_from_system()
	var age: int = today.year - year
	if today.month < month or (today.month == month and today.day < day):
		age -= 1
	return age


## How many days `month` (1 to 12) has in `year`.
static func days_in_month(month: int, year: int) -> int:
	if month == 2:
		return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
	return 30 if month in [4, 6, 9, 11] else 31


func _on_player_moved(id: String, player_username: String, move: Dictionary) -> void:
	town_players[id] = {"username": player_username, "move": move}
	town_player_moved.emit(id, player_username, move)


func _on_world_clock(town_minutes: float) -> void:
	_world_minutes = town_minutes
	_world_told_at = Time.get_ticks_msec()
	world_clock_known = true
	world_clock_changed.emit()


func _on_player_left(id: String) -> void:
	town_players.erase(id)
	town_player_left.emit(id)


# Takes in what the server said. If it worked, the player is logged in, and the
# login is kept for next time.
func _use(result: Dictionary) -> String:
	if not result.get("ok", false):
		return String(result.get("error", "Something went wrong. Please try again."))
	_token = result.token
	_refresh_token = result.refresh_token
	username = result.username
	display_name = result.display_name
	email = result.email
	offline = false
	var file := FileAccess.open(account_file, FileAccess.WRITE)
	file.store_string(JSON.stringify({"token": _token, "refresh_token": _refresh_token}))
	file.close()
	account_changed.emit()
	return ""
