extends Node
## Gold Coast's link to its server (Nakama: see server/README.md). It makes
## accounts, logs players in and out, remembers the login in the browser
## (ACCOUNT_FILE), so they stay logged in between visits, joins the shared
## town, and keeps a copy of her saved game in her account: a cloud save.
##
## Cloud saves, this computer first: every save goes to this computer (the
## browser) first, as before, then a copy goes up to the cloud in the
## background; with no internet, it goes up later. When she logs in (on the
## title screen), check_cloud() brings the two into step: whichever changed
## since they were last the same is kept, so logging in on another computer
## brings her save, and if both changed, she chooses which to keep. The rules
## are CloudSave's; `cloud` says how it stands, for the little cloud on her phone.
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
## How her cloud save stands has changed (see `cloud`).
signal cloud_changed

## The terms a new account agrees to. The server checks for the same
## (server/modules/gold_coast.lua), so change both together.
const TERMS_VERSION := "2026-10-30"
const MIN_AGE := 18
const ACCOUNT_FILE := "user://gold_coast_account.json"
## The login kept for the online server, apart from this computer's, so trying
## one never logs you out of the other.
const LIVE_ACCOUNT_FILE := "user://gold_coast_account_online.json"
## This computer's notes on each account's cloud save: where the save here and
## the cloud's stood when they were last the same (see CloudSave).
const CLOUD_FILE := "user://gold_coast_cloud.json"
## When the cloud can't be reached, how long until it tries again, in seconds.
const CLOUD_RETRY_SECONDS := 30.0
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
## The logged-in player's account id (the server's), username (her name in
## town), name, and email, or "".
var user_id := ""
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
## How her cloud save stands (CloudSave.State): no cloud (offline), up to date,
## waiting to go up, or a different game in the cloud.
var cloud := CloudSave.State.OFF
## Where this computer's notes on cloud saves are kept (tests use their own file).
var cloud_file := CLOUD_FILE
## The two saves she's asked to choose between, when check_cloud() says "ask":
## {"here": this computer's, "cloud": the cloud's (both saved games, as
## Dictionaries), "version": the cloud copy's version}.
var cloud_question := {}

var _token := ""
var _refresh_token := ""
var _joining := false
# The town's time of day when it last told it, and when that was (in msec).
var _world_minutes := 0.0
var _world_told_at := 0
# Whether a cloud save is being checked or sent now (one at a time), and
# whether another save came in meanwhile, so it goes again.
var _syncing := false
var _sync_again := false
# Tries the cloud again after it couldn't be reached.
var _retry: Timer


func _ready() -> void:
	var page_host := ""
	var page_query := ""
	if OS.has_feature("web"):
		page_host = String(JavaScriptBridge.eval("location.hostname"))
		page_query = String(JavaScriptBridge.eval("location.search"))
	use_server_for(page_host, wants_live_server(page_query, OS.get_cmdline_user_args()))
	if backend == null:
		backend = NakamaBackend.new(host, port, scheme, server_key)
	# Without an online server, the game on itch.io can't reach the one on the
	# computer that made it, so there it plays offline.
	if OS.has_feature("web") and not can_reach(host, page_host):
		offline = true
	GameState.game_saved.connect(_on_game_saved)
	_retry = Timer.new()
	_retry.one_shot = true
	_retry.wait_time = CLOUD_RETRY_SECONDS
	_retry.process_mode = Node.PROCESS_MODE_ALWAYS # menus pause the game, not the cloud
	_retry.timeout.connect(retry_cloud)
	add_child(_retry)


## Whether this copy was asked to use the online server even on this computer,
## to try it out before the game on itch.io does: "?server=live" at the end of
## the web page's address, or "--server=live" after Godot's own arguments
## (godot --path . -- --server=live).
static func wants_live_server(page_query: String, args: PackedStringArray) -> bool:
	return "server=live" in page_query or "--server=live" in args


## Points the game at the online server (LiveServer.HOST), if there is one,
## when it's a web page on the internet (like itch.io's) or `live` asks for it.
## Otherwise (the editor, the tests, a web page served on this computer) it
## keeps this computer's server.
func use_server_for(page_host: String, live := false, live_host: String = LiveServer.HOST,
		live_key: String = LiveServer.SERVER_KEY) -> void:
	if live_host == "":
		if live:
			push_warning("There's no online server in scripts/live_server.gd yet, so it's this computer's.")
		return
	if not live and page_host in ["127.0.0.1", "localhost", ""]:
		return
	host = live_host
	port = 443
	scheme = "https"
	server_key = live_key
	account_file = LIVE_ACCOUNT_FILE


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


## Logs out, and forgets the login in this browser. (Her saved game stays on
## this computer, and in the cloud.)
func log_out() -> void:
	leave_town()
	if is_logged_in():
		backend.log_out(_token, _refresh_token) # not waited for: the game carries on
	_token = ""
	_refresh_token = ""
	user_id = ""
	username = ""
	display_name = ""
	email = ""
	offline = false
	cloud_question = {}
	_set_cloud(CloudSave.State.OFF)
	DirAccess.remove_absolute(account_file)
	account_changed.emit()


