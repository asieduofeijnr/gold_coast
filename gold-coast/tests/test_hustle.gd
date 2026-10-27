extends TestCase
## Checks the first hustle: carrying loads like a kayayo (a head porter).
## Picking up a load, delivering it in time (full pay) or late (half pay),
## giving it back (no pay), and dropping it when she passes out. Carrying tires
## her faster, and she can't go to sleep with a load on her head. In the game:
## Madam Serwaa's market, the headpan, the phone, the way-finding ring and
## arrow, and a whole day of work, food, and sleep.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _main: Node
var _player: Player
var _model: PlayerModel
var _market: Market
var _phone: Phone


func run_tests() -> void:
	_check_loads()
	_check_carrying_is_tiring()
	await _check_in_game()
	await _check_a_whole_day()
	GameState.reset()
	await get_tree().process_frame


func _check_loads() -> void:
	_start_over(80.0, 80.0)
	var changes := []
	var on_change := func(headload: Delivery) -> void: changes.append(headload)
	GameState.load_changed.connect(on_change)

	var headload := _make_load(1200, 25.0)
	check(GameState.pick_up(headload) and GameState.delivery == headload and changes == [headload],
			"she can pick up a load, and it's announced")
	check(is_equal_approx(GameState.delivery_minutes_left(), 25.0), "  ...with its time limit (25 minutes) starting now")
	check(not GameState.pick_up(_make_load(500, 10.0)), "  ...and she can only carry one load at a time")
	GameState.advance(20.0)
	check(GameState.deliver_load() == 1200 and GameState.money == 10000 + 1200 and GameState.delivery == null,
			"delivering it in time pays in full (GH₵12.00)")

	GameState.pick_up(_make_load(1200, 25.0))
	GameState.advance(30.0)
	check(GameState.delivery_minutes_left() < 0.0 and GameState.deliver_load() == 600,
			"delivering it late pays half (GH₵6.00)")

	var money := GameState.money
	GameState.pick_up(_make_load(1200, 25.0))
	GameState.give_back_load()
	check(GameState.delivery == null and GameState.money == money, "giving a load back pays nothing")

	var refused := [""]
	var listen := func(reason: String) -> void: refused[0] = reason
	GameState.sleep_refused.connect(listen)
	GameState.set_needs(80.0, 40.0)
	GameState.pick_up(_make_load(1200, 25.0))
	check(not GameState.sleep() and refused[0] == "DELIVER IT!" and GameState.delivery != null,
			"she can't go to sleep with a load on her head (the phone says DELIVER IT!)")
	GameState.sleep_refused.disconnect(listen)

	var dropped := []
	var on_drop := func(lost: Delivery) -> void: dropped.append(lost)
	GameState.load_dropped.connect(on_drop)
	var heavy := GameState.delivery
	GameState.set_needs(80.0, 1.0)
	GameState.advance(30.0)
	check(GameState.passed_out and GameState.delivery == null and dropped == [heavy] and GameState.money == money,
			"if she passes out, she drops her load, and isn't paid")
	GameState.load_dropped.disconnect(on_drop)
	GameState.load_changed.disconnect(on_change)


func _check_carrying_is_tiring() -> void:
	_start_over(80.0, 80.0)
	GameState.pick_up(_make_load(1200, 60.0))
	GameState.advance(60.0)
	var rate := GameState.energy_per_hour + GameState.carrying_energy_per_hour
	check(is_equal_approx(GameState.energy, 80.0 - rate),
			"carrying a load tires her faster (%.0f energy an hour instead of %.0f)" % [rate, GameState.energy_per_hour])


