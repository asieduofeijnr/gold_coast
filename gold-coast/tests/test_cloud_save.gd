extends TestCase
## Checks cloud saves (Online, with CloudSave's rules), against a pretend
## server (FakeBackend), with no internet:
## - the rules: which save to keep, from what's changed since they were last
##   the same, and whose they are
## - saving while she's logged in puts a copy in her account, that only she
##   can read or change, and the little cloud on her phone is full
## - logging in on another computer brings her save
## - with no internet (or playing offline), her save waits on this computer,
##   and goes up when it can; a newer one in the cloud never replaces hers while
##   she plays
## - two different saves: her phone asks which to keep, and keeps it (but the
##   same game in both is never asked about)
## - playing on two computers at once never writes over the other's save, even
##   when the other's gets there between looking and writing
## - another account's game on this computer is never put in hers, nor hers in his
## - LOG OUT waits until her save is in the cloud
## - a cloud save this version can't read is left alone

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const AMA := {"email": "ama@example.com", "password": "kenkey-and-fish", "username": "ama_osu"}
const KOFI := {"email": "kofi@example.com", "password": "waakye-for-two", "username": "kofi_ab"}

var _fake: FakeBackend
var _main: Node
var _title: TitleScreen
var _phone: Phone


func run_tests() -> void:
	_check_rules()
	_fake = FakeBackend.new()
	for who: Dictionary in [AMA, KOFI]:
		_fake.accounts[who.email] = {"password": who.password, "username": who.username, "display_name": who.username}
	Online.backend = _fake
	Online.log_out()
	_new_computer()
	GameState.reset()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await wait_physics_frames(5)
	_title = _main.get_node("HUD/TitleScreen")
	_phone = _main.get_node("HUD/Phone")
	await _check_saving_goes_up()
	await _check_another_computer()
	await _check_no_internet()
	await _check_choosing()
	await _check_two_computers_at_once()
	await _check_racing()
	await _check_internet_back_while_playing()
	await _check_other_accounts()
	await _check_trip_unheard()
	await _check_log_out_waits()
	await _check_unreadable_cloud_save()
	_main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	# Back to how the test runner set things up.
	Online.backend = FakeBackend.new()
	Online.log_out()
	Online.play_offline()
	_new_computer()
	GameState.reset()


func _check_rules() -> void:
	var me := "id-ama"
	var text := "{\"day\": 5}"
	var later := "{\"day\": 6}"
	var nothing := CloudSave.empty_notes()
	var in_step := {"accounts": {me: {"save": CloudSave.fingerprint(text), "cloud": "v1"}}, "last": me}
	check(CloudSave.next_step("", "", nothing, me) == CloudSave.Step.SAME
			and CloudSave.next_step("", "v1", nothing, me) == CloudSave.Step.DOWNLOAD,
			"the rules: with nothing saved here, there's nothing to do, or the cloud's save comes down")
	check(CloudSave.next_step(text, "", nothing, me) == CloudSave.Step.UPLOAD,
			"  ...a save from before cloud saves (or from playing offline), with nothing in her cloud, goes up")
	check(CloudSave.next_step(text, "v1", in_step, me) == CloudSave.Step.SAME,
			"  ...both just as they were when they were last the same: nothing to do")
	check(CloudSave.next_step(later, "v1", in_step, me) == CloudSave.Step.UPLOAD,
			"  ...only this computer's has changed: it goes up")
	check(CloudSave.next_step(text, "v2", in_step, me) == CloudSave.Step.DOWNLOAD,
			"  ...only the cloud's has changed (she played on another computer): it comes down")
	check(CloudSave.next_step(later, "v2", in_step, me) == CloudSave.Step.ASK,
			"  ...both have changed: she chooses which to keep")
	var kofi_last := in_step.duplicate(true)
	kofi_last.last = "id-kofi"
	check(CloudSave.next_step(later, "v1", kofi_last, me) == CloudSave.Step.ASK,
			"  ...this computer's has changed, but someone else played here last: she chooses")
	check(CloudSave.next_step(text, "v1", nothing, me) == CloudSave.Step.ASK,
			"  ...a save here that's never been the same as her cloud's, and one in her cloud: she chooses")
	var kofis := {"accounts": {"id-kofi": {"save": CloudSave.fingerprint(text), "cloud": "k1"}}, "last": "id-kofi"}
	check(CloudSave.next_step(text, "v1", kofis, me) == CloudSave.Step.DOWNLOAD
			and CloudSave.next_step(text, "", kofis, me) == CloudSave.Step.CLEAR,
			"  ...another account's game here (safe in his cloud) makes way: hers comes down, or it's cleared")
	check(CloudSave.fingerprint(text) != CloudSave.fingerprint(later) and CloudSave.fingerprint(text).length() == 64
			and CloudSave.fingerprint("") == "",
			"a save's fingerprint changes whenever the save does")
	var up := NakamaBackend.save_object(text, "*")
	check(up.collection == "saves" and up.key == "game" and up.permission_read == NakamaBackend.OWNER_ONLY
			and up.permission_write == NakamaBackend.OWNER_ONLY and NakamaBackend.OWNER_ONLY == 1,
			"her save goes up where only she can read or change it (Nakama's owner-only permission, 1)")
	check(Format.date_time(1763072400, -360) == "13 Nov, 16:20" and Format.date_time(1767225599, 60) == "1 Jan, 00:59",
			"when a save was made is shown in this computer's time: %s" % Format.date_time(1763072400, -360))