## Plays without an account this time: single player, saved in the browser.
func play_offline() -> void:
	offline = true
	account_changed.emit()


## Brings her save on this computer and the one in the cloud into step, as the
## game starts (the title screen calls it once she's logged in): whichever has
## changed since they were last the same is kept, coming down from the cloud
## or going up to it (see CloudSave). Returns "ask" if both have changed, so she
## must choose which to keep (see cloud_question and keep_save()). Otherwise it
## returns "" when it's done, or when the cloud can't be reached: then her save
## waits here, and goes up later.
func check_cloud() -> String:
	cloud_question = {}
	if not is_logged_in():
		_set_cloud(CloudSave.State.OFF)
		return ""
	return await _sync_now(true)


## Keeps one of two different saves, after check_cloud() asked: "here" (this
## computer's, which goes up to the cloud) or "cloud" (the cloud's, which
## comes down to this computer). The other one is replaced.
func keep_save(which: String) -> void:
	var question := cloud_question
	cloud_question = {}
	if question.is_empty() or not is_logged_in():
		return
	if which == "cloud":
		if GameState.replace_save(question.cloud):
			_note_in_step(GameState.save_text(), question.version)
			_set_cloud(CloudSave.State.UP_TO_DATE)
		return
	# This computer's: the notes count the cloud's copy she's seen as dealt
	# with, so this one goes up over it (now, or when the cloud can be reached).
	var notes := _read_notes()
	notes.accounts[user_id] = {"save": "", "cloud": question.version}
	notes.last = user_id
	_write_notes(notes)
	await _sync_now(false)


## Tries again to put her save in the cloud, after the server couldn't be
## reached (a timer does this CLOUD_RETRY_SECONDS later, again and again).
func retry_cloud() -> void:
	if is_logged_in() and cloud == CloudSave.State.WAITING:
		_sync_in_background()


## Whether her save is being checked against the cloud, or sent there, now.
func is_syncing() -> bool:
	return _syncing


## Whether it's going to try the cloud again soon (the server couldn't be reached).
func will_retry() -> bool:
	return _retry != null and not _retry.is_stopped()


## Waits until her save has finished going to the cloud, for up to `seconds`
## (logging out waits, so the save she just made goes up first).
func wait_for_cloud(seconds := 8.0) -> void:
	var give_up_at := Time.get_ticks_msec() + int(seconds * 1000.0)
	while _syncing and Time.get_ticks_msec() < give_up_at:
		await get_tree().process_frame


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
	user_id = String(result.get("user_id", ""))
	username = result.username
	display_name = result.display_name
	email = result.email
	offline = false
	_remember_login()
	account_changed.emit()
	return ""


# Keeps the login in this browser, for next time.
func _remember_login() -> void:
	var file := FileAccess.open(account_file, FileAccess.WRITE)
	file.store_string(JSON.stringify({"token": _token, "refresh_token": _refresh_token}))
	file.close()


# The client renews a login that's about to run out on its way to the server;
# if it did, the new one is kept.
func _keep_tokens(result: Dictionary) -> void:
	var token := String(result.get("token", ""))
	if token == "" or token == _token:
		return
	_token = token
	_refresh_token = String(result.get("refresh_token", _refresh_token))
	_remember_login()


# Every save she makes while logged in goes up to the cloud, in the background.
func _on_game_saved() -> void:
	if not is_logged_in():
		return
	var notes := _read_notes()
	notes.last = user_id # she's played on here, as herself
	_write_notes(notes)
	_sync_in_background()


# Checks her save against the cloud now, after any check already going (one
# at a time), and returns what _sync() says.
func _sync_now(at_start: bool) -> String:
	while _syncing:
		await get_tree().process_frame
	_syncing = true
	var answer := await _sync(at_start)
	_syncing = false
	if _sync_again:
		_sync_in_background() # a save came in meanwhile
	return answer


# In the background: checks her save against the cloud, and sends it if it
# can. A save that comes in while it's going makes it go again afterwards.
func _sync_in_background() -> void:
	_sync_again = true
	if _syncing:
		return
	_syncing = true
	while _sync_again and is_logged_in():
		_sync_again = false
		await _sync(false)
	_syncing = false


