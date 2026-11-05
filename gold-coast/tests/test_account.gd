extends TestCase
## Checks the account card and logging in, against a pretend server
## (FakeBackend), with no internet:
## - the sign-up form's rules: a name, a username like ama_osu, a password of 8
##   or more that isn't too easy, an email, a date of birth (18 or older), and
##   the box ticked
## - signing up sends the name, date of birth, and terms to the server, logs
##   her in, and goes on to the phone's start menu
## - mistakes under the fields, a taken username, a wrong password, and no
##   server, all in plain words
## - logging in, playing offline, and staying logged in for next time
## - the password's eye, and the five pages the box agrees to
## - logging out from the phone's ACCOUNT page
## - the server's client keeps working while the title screen pauses the game

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const AMA := {"name": "Ama Mensah", "username": "ama_osu", "password": "kenkey-and-fish", "email": "ama@example.com",
		"birthdate": "1998-03-06", "agreed": true}

var _fake: FakeBackend
var _main: Node
var _title: TitleScreen
var _card: AccountScreen
var _phone: Phone


func run_tests() -> void:
	_check_form_rules()
	_fake = FakeBackend.new()
	Online.backend = _fake
	Online.log_out() # logged out, and not offline: the title screen asks
	GameState.reset()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await wait_physics_frames(5)
	_title = _main.get_node("HUD/TitleScreen")
	_card = _title.get_account_screen()
	_phone = _main.get_node("HUD/Phone")
	await _check_sign_up()
	await _check_mistakes()
	await _check_log_in_and_offline()
	await _check_staying_logged_in()
	_check_reading()
	await _check_log_out()
	check(Nakama.process_mode == Node.PROCESS_MODE_ALWAYS,
			"the server's client keeps working while the title screen pauses the game (it would hang otherwise)")
	_main.queue_free()
	await get_tree().process_frame
	get_tree().paused = false
	# Back to how the test runner set things up.
	Online.backend = FakeBackend.new()
	Online.log_out()
	Online.play_offline()
	GameState.reset()


func _check_form_rules() -> void:
	check(Online.check_sign_up(AMA).is_empty(), "a filled-in sign-up form passes its checks")
	var problems := Online.check_sign_up({"name": " ", "username": "Ama Osu!", "password": "1234567",
			"email": "ama.example.com", "birthdate": "", "agreed": false})
	check(problems.size() == 6, "an empty or wrong form has a message for each field: %s" % " / ".join(problems.values()))
	var young := AMA.duplicate()
	young.birthdate = "%d-01-01" % (int(Time.get_date_dict_from_system().year) - 17)
	check(Online.check_sign_up(young).get("birthdate", "") == "Gold Coast is for players 18 and older.",
			"  ...someone under 18 can't make an account")
	var easy := AMA.duplicate()
	easy.password = "password1"
	check("easy" in String(Online.check_sign_up(easy).get("password", "")),
			"  ...nor can anyone use a password that's too easy to guess")
	check(Online.age_on_today("2001-02-30") == -1 and Online.days_in_month(2, 2024) == 29,
			"  ...and a date that doesn't exist (30 February) isn't a date of birth")
	check(Online.can_reach("127.0.0.1", "127.0.0.1") and not Online.can_reach("127.0.0.1", "html-classic.itch.zone")
			and Online.can_reach("play.goldcoast.example", "html-classic.itch.zone"),
			"while the server is only on this computer, the game on itch.io plays offline (a page from here can reach it)")


func _check_sign_up() -> void:
	_title.open()
	await wait_physics_frames(2)
	check(_title.is_asking_for_account() and _card.tab() == 0 and not _phone.visible,
			"with nobody logged in, the title screen shows the account card, on Create account")
	var username := _card.input("username")
	username.text = "Ama Osu"
	username.text_changed.emit(username.text) # as typing does
	check(username.text == "ama_osu", "  ...a username is small letters as it's typed (\"Ama Osu\" becomes %s)" % username.text)
	_card.fill(AMA)
	await _card.submit()
	await wait_physics_frames(2)
	check(_fake.accounts.has(AMA.email) and _fake.last_vars.get("name") == AMA.name
			and _fake.last_vars.get("birthdate") == AMA.birthdate and _fake.last_vars.get("terms") == Online.TERMS_VERSION,
			"Sign up sends her name, date of birth, and the terms she agreed to, with her email, password, and username")
	check(Online.is_logged_in() and Online.username == "ama_osu" and not _title.is_asking_for_account()
			and _phone.visible and _phone.screen == Phone.Screen.MENU and _phone.menu_title == "GOLD COAST",
			"  ...she's logged in as @ama_osu, and the phone's start menu comes up")


func _check_mistakes() -> void:
	Online.log_out()
	_title.open()
	await wait_physics_frames(2)
	_card.fill({"name": "", "username": "", "password": "", "email": "", "birthdate": "", "agreed": false})
	var asked := _fake.calls.size()
	await _card.submit()
	var all_marked := ["name", "username", "password", "email", "birthdate", "agreed"].all(
			func(key: String) -> bool: return _card.error_for(key) != "")
	check(all_marked and _fake.calls.size() == asked and _card.message() != "",
			"an empty form shows what's missing under each field, in red, and asks the server nothing")
	_card.fill(AMA)
	_card.fill({"email": "ama.two@example.com"}) # a new email, but Ama's username
	await _card.submit()
	check(_card.error_for("username") == "That username is taken. Try another one." and not Online.is_logged_in(),
			"a username that's taken says so, under the username")
	_card.fill({"username": "kofi_ab", "email": AMA.email}) # Ama's email, another password
	_card.fill({"password": "another-password"})
	await _card.submit()
	check(_card.message() == "There's already an account with that email. Log in instead." and not Online.is_logged_in(),
			"an email that already has an account says to log in instead")
	_fake.reachable = false
	_card.fill({"email": "kofi@example.com"})
	await _card.submit()
	check("play offline" in _card.message() and not Online.is_logged_in(),
			"with no server, it says so, and offers playing offline: \"%s\"" % _card.message())
	_fake.reachable = true