func _check_saving_goes_up() -> void:
	await _start_as(AMA)
	check(_title.items()[0] == "NEW GAME" and Online.cloud == CloudSave.State.UP_TO_DATE and _phone.cloud == Phone.Cloud.FULL,
			"logged in, with no save here or in her cloud, she starts a new game, and the cloud on her phone is full")
	await _play(false)
	GameState.money = 23456
	GameState.set_time(5, 14 * 60.0 + 20.0)
	GameState.save_game()
	await wait_physics_frames(1)
	var up := _cloud_save(AMA)
	check(int(up.get("money", 0)) == 23456 and int(up.get("day", 0)) == 5 and up.get("saved_at") is float,
			"saving while she's logged in puts a copy of her save in her account, in the cloud")
	check(Online.cloud == CloudSave.State.UP_TO_DATE and _phone.cloud == Phone.Cloud.FULL,
			"  ...and the little cloud on her phone is full: her save is up to date")


func _check_another_computer() -> void:
	Online.log_out()
	_new_computer() # another browser: no save, no notes, and nobody logged in
	GameState.reset()
	_title.open()
	await wait_physics_frames(2)
	var card := _title.get_account_screen()
	card.show_tab(1)
	card.fill({"login_email": AMA.email, "login_password": AMA.password})
	await card.submit()
	await wait_physics_frames(2)
	check(Online.is_logged_in() and _title.items()[0] == "CONTINUE" and "day 5, 14:20" in _title.saved_game_line()
			and "GH₵234.56" in _title.saved_game_line() and "saved " in _title.saved_game_line(),
			"logging in on another computer brings her save: \"%s\"" % _title.saved_game_line())
	await _play(true)
	check(GameState.money == 23456 and GameState.day == 5, "  ...and CONTINUE carries on from it")


