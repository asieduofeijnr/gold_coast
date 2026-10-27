extends TestCase
## Checks Maame Esi's chop bar: E at the counter opens her menu board (and
## pauses the game), buying a dish pays by mobile money and she sits down and
## eats it, buying with too little money fails cleanly, and washing her bowls
## earns money once a day.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _main: Node
var _player: Player
var _model: PlayerModel
var _shop: ChopBarShop
var _phone: Phone


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_model = _player.get_node("Model")
	_shop = _main.get_node("ChopBarShop")
	_phone = _main.get_node("HUD/Phone")
	await wait_physics_frames(10)

	await _check_washing() # first, before the menu has ever been opened
	await _check_menu()
	await _check_buying()
	await _check_too_little_money()
	await _check_too_full()
	await _check_mouse()

	get_tree().paused = false
	_main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _check_menu() -> void:
	var board := _shop.board
	await _open_menu()
	check(board.is_open() and get_tree().paused, "E at the counter opens the menu board, and the game pauses")
	check(board.foods.size() == 6 and board.foods[0].title == "Waakye" and board.foods[0].price == 2500,
			"  ...it lists the chop bar's %d dishes with their prices (waakye is %s)"
			% [board.foods.size(), Format.cedis(board.foods[0].price)])
	var clock := GameState.minutes
	GameState.time_speed = 1.0
	await wait_physics_frames(30)
	check(GameState.minutes == clock, "  ...the clock stops while you choose")
	GameState.time_speed = 0.0
	check(board.line.begins_with("Akwaaba"), "  ...and Maame Esi welcomes you: \"%s\"" % board.line)
	await press_action("ui_down")
	await press_action("ui_down")
	check(board.selected == 2, "the arrow keys move down the menu")
	await press_action("ui_up")
	check(board.selected == 1, "  ...and back up")
	await press_action("ui_cancel")
	check(not board.is_open() and not get_tree().paused, "Esc closes it, and the game carries on")


func _check_buying() -> void:
	GameState.money = 10000
	GameState.set_needs(40.0, 80.0)
	await _open_menu()
	_shop.board.selected = 0
	await press_action("ui_accept")
	check(GameState.money == 10000 - 2500 and not _shop.board.is_open() and not get_tree().paused,
			"buying waakye takes GH₵25.00 by mobile money, and the menu closes")
	var text := _phone.shown_sms()
	check(text == PackedStringArray(["PAYMENT SENT", "GH₵25.00", "TO CHOP BAR", "BAL GH₵75.00"]) and _phone.is_beeping(),
			"  ...and the phone beeps with a payment text: %s" % " / ".join(text))
	check(_shop.vendor.saying().begins_with("Enjoy your waakye"), "  ...Maame Esi says \"%s\"" % _shop.vendor.saying())
	check(not _shop.vendor.get_bubble().small, "  ...in a normal-size bubble, because she's talking to her")

	var seated: bool = await wait_until(func() -> bool: return GameState.activity != "", 8.0)
	await wait_physics_frames(30)
	check(seated and _flat_gap(_player, _shop.table.seat) < 0.1 and _shop.table.is_served(),
			"she walks to the table and sits down, and her waakye arrives")
	check(_model.animation_player.current_animation == "eat" and _model.shown_activity() == "Eating waakye",
			"  ...she eats, and \"Eating waakye...\" shows over her head")
	check(GameState.time_speed > 1.0, "  ...and time runs faster while she eats")
	var finished: bool = await wait_until(func() -> bool: return GameState.activity == "", 6.0)
	var expected := 40.0 + 45.0 - GameState.hunger_per_hour * 0.5
	check(finished and absf(GameState.hunger - expected) < 0.1 and "+45 food" in _floating_words(),
			"after half an hour her meal is done: hunger is up from 40 to %.1f, and \"+45 food\" floats up"
			% GameState.hunger)
	check(GameState.time_speed == 0.0 and not _shop.table.is_served(), "  ...the bowl is cleared and time runs normally again")
	var up: bool = await wait_until(func() -> bool: return _player.is_free(), 2.0)
	check(up and _model.animation_player.current_animation != "eat", "  ...and she gets up, free to go")


func _check_too_little_money() -> void:
	GameState.money = 500
	GameState.set_needs(40.0, 80.0)
	await _open_menu()
	_shop.board.selected = 0
	await press_action("ui_accept")
	check(GameState.money == 500 and GameState.hunger == 40.0,
			"buying waakye with only GH₵5.00 fails cleanly: her money and hunger don't change")
	var text := _phone.shown_sms()
	check(text == PackedStringArray(["PAYMENT FAILED", "NEED GH₵25.00", "BAL GH₵5.00", "GET A HUSTLE!"]),
			"  ...the phone says the payment failed and to get a hustle: %s" % " / ".join(text))
	check(_shop.board.is_open() and "Wash my bowls" in _shop.board.line,
			"  ...the menu stays open, and Maame Esi offers work: \"%s\"" % _shop.board.line)
	check(GameState.activity == "" and not _shop.table.is_served(), "  ...and no food comes")

	_shop.board.selected = 5
	await press_action("ui_accept")
	check(GameState.money == 400 and not _shop.board.is_open(), "  ...but she can still afford a sachet of pure water (GH₵1.00)")
	await wait_until(func() -> bool: return _player.is_free() and GameState.activity == "", 10.0)


