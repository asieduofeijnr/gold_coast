extends TestCase
## Checks the game's menu on her phone, saving anywhere, and the title screen.
## M or Esc (or the phone's middle key) holds the phone up with the menu on it
## and pauses the game. The keys move through it, and so do the phone's own
## keys, clicked. Save game keeps her spot, the way she faces, and her load,
## but not while she's busy or asleep in the street. Load game and New game
## ask first. How to play pages through, and every line fits the phone's
## screen. The title screen offers to carry on from the saved game.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _main: Node
var _player: Player
var _phone: Phone
var _menu: PauseMenu


func run_tests() -> void:
	GameState.reset()
	GameState.delete_save()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_phone = _main.get_node("HUD/Phone")
	_menu = _main.get_node("HUD/PauseMenu")
	await wait_physics_frames(10)
	await _check_opening()
	await _check_saving_anywhere()
	await _check_refusals()
	await _check_new_game()
	await _check_help()
	await _check_title_screen()
	get_tree().paused = false
	_main.queue_free()
	await get_tree().process_frame
	GameState.delete_save()
	GameState.reset()


func _check_opening() -> void:
	await press_action("phone_menu")
	await wait_physics_frames(20) # let the phone come up
	check(_menu.is_open() and get_tree().paused and _phone.is_held_up() and _phone.screen == Phone.Screen.MENU
			and _phone.menu_items == PackedStringArray(PauseMenu.ITEMS),
			"M (or Esc) holds her phone up with the menu on it, and the game pauses: %s" % " / ".join(_phone.menu_items))
	await press_action("ui_down")
	check(_phone.picked_item() == "SAVE GAME", "the arrow keys move down the menu")
	await press_action("move_forward")
	check(_phone.picked_item() == "RESUME", "  ...and up again (W and S work too)")
	await _click_key("down")
	check(_phone.picked_item() == "SAVE GAME", "clicking the phone's own scroll key moves down too")
	await _click_key("back")
	await wait_physics_frames(20)
	check(not _menu.is_open() and not get_tree().paused and not _phone.is_held_up() and _phone.screen == Phone.Screen.HOME,
			"its C key closes the menu, the phone goes back to its corner, and the game carries on")
	await _click_key("select")
	await wait_physics_frames(20)
	check(_menu.is_open() and get_tree().paused, "the phone's middle key opens the menu too")
	await press_action("ui_accept")
	check(not _menu.is_open() and not get_tree().paused, "RESUME goes back to the game")


func _check_saving_anywhere() -> void:
	GameState.set_time(2, 10 * 60.0 + 30.0)
	GameState.money = 4200
	var store := _main.get_node("DeliverySpots/ToProvisionsStore") as DeliverySpot
	var headload := Delivery.new()
	headload.goods = "yams"
	headload.place = store.place_name
	headload.phone_place = store.phone_name
	headload.receiver = store.receiver
	headload.payer = "SERWAA"
	headload.pay = 1400
	headload.minutes = 28.0
	GameState.pick_up(headload)
	var spot := Vector3(-3.0, 0.05, 6.5)
	_player.place(spot, 1.2)
	await wait_physics_frames(3)
	await _choose("SAVE GAME")
	check(_phone.screen == Phone.Screen.PAGE and _phone.page_lines[0] == "GAME SAVED." and GameState.has_save(),
			"SAVE GAME saves her game wherever she is: %s" % " / ".join(_phone.page_lines))
	await press_action("ui_accept")
	check(_phone.screen == Phone.Screen.MENU and _phone.picked_item() == "SAVE GAME", "  ...OK goes back to the menu")
	await press_action("ui_cancel")

	# Carry on playing a bit (the load gets handed back, she walks off, time passes)...
	GameState.give_back_load()
	GameState.set_time(3, 8 * 60.0)
	GameState.money = 100
	_player.place(Vector3(10.0, 0.05, 3.0), 0.0)
	await wait_physics_frames(3)
	await _choose("LOAD GAME")
	check(_phone.page_lines[0] == "LOAD THE SAVE?" and _phone.page_lines[1] == "TUE DAY 2" and _phone.soft_key == "YES",
			"LOAD GAME asks first, saying when the game was saved: %s" % " / ".join(_phone.page_lines))
	await press_action("ui_accept")
	await wait_physics_frames(5)
	GameState.time_speed = 0.0 # (loading sets the clock going again)
	var gap := Vector2(_player.global_position.x - spot.x, _player.global_position.z - spot.z).length()
	check(not _menu.is_open() and not get_tree().paused and GameState.day == 2 and absf(GameState.minutes - 630.0) < 1.0
			and GameState.money == 4200 and gap < 0.05 and absf(angle_difference(_player.rotation.y, 1.2)) < 0.01,
			"  ...YES puts her back on the same spot (%.2f m off), facing the same way (%.2f), on day %d at %s, with %s"
			% [gap, _player.rotation.y, GameState.day, Format.clock(GameState.minutes), Format.cedis(GameState.money)])
	check(GameState.delivery != null and GameState.delivery.place == store.place_name
			and is_equal_approx(GameState.delivery.due, headload.due) and _phone.screen_day == "TO STORE" and store.is_marked(),
			"  ...still carrying her load, due when it was before (the phone says %s)" % _phone.screen_day)
	GameState.give_back_load()