func _check_no_internet() -> void:
	_fake.reachable = false
	GameState.money = 30000
	GameState.save_game()
	await wait_physics_frames(1)
	check(int(GameState.peek_save().money) == 30000 and int(_cloud_save(AMA).money) == 23456
			and Online.cloud == CloudSave.State.WAITING and _phone.cloud == Phone.Cloud.EMPTY and Online.will_retry(),
			"with no internet, her save stays on this computer, the cloud on her phone is empty, and it'll try again")
	_fake.reachable = true
	Online.retry_cloud() # what the timer does, CLOUD_RETRY_SECONDS later
	await wait_physics_frames(1)
	check(int(_cloud_save(AMA).money) == 30000 and Online.cloud == CloudSave.State.UP_TO_DATE
			and _phone.cloud == Phone.Cloud.FULL and not Online.will_retry(),
			"  ...once the server can be reached, it goes up, and the cloud is full again")
	Online.log_out()
	Online.play_offline()
	GameState.money = 31000
	GameState.save_game()
	await wait_physics_frames(1)
	check(int(_cloud_save(AMA).money) == 30000 and _phone.cloud == Phone.Cloud.NONE,
			"playing offline, her saves stay on this computer (and the phone has no cloud)")
	await _start_as(AMA)
	check(int(_cloud_save(AMA).money) == 31000 and _title.items()[0] == "CONTINUE" and Online.cloud == CloudSave.State.UP_TO_DATE,
			"  ...they go up to her cloud the next time she logs in")


func _check_choosing() -> void:
	# This computer's save changes (offline), and so does the cloud's (another computer's).
	Online.log_out()
	Online.play_offline()
	GameState.reset()
	GameState.money = 40000
	GameState.save_game()
	var elsewhere := _cloud_save(AMA)
	elsewhere.day = 9
	elsewhere.money = 41000
	_fake.put_save(AMA.username, elsewhere)
	await _start_as(AMA)
	var lines := _title.which_lines()
	check(_title.is_asking_which() and _phone.menu_title == "KEEP WHICH?"
			and _phone.menu_items == PackedStringArray(["THIS COMPUTER", "THE CLOUD"]) and lines.size() == 2
			and "GH₵400.00" in lines[0] and "day 9" in lines[1] and "GH₵410.00" in lines[1],
			"when both saves have changed, her phone asks which to keep, with both described: \"%s\" / \"%s\""
			% [lines[0] if lines.size() > 0 else "", lines[1] if lines.size() > 1 else ""])
	_phone.press("back")
	await wait_physics_frames(1)
	check(_title.is_asking_which(), "  ...she must choose (C doesn't skip it)")
	_phone.press("down")
	_phone.press("select") # THE CLOUD
	await wait_physics_frames(2)
	check(not _title.is_asking_which() and int(GameState.peek_save().money) == 41000 and _title.items()[0] == "CONTINUE"
			and Online.cloud == CloudSave.State.UP_TO_DATE,
			"  ...THE CLOUD brings the cloud's save to this computer (GH₵410.00, day 9)")
	Online.log_out()
	Online.play_offline()
	GameState.reset()
	GameState.money = 50000
	GameState.save_game()
	elsewhere = _cloud_save(AMA)
	elsewhere.money = 51000
	_fake.put_save(AMA.username, elsewhere)
	await _start_as(AMA)
	var asked := _title.is_asking_which()
	_phone.press("select") # THIS COMPUTER
	await wait_physics_frames(2)
	check(asked and int(_cloud_save(AMA).money) == 50000 and int(GameState.peek_save().money) == 50000
			and Online.cloud == CloudSave.State.UP_TO_DATE,
			"  ...and THIS COMPUTER puts this computer's save in the cloud instead")


func _check_two_computers_at_once() -> void:
	await _play(true)
	var elsewhere := _cloud_save(AMA)
	elsewhere.money = 70000
	_fake.put_save(AMA.username, elsewhere) # the other computer saves first
	_fake.delay = 0.1 # the server answers a moment later, as a real one does (after the phone's GAME SAVED text)
	GameState.money = 65000
	GameState.save_game()
	await wait_until(func() -> bool: return not Online.is_syncing(), 3.0)
	_fake.delay = 0.0
	check(int(_cloud_save(AMA).money) == 70000 and int(GameState.peek_save().money) == 65000
			and Online.cloud == CloudSave.State.DIFFERS and _phone.cloud == Phone.Cloud.EMPTY
			and "CLOUD SAVE" in _phone.shown_sms(),
			"playing on two computers at once, a save never writes over the other's in the cloud, and her phone says so")
	await _start_as(AMA)
	check(_title.is_asking_which(), "  ...the next time she starts, she chooses which to keep")
	_phone.press("select") # THIS COMPUTER
	await wait_physics_frames(2)