func _check_in_game() -> void:
	_start_over(80.0, 90.0)
	GameState.set_time(1, 8 * 60.0)
	await _load_main()
	var store := _main.get_node("DeliverySpots/ToProvisionsStore") as DeliverySpot
	var hire := _market.hire_spot

	_market.make_offer(store)
	await _go_to(hire)
	check(_player.focus == hire and hire.get_sign().text.begins_with("Carry ") and hire.get_sign().text.ends_with("+GH₵14.00"),
			"at the market, Madam Serwaa offers a load to carry: %s" % hire.get_sign().text)
	await press_action("interact")
	await wait_physics_frames(30)
	check(GameState.delivery != null and GameState.delivery.place == "the Provisions Store" and _model.is_carrying(),
			"E there puts the load on her head, in a headpan")
	check(_model.animation_player.current_animation == "carry_idle", "  ...and she steadies it with one hand")
	check(_market.trader.saying().begins_with("Take the") and "Uncle Kofi" in _market.trader.saying(),
			"  ...Madam Serwaa says where it goes: \"%s\"" % _market.trader.saying())
	check(_phone.screen_day == "TO STORE" and _phone.screen_title == "28 MIN LEFT",
			"  ...the phone shows where it's going and the time left: %s / %s" % [_phone.screen_day, _phone.screen_title])
	var marked := []
	for spot in _main.get_node("DeliverySpots").get_children():
		if (spot as DeliverySpot).is_marked():
			marked.append(str(spot.name))
	check(marked == ["ToProvisionsStore"] and store.get_guide().is_off_screen(),
			"  ...a gold ring marks the store, and an arrow at the edge of the screen points the way")

	var counter := _main.get_node("ChopBarShop/Counter") as Interactable
	await _go_to(counter)
	check(_player.focus == null and not counter.is_sign_showing(),
			"with a load on her head, she can't use other things, like the Chop Bar's stall")

	teleport(_player, Vector3(0.0, 0.05, 2.0))
	await wait_physics_frames(5)
	var start := _player.global_position
	Input.action_press("move_right")
	await wait_physics_frames(30)
	var walking_animation := _model.animation_player.current_animation
	await wait_physics_frames(30)
	Input.action_release("move_right")
	await wait_physics_frames(20)
	var walked := Vector2(_player.global_position.x - start.x, _player.global_position.z - start.z).length()
	check(walked < _player.walk_speed * 0.95 and walked > _player.walk_speed * 0.75 and walking_animation == "carry",
			"she walks a little slower with a load (%.1f m in a second instead of %.1f), one hand on it"
			% [walked, _player.walk_speed])

	GameState.set_needs(80.0, 20.0)
	await press_action("sleep")
	check(not GameState.sleeping and _phone.shown_title() == "DELIVER IT!",
			"Z won't put her to sleep with a load on her head: the phone says DELIVER IT!")
	GameState.set_needs(80.0, 90.0)

	var money := GameState.money
	var goods := GameState.delivery.goods
	await _go_to(store)
	check(_player.focus == store and store.get_sign().text == "Deliver the " + goods,
			"at the store, its sign says: %s" % store.get_sign().text)
	await press_action("interact")
	check(GameState.money == money + 1400 and GameState.delivery == null and not _model.is_carrying(),
			"delivering it in time pays GH₵14.00, and the headpan comes off")
	var text := _phone.shown_sms()
	check(text.size() == 4 and text[0] == "RECEIVED" and text[1] == "GH₵14.00" and text[2] == "FROM SERWAA",
			"  ...by mobile money, with a text: %s" % " / ".join(text))
	check(store.saying().begins_with("Ayekoo"), "  ...and Uncle Kofi says \"%s\"" % store.saying())
	check(not store.is_marked() and _market.offer != null, "  ...the ring goes, and Madam Serwaa has the next load ready")

	money = GameState.money
	_market.make_offer(store)
	await _go_to(hire)
	await press_action("interact")
	GameState.advance(40.0)
	check(_phone.screen_title == "LATE! HURRY", "when the time runs out, the phone says LATE! HURRY")
	await _go_to(store)
	await press_action("interact")
	check(GameState.money == money + 700 and "late" in store.saying(),
			"delivering late pays half (GH₵7.00), and Uncle Kofi says \"%s\"" % store.saying())

	money = GameState.money
	await _go_to(hire)
	await press_action("interact")
	var picked_up := GameState.delivery != null
	await wait_physics_frames(3)
	await press_action("interact")
	check(picked_up and GameState.delivery == null and GameState.money == money and "another kayayo" in _market.trader.saying(),
			"E at Madam Serwaa's stall again gives the load back, for no pay")

	_market.make_offer(store)
	await _go_to(hire)
	await press_action("interact")
	teleport(_player, Vector3(-12.0, 0.05, 2.0))
	await wait_physics_frames(40) # let the camera catch up with her
	var camera := _main.get_node("IsoCamera") as Camera3D
	var box := (_main.get_node("Buildings/ProvisionsStore") as Building).bounds()
	await click_at(camera.unproject_position(Vector3(box.get_center().x, box.end.y - 0.4, box.get_center().z)))
	var delivered: bool = await wait_until(func() -> bool: return GameState.delivery == null, 10.0)
	check(delivered and GameState.money == money + 1400,
			"with a load, clicking the store walks her there and hands it over")

	GameState.set_time(1, 18 * 60.0 + 5.0)
	await _go_to(hire)
	await press_action("interact")
	check(GameState.delivery == null and hire.get_sign().text == "Market closed (opens 06:00)"
			and "closed" in _market.trader.saying(), "after 18:00 the market is closed, and there are no loads")
	GameState.set_time(1, 20 * 60.0)
	await wait_physics_frames(3)
	check(not _market.trader.is_here() and not hire.enabled and not hire.is_sign_showing(),
			"  ...and at night Madam Serwaa has gone home, so there's nobody to ask")

	GameState.set_time(1, 9 * 60.0)
	await _go_to(hire)
	await press_action("interact")
	GameState.set_needs(80.0, 0.5)
	GameState.advance(10.0)
	text = _phone.shown_sms()
	check(GameState.passed_out and GameState.delivery == null and not text.is_empty() and text[0] == "LOAD DROPPED!",
			"if she passes out, she drops the load, and the phone says so: %s" % " / ".join(text))
	_main.queue_free()
	await get_tree().process_frame