func _check_too_full() -> void:
	GameState.money = 10000
	GameState.set_needs(98.0, 80.0)
	await _open_menu()
	_shop.board.selected = 0
	await press_action("ui_accept")
	check(GameState.money == 10000 and _shop.board.is_open() and "full" in _shop.board.line,
			"when she's full, Maame Esi won't sell her more (\"%s\"), and nothing is paid" % _shop.board.line)
	await press_action("ui_cancel")


func _check_mouse() -> void:
	var board := _shop.board
	GameState.set_needs(40.0, 80.0)
	await _open_menu()
	await move_mouse_to(board.row_center(4))
	check(board.selected == 4, "pointing at a dish on the menu picks it")
	await click_at(board.row_center(4))
	check(GameState.money == 10000 - 1000 and not board.is_open(), "  ...and clicking it buys it (kelewele, GH₵10.00)")
	await wait_until(func() -> bool: return _player.is_free() and GameState.activity == "", 10.0)

	await _open_menu()
	await click_at(Vector2(5, 5))
	check(not board.is_open() and not get_tree().paused, "clicking outside the board closes it")


func _check_washing() -> void:
	GameState.set_time(1, 9 * 60.0)
	GameState.bowls_washed_day = 0
	var money := GameState.money
	var basin := _shop.basin_spot
	teleport(_player, basin.global_position + Vector3(0, 0.05, 0.4))
	await wait_physics_frames(3)
	check(_player.focus == basin and basin.get_sign().text == "Wash bowls  +GH₵20.00",
			"at the basin, the sign offers work: %s" % basin.get_sign().text)
	check(_shop.vendor.saying() in _shop.vendor.greetings and _shop.vendor.get_bubble().small,
			"  ...and Maame Esi calls out in a small bubble: \"%s\"" % _shop.vendor.saying())
	await press_action("interact")
	var started: bool = await wait_until(func() -> bool: return GameState.activity == ChopBarShop.WASHING, 4.0)
	await wait_physics_frames(30)
	check(started and _model.animation_player.current_animation == "wash", "pressing E there, she gets to work washing bowls")
	var done: bool = await wait_until(func() -> bool: return GameState.activity == "", 6.0)
	check(done and GameState.money == money + ChopBarShop.WAGE and "+GH₵20.00" in _floating_words(),
			"  ...after an hour of washing, she's paid GH₵20.00 (\"+GH₵20.00\" floats up)")
	var text := _phone.shown_sms()
	check(text.size() == 4 and text[0] == "RECEIVED" and text[1] == "GH₵20.00" and text[2] == "FROM CHOP BAR",
			"  ...by mobile money, with a text: %s" % " / ".join(text))
	check(absf(GameState.minutes - 10 * 60.0) < 1.0, "  ...and an hour has gone by (it's %s)" % Format.clock(GameState.minutes))

	await wait_until(func() -> bool: return _player.is_free(), 2.0)
	await wait_physics_frames(3)
	await press_action("interact")
	await wait_physics_frames(5)
	check(GameState.money == money + ChopBarShop.WAGE and GameState.activity == ""
			and "tomorrow" in _shop.vendor.saying() and "tomorrow" in basin.get_sign().text,
			"she can only wash them once a day (\"%s\")" % _shop.vendor.saying())
	GameState.set_time(2, 9 * 60.0)
	await wait_physics_frames(2)
	await press_action("interact")
	var again: bool = await wait_until(func() -> bool: return GameState.activity == ChopBarShop.WASHING, 4.0)
	check(again, "  ...and the next day there are more bowls to wash")
	await wait_until(func() -> bool: return _player.is_free() and GameState.activity == "", 8.0)


## Puts her in front of the counter and presses E.
func _open_menu() -> void:
	teleport(_player, _shop.counter.global_position + Vector3(0, 0.05, 0.3))
	await wait_physics_frames(3)
	await press_action("interact")


## The words floating up over her head right now (like "+45 food").
func _floating_words() -> Array[String]:
	var words: Array[String] = []
	for layer in _player.get_children(true):
		for child in layer.get_children():
			if child is FloatingText:
				words.append((child as FloatingText).text)
	return words


func _flat_gap(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