# Another computer's save gets to the cloud just after hers looked, and just
# before hers arrives: the cloud only takes a save over the copy it looked at.
func _check_racing() -> void:
	await _play(true)
	var elsewhere := _cloud_save(AMA)
	elsewhere.money = 80000
	_fake.before_next_write = func() -> void: _fake.put_save(AMA.username, elsewhere)
	GameState.money = 75000
	GameState.save_game()
	await wait_physics_frames(1)
	check(int(_cloud_save(AMA).money) == 80000 and Online.cloud == CloudSave.State.DIFFERS,
			"a save that gets to the cloud between hers looking and arriving is never written over")
	elsewhere.money = 85000
	_fake.before_next_write = func() -> void: _fake.put_save(AMA.username, elsewhere)
	Online.log_out()
	Online.play_offline()
	GameState.money = 76000
	GameState.save_game()
	await Online.log_in(AMA.email, AMA.password)
	var notes := _notes()
	notes.accounts[Online.user_id].cloud = _fake.saves[AMA.username].version # as if this computer last saw it
	_keep_notes(notes)
	_title.open()
	await wait_physics_frames(2)
	check(_title.is_asking_which() and int(_cloud_save(AMA).money) == 85000 and "GH₵850.00" in _title.which_lines()[1],
			"  ...and at the start, it looks again and asks her which to keep")
	_phone.press("select") # THIS COMPUTER
	await wait_physics_frames(2)
	check(int(_cloud_save(AMA).money) == 76000 and Online.cloud == CloudSave.State.UP_TO_DATE,
			"  ...then keeps the one she chooses")


# The cloud can't be reached as the game starts, so she plays on from this
# computer's save; when it's back, the cloud has a newer one (another
# computer's). Hers isn't replaced under her feet: she chooses next time.
func _check_internet_back_while_playing() -> void:
	Online.log_out()
	await Online.log_in(AMA.email, AMA.password)
	_fake.reachable = false
	_title.open()
	await wait_physics_frames(2)
	var waiting := Online.cloud == CloudSave.State.WAITING and _title.items()[0] == "CONTINUE"
	await _play(true)
	var here := GameState.save_text()
	var elsewhere := _cloud_save(AMA)
	elsewhere.money = 90000
	_fake.put_save(AMA.username, elsewhere)
	_fake.reachable = true
	Online.retry_cloud()
	await wait_physics_frames(1)
	check(waiting and GameState.save_text() == here and Online.cloud == CloudSave.State.DIFFERS
			and int(_cloud_save(AMA).money) == 90000,
			"if the cloud can't be reached as she starts, she plays on from this computer's save, and a newer one in the cloud never replaces it while she plays")


func _check_other_accounts() -> void:
	var hers := int(_cloud_save(AMA).money)
	await _start_as(KOFI)
	check(_title.items()[0] == "NEW GAME" and _title.saved_game_line() == "" and not GameState.has_save(),
			"someone else (@kofi_ab) logging in on her computer doesn't get her game (it's safe in her cloud): he starts afresh")
	await _play(false)
	GameState.reset()
	GameState.money = 777
	GameState.save_game()
	await wait_physics_frames(1)
	check(int(_cloud_save(KOFI).money) == 777 and int(_cloud_save(AMA).money) == hers,
			"  ...his saves go to his cloud, never hers")
	await _start_as(AMA)
	check(_title.items()[0] == "CONTINUE" and int(GameState.peek_save().money) == hers and int(_cloud_save(KOFI).money) == 777,
			"  ...and when she logs in again, her own game comes back down (and his stays his)")