func _check_refusals() -> void:
	GameState.delete_save()
	GameState.start_activity("Eating waakye", 30.0, 3.0)
	await _choose("SAVE GAME")
	check(_phone.page_lines.size() > 1 and _phone.page_lines[1] == "SHE IS BUSY" and not GameState.has_save(),
			"she can't save while she's busy eating: %s" % " / ".join(_phone.page_lines))
	await press_action("ui_cancel")
	await press_action("ui_cancel")
	GameState.stop_activity()
	GameState.set_needs(80.0, 50.0)
	GameState.sleep()
	await _choose("SAVE GAME")
	check(_phone.page_lines.size() > 1 and _phone.page_lines[1] == "SHE IS ASLEEP" and not GameState.has_save(),
			"  ...or while she's asleep in the street: %s" % " / ".join(_phone.page_lines))
	await press_action("ui_cancel")
	await press_action("ui_cancel")
	GameState.set_needs(80.0, 100.0)
	GameState.wake_up()
	await wait_physics_frames(30)


func _check_new_game() -> void:
	GameState.money = 777
	GameState.set_time(4, 10 * 60.0)
	GameState.save_game()
	await _choose("NEW GAME")
	check(_phone.page_lines[0] == "START AGAIN?" and _phone.soft_key == "YES", "NEW GAME asks first: %s" % " / ".join(_phone.page_lines))
	await press_action("ui_cancel")
	check(_phone.screen == Phone.Screen.MENU and GameState.money == 777, "  ...C means no, and nothing changes")
	await _choose("NEW GAME")
	await press_action("ui_accept")
	await wait_physics_frames(3)
	var start := Vector3(0.0, 0.05, 5.0)
	check(not _menu.is_open() and GameState.money == GameState.STARTING_MONEY and GameState.day == 1
			and _player.global_position.distance_to(start) < 0.1 and GameState.has_save(),
			"  ...YES starts a new game (GH₵100.00 on day 1, back at the start), and the old save stays until the next save")


func _check_help() -> void:
	var fits := true
	for page: Array in PauseMenu.HOW_TO_PLAY:
		for line: String in page:
			fits = fits and line.length() <= Phone.MAX_CHARACTERS and _phone.can_show(line)
	check(fits and PauseMenu.HOW_TO_PLAY.size() == 8, "every line of How to play fits the phone's screen, in its own font")
	await _choose("HOW TO PLAY")
	check(_phone.page_title == "HELP 1/8" and _phone.page_lines[0] == "WALK: WASD OR", "HOW TO PLAY shows the first page: %s"
			% " / ".join(_phone.page_lines))
	await press_action("ui_down")
	check(_phone.page_title == "HELP 2/8", "  ...the scroll key turns the pages")
	for i in PauseMenu.HOW_TO_PLAY.size() - 1:
		await press_action("ui_accept")
	check(_phone.screen == Phone.Screen.MENU and _phone.picked_item() == "HOW TO PLAY", "  ...and after the last page, back to the menu")
	await press_action("ui_cancel")


func _check_title_screen() -> void:
	var title := _main.get_node("HUD/TitleScreen") as TitleScreen
	GameState.money = 23000
	GameState.set_time(5, 14 * 60.0 + 20.0)
	GameState.save_game()
	GameState.reset()
	title.open()
	await wait_physics_frames(20)
	check(title.is_open() and get_tree().paused and _phone.is_held_up()
			and title.items() == PackedStringArray(["CONTINUE", "NEW GAME", "HOW TO PLAY"])
			and "day 5, 14:20" in title.saved_game_line() and "GH₵230.00" in title.saved_game_line(),
			"the title screen offers to carry on from the saved game: \"%s\"" % title.saved_game_line())
	await press_action("ui_accept")
	await wait_physics_frames(5)
	check(not title.is_open() and not get_tree().paused and GameState.day == 5 and GameState.money == 23000,
			"  ...CONTINUE carries on from it")
	GameState.delete_save()
	title.open()
	await wait_physics_frames(5)
	check(title.items() == PackedStringArray(["NEW GAME", "HOW TO PLAY"]) and title.saved_game_line() == "",
			"with no saved game, it offers NEW GAME and HOW TO PLAY")
	await press_action("ui_accept")
	await wait_physics_frames(5)
	check(not title.is_open() and not get_tree().paused, "  ...and NEW GAME starts")


# Opens the menu (if it isn't open), picks `item` with the down key, and chooses it.
func _choose(item: String) -> void:
	if not _menu.is_open():
		await press_action("phone_menu")
		await wait_physics_frames(2)
	for i in PauseMenu.ITEMS.size():
		if _phone.picked_item() == item:
			break
		await press_action("ui_down")
	await press_action("ui_accept")


# Clicks one of the phone's keys, where it shows on the screen right now.
func _click_key(key: String) -> void:
	await click_at(_phone.get_global_transform() * _phone.key_rect(key).get_center())