## Plays a whole day the quick way: jumping between places, and moving the
## clock on instead of walking. Loads all morning, a meal at the chop bar, more
## loads, another meal, an evening off, then her bed at home.
func _check_a_whole_day() -> void:
	_start_over(100.0, 100.0)
	GameState.set_time(1, 6 * 60.0)
	await _load_main()
	var start_money := GameState.money
	var spots := _main.get_node("DeliverySpots").get_children()
	var loads := 0
	while GameState.minutes < 10.5 * 60.0:
		await _carry_a_load(spots[loads % spots.size()])
		loads += 1
	await _eat(0)
	while GameState.minutes < 14.0 * 60.0:
		await _carry_a_load(spots[loads % spots.size()])
		loads += 1
	await _eat(3)
	while GameState.minutes < 20.0 * 60.0:
		GameState.advance(30.0) # an evening off
	var door := (_main.get_node("Home") as Home).door
	await _go_to(door)
	await press_action("interact")
	await wait_until(func() -> bool: return GameState.in_bed, 4.0)
	for i in 48:
		if not GameState.sleeping:
			break
		GameState.advance(30.0)
	check(GameState.day == 2 and not GameState.sleeping and GameState.money > start_money
			and GameState.hunger > 0.0 and GameState.energy > 0.0,
			"a whole day of %d loads, two meals, and a night in bed: she has %s (from %s), hunger %.0f, energy %.0f"
			% [loads, Format.cedis(GameState.money), Format.cedis(start_money), GameState.hunger, GameState.energy])
	_main.queue_free()
	await get_tree().process_frame


# One trip: take a load at the market, walk there (the clock moves on), hand it
# over, and walk back.
func _carry_a_load(spot: DeliverySpot) -> void:
	_market.make_offer(spot)
	await _go_to(_market.hire_spot)
	await press_action("interact")
	_walk_for(spot.minutes * 0.7)
	await _go_to(spot)
	await press_action("interact")
	_walk_for(15.0)


# Buys dish number `dish` at the chop bar and waits until she's eaten it.
func _eat(dish: int) -> void:
	var shop := _main.get_node("ChopBarShop") as ChopBarShop
	await _go_to(shop.counter)
	await press_action("interact")
	shop.board.selected = dish
	await press_action("ui_accept")
	await wait_until(func() -> bool: return _player.is_free() and GameState.activity == "", 12.0)


# Moves the clock on as if she'd walked for `game_minutes`.
func _walk_for(game_minutes: float) -> void:
	GameState.is_walking = true
	GameState.advance(game_minutes)
	GameState.is_walking = false


# Puts her just in front of `thing`, where she can use it.
func _go_to(thing: Node3D) -> void:
	teleport(_player, thing.global_position + Vector3(0, 0.05, 0.3))
	await wait_physics_frames(3)


func _load_main() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_model = _player.get_node("Model")
	_market = _main.get_node("Market")
	_phone = _main.get_node("HUD/Phone")
	await wait_physics_frames(10)


func _make_load(pay: int, minutes: float) -> Delivery:
	var headload := Delivery.new()
	headload.goods = "tomatoes"
	headload.place = "the Chop Bar"
	headload.phone_place = "CHOP BAR"
	headload.payer = "SERWAA"
	headload.pay = pay
	headload.minutes = minutes
	return headload


## Starts from a fresh game with the clock stopped and these needs.
func _start_over(hunger: float, energy: float) -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_needs(hunger, energy)