func _check_log_in_and_offline() -> void:
	_card.show_tab(1)
	_card.fill({"login_email": AMA.email, "login_password": "wrong-password"})
	await _card.submit()
	check(_card.message() == "That email and password don't match." and not Online.is_logged_in(),
			"Log in with the wrong password says so")
	_card.fill({"login_email": "nobody@example.com"})
	await _card.submit()
	check(_card.message().begins_with("There's no account with that email"), "  ...and with an email nobody has, says that")
	_card.fill({"login_email": AMA.email, "login_password": AMA.password})
	await _card.submit()
	check(Online.is_logged_in() and Online.username == "ama_osu" and not _title.is_asking_for_account(),
			"  ...with the right ones, she's logged in")
	Online.log_out()
	_title.open()
	await wait_physics_frames(2)
	_card.play_offline()
	await wait_physics_frames(2)
	check(Online.offline and not Online.is_logged_in() and not _title.is_asking_for_account()
			and _phone.menu_title == "GOLD COAST",
			"Play offline goes straight to the start menu, with no account")


func _check_staying_logged_in() -> void:
	Online.log_out()
	await Online.log_in(AMA.email, AMA.password)
	# As if the game started again: nobody's logged in yet, but the login is kept.
	Online.username = ""
	_fake.calls.clear()
	_title.open()
	await wait_until(func() -> bool: return Online.is_logged_in(), 3.0)
	await wait_physics_frames(2)
	check(Online.has_saved_login() and Online.is_logged_in() and _fake.calls.has("restore")
			and not _title.is_asking_for_account(),
			"next time, she's logged in again by herself (the login is kept in the browser)")
	Online.username = ""
	var kept: Dictionary = _fake.accounts
	_fake.accounts = {} # the server no longer knows that login
	_title.open()
	await wait_physics_frames(4)
	check(_title.is_asking_for_account() and _card.tab() == 1 and _card.message() == "Please log in again."
			and not Online.has_saved_login(),
			"  ...if that login no longer works, the card asks her to log in again (and forgets it)")
	_fake.accounts = kept
	await Online.log_in(AMA.email, AMA.password)
	Online.username = ""
	_fake.reachable = false # the server isn't running
	_title.open()
	await wait_physics_frames(4)
	check(_title.is_asking_for_account() and _card.message().begins_with("Can't reach the Gold Coast server")
			and Online.has_saved_login(),
			"  ...and if the server can't be reached, the card says so (and keeps the login for next time)")
	_fake.reachable = true


func _check_reading() -> void:
	_card.show_tab(0)
	check(not _card.is_password_shown(), "the password is hidden as it's typed")
	_card.press_eye()
	var shown := _card.is_password_shown()
	_card.press_eye()
	check(shown and not _card.is_password_shown(), "  ...its eye shows it, and hides it again")
	_card.open_document("terms")
	var terms := _card.document_title()
	_card.close_document()
	check(terms == "Terms of Use" and _card.document_title() == "",
			"the box's Terms (and its other pages) open to read over the card, and close again")
	var pages := ["terms", "guidelines", "privacy", "disclaimer", "child_safety"].all(
			func(page: String) -> bool: return Legal.text(page) != "")
	check(pages, "  ...all five pages are there: Terms, Community Guidelines, Privacy Policy, Disclaimer, Child safety")


func _check_log_out() -> void:
	await Online.log_in(AMA.email, AMA.password)
	_title.open()
	await wait_physics_frames(2)
	check(_title.items()[-1] == "LOG OUT", "logged in, the title screen's start menu ends with LOG OUT")
	_phone.press("select") # NEW GAME: into the game
	await wait_physics_frames(3)
	GameState.money = 4321
	await press_action("phone_menu")
	await wait_physics_frames(2)
	var menu := _main.get_node("HUD/PauseMenu") as PauseMenu
	var offered := menu.items()[4]
	for i in PauseMenu.ITEMS.size():
		if _phone.picked_item() == "LOG OUT":
			break
		await press_action("ui_down")
	await press_action("ui_accept")
	var page := _phone.page_lines
	await press_action("ui_accept") # YES
	await wait_physics_frames(2)
	check(offered == "LOG OUT" and not page.is_empty() and page[0] == "LOG OUT?" and page[1] == "IT SAVES YOUR"
			and GameState.peek_save().get("money", 0) == 4321 and not Online.is_logged_in() and not Online.has_saved_login(),
			"the phone menu's LOG OUT saves her game first, logs her out, and forgets the login in this browser")
	await Online.log_in(AMA.email, AMA.password)
	_title.open()
	await wait_physics_frames(2)
	_phone.press("up") # from NEW GAME round to the last item, LOG OUT
	await wait_physics_frames(1)
	var picked := _phone.picked_item()
	_phone.press("select")
	await wait_physics_frames(2)
	check(picked == "LOG OUT" and not Online.is_logged_in() and _title.is_asking_for_account(),
			"  ...and the title screen's LOG OUT goes back to the account card, to switch accounts")