# Her last save went up, but the page was closed before this computer heard
# back, so its notes are behind on both sides: the very same game in both
# isn't asked about.
func _check_trip_unheard() -> void:
	var notes := _notes()
	notes.accounts[Online.user_id] = {"save": CloudSave.fingerprint("{}"), "cloud": "an-older-version"}
	_keep_notes(notes)
	await _start_as(AMA)
	check(not _title.is_asking_which() and Online.cloud == CloudSave.State.UP_TO_DATE and _title.items()[0] == "CONTINUE"
			and _notes().accounts[Online.user_id].cloud == _fake.saves[AMA.username].version,
			"the same game here and in the cloud is never asked about, even when this computer's notes are behind")


func _check_log_out_waits() -> void:
	await _play(true)
	GameState.money = 60000
	_fake.delay = 0.4 # a slow internet: each trip to the cloud takes a while
	await press_action("phone_menu")
	await wait_physics_frames(2)
	for i in PauseMenu.ITEMS.size():
		if _phone.picked_item() == "LOG OUT":
			break
		await press_action("ui_down")
	await press_action("ui_accept")
	await press_action("ui_accept") # YES
	var waited := _phone.screen == Phone.Screen.PAGE and _phone.page_lines[0] == "SAVING TO" and Online.is_logged_in()
	await wait_until(func() -> bool: return not Online.is_logged_in(), 4.0)
	_fake.delay = 0.0
	check(waited and int(_cloud_save(AMA).money) == 60000 and not Online.is_logged_in(),
			"LOG OUT waits while her save goes up to the cloud, then logs out: the save she just made is there")


func _check_unreadable_cloud_save() -> void:
	var newer := _cloud_save(AMA)
	newer.version = GameState.SAVE_VERSION + 1 # from a newer version of the game
	_fake.put_save(AMA.username, newer)
	var here := GameState.save_text()
	await _start_as(AMA)
	check(GameState.save_text() == here and Online.cloud == CloudSave.State.DIFFERS and not _title.is_asking_which(),
			"a cloud save this version of the game can't read never replaces the one on this computer")
	GameState.money = 100
	GameState.save_game()
	await wait_physics_frames(1)
	check(int(_cloud_save(AMA).version) == GameState.SAVE_VERSION + 1, "  ...and is never written over")


# As the game starts, logged in as `who`: the title screen checks her cloud save.
func _start_as(who: Dictionary) -> void:
	Online.log_out()
	await Online.log_in(who.email, who.password)
	_title.open()
	await wait_physics_frames(2)


# From the title screen's start menu into the game: CONTINUE, or NEW GAME.
func _play(continuing: bool) -> void:
	if not _title.is_open():
		_title.open()
		await wait_physics_frames(2)
	var item := "CONTINUE" if continuing else "NEW GAME"
	for i in _title.items().size():
		if _phone.picked_item() == item:
			break
		_phone.press("down")
	_phone.press("select")
	await wait_physics_frames(2)


# What's in `who`'s cloud save, as a saved game ({} if nothing).
func _cloud_save(who: Dictionary) -> Dictionary:
	if not _fake.saves.has(who.username):
		return {}
	var json := JSON.new()
	return json.data if json.parse(_fake.saves[who.username].text) == OK else {}


# This computer's notes on cloud saves, and writing them back (as if from before).
func _notes() -> Dictionary:
	var json := JSON.new()
	json.parse(FileAccess.get_file_as_string(Online.cloud_file))
	return json.data if json.data is Dictionary else CloudSave.empty_notes()


func _keep_notes(notes: Dictionary) -> void:
	var file := FileAccess.open(Online.cloud_file, FileAccess.WRITE)
	file.store_string(JSON.stringify(notes))
	file.close()


# A fresh browser: no saved game, and no notes on cloud saves.
func _new_computer() -> void:
	GameState.delete_save()
	DirAccess.remove_absolute(Online.cloud_file)