# Brings her save on this computer and the cloud's into step, if it can (see
# CloudSave.next_step()). At the start (`at_start`: on the title screen, before
# she plays), the cloud's save can come down, and if both changed it returns
# "ask". In the game she's playing on from this computer's save, so only this
# one can go up; if the cloud's has changed, it waits for her next start
# (DIFFERS), and nothing is written over.
func _sync(at_start: bool, again := false) -> String:
	var me := user_id
	var read: Dictionary = await backend.read_save(_token, _refresh_token)
	if me != user_id:
		return "" # she logged out (or someone else logged in) on the way
	_keep_tokens(read)
	if not read.get("ok", false):
		_wait_for_server(read)
		return ""
	var version := String(read.get("version", ""))
	if version != "" and not GameState.is_save(read.get("save")):
		# A cloud save this version can't read (damaged, or from a newer
		# version of the game): it's left alone, and so is this computer's.
		_set_cloud(CloudSave.State.DIFFERS)
		return ""
	var text := GameState.save_text()
	var step := CloudSave.next_step(text, version, _read_notes(), me)
	if step != CloudSave.Step.SAME and version != "" and GameState.peek_save() == read.save:
		# The very same game in both: its last trip up got there, but this
		# computer never heard back (the page was closed first, say).
		step = CloudSave.Step.SAME
	match step:
		CloudSave.Step.SAME:
			_note_in_step(text, version)
			_set_cloud(CloudSave.State.UP_TO_DATE)
		CloudSave.Step.UPLOAD:
			var beaten := await _upload(text, version)
			if beaten and at_start and not again:
				return await _sync(true, true) # another computer's save got there first: look again
		CloudSave.Step.DOWNLOAD:
			if at_start and GameState.replace_save(read.save):
				_note_in_step(GameState.save_text(), version)
				_set_cloud(CloudSave.State.UP_TO_DATE)
			else:
				_set_cloud(CloudSave.State.DIFFERS)
		CloudSave.Step.CLEAR:
			# Another account's game (safe in their cloud), and she has none in
			# hers: at the start it's cleared from this computer, so she starts
			# afresh; in the game, her next save makes it hers, and it goes up.
			if at_start:
				GameState.delete_save()
				var notes := _read_notes()
				notes.last = me
				_write_notes(notes)
				_set_cloud(CloudSave.State.UP_TO_DATE)
			else:
				_set_cloud(CloudSave.State.WAITING)
		CloudSave.Step.ASK:
			_set_cloud(CloudSave.State.DIFFERS)
			if at_start:
				cloud_question = {"here": GameState.peek_save(), "cloud": read.save, "version": version}
				return "ask"
	return ""


# Puts `text` (her saved game's file) in the cloud, over the copy there, if
# it's still `version` ("": there wasn't one). Returns true if another
# computer's save got there first (then nothing is written over).
func _upload(text: String, version: String) -> bool:
	var me := user_id
	var wrote: Dictionary = await backend.write_save(_token, _refresh_token, text, version if version != "" else "*")
	if wrote.get("ok", false):
		_note_in_step(text, String(wrote.get("version", "")), me) # even if she's logged out since: it's in her cloud
	if me != user_id:
		return false
	_keep_tokens(wrote)
	if wrote.get("ok", false):
		_set_cloud(CloudSave.State.UP_TO_DATE)
		return false
	if wrote.get("conflict", false):
		_set_cloud(CloudSave.State.DIFFERS)
		return true
	_wait_for_server(wrote)
	return false


# The cloud couldn't be checked or written: her save waits on this computer.
# If the server couldn't be reached at all, it tries again in a while.
func _wait_for_server(failed: Dictionary) -> void:
	_set_cloud(CloudSave.State.WAITING)
	if failed.get("unreachable", false):
		_retry.start(CLOUD_RETRY_SECONDS)


func _set_cloud(state: CloudSave.State) -> void:
	if state != CloudSave.State.WAITING and _retry != null:
		_retry.stop()
	if state != cloud:
		cloud = state
		cloud_changed.emit()


# Notes that the save here (`text`) and `account`'s copy in the cloud
# (`version`) are the same now, and (if that's who's logged in) that it's the
# last account to play here.
func _note_in_step(text: String, version: String, account := user_id) -> void:
	var notes := _read_notes()
	notes.accounts[account] = {"save": CloudSave.fingerprint(text), "cloud": version}
	if account == user_id:
		notes.last = account
	_write_notes(notes)


# This computer's notes on cloud saves (see CloudSave.empty_notes()), skipping
# anything in the file that isn't what it should be.
func _read_notes() -> Dictionary:
	var notes := CloudSave.empty_notes()
	if not FileAccess.file_exists(cloud_file):
		return notes
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(cloud_file)) != OK or not json.data is Dictionary:
		return notes
	var kept: Dictionary = json.data
	var accounts: Variant = kept.get("accounts")
	if accounts is Dictionary:
		for account: Variant in accounts:
			var note: Variant = accounts[account]
			if account is String and note is Dictionary and note.get("save") is String and note.get("cloud") is String:
				notes.accounts[account] = {"save": note.save, "cloud": note.cloud}
	if kept.get("last") is String:
		notes.last = kept.last
	return notes


func _write_notes(notes: Dictionary) -> void:
	var file := FileAccess.open(cloud_file, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(notes, "\t"))
	file.close()
