extends TestCase
## Checks rent and saving. Rent comes out every Monday by mobile money, or she
## owes it and her room locks until she pays the landlady. Going to bed saves the
## game, and loading it brings back her money, the time, her needs, and the rest.
## A missing or broken save leaves a new game untouched.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	_check_saving()
	_check_rent()
	await _check_in_game()
	GameState.delete_save()
	GameState.reset()


func _check_saving() -> void:
	_start_over()
	GameState.money = 12345
	GameState.set_time(3, 21 * 60.0 + 30.0)
	GameState.set_needs(64.0, 41.0)
	GameState.rent_owed = 14000
	GameState.next_rent_day = 15
	GameState.bowls_washed_day = 3
	check(GameState.save_game() and GameState.has_save(), "the game can be saved to a file")
	GameState.reset()
	check(GameState.load_game(), "  ...and loaded again")
	check(GameState.money == 12345 and GameState.day == 3 and is_equal_approx(GameState.minutes, 21 * 60.0 + 30.0),
			"loading brings back her money and the time (%s on day %d at %s)"
			% [Format.cedis(GameState.money), GameState.day, Format.clock(GameState.minutes)])
	check(is_equal_approx(GameState.hunger, 64.0) and is_equal_approx(GameState.energy, 41.0),
			"  ...her needs (hunger %.0f, energy %.0f)" % [GameState.hunger, GameState.energy])
	check(GameState.rent_owed == 14000 and GameState.next_rent_day == 15 and GameState.bowls_washed_day == 3,
			"  ...the rent she owes, the next rent day, and the bowls she's washed")

	_start_over()
	GameState.set_needs(70.0, 40.0)
	GameState.sleep(true)
	var saved_in_bed := GameState.has_save()
	GameState.reset()
	GameState.load_game()
	check(saved_in_bed and GameState.sleeping and GameState.in_bed and GameState.time_speed == GameState.sleep_time_speed,
			"going to bed saves the game, and loading it has her asleep in bed again")

	_start_over()
	GameState.money = 777
	check(not GameState.load_game() and GameState.money == 777, "with no saved game, loading changes nothing")
	var file := FileAccess.open(GameState.save_path, FileAccess.WRITE)
	file.store_string("this is not a saved game {")
	file.close()
	check(not GameState.load_game() and GameState.money == 777, "  ...and a broken save is ignored, so a new game starts cleanly")


func _check_rent() -> void:
	_start_over()
	var sent := []
	var on_sent := func(amount: int, payee: String) -> void: sent.append([amount, payee])
	var reminders := []
	var on_reminder := func(amount: int) -> void: reminders.append(amount)
	var missed := []
	var on_missed := func(owed: int) -> void: missed.append(owed)
	GameState.payment_sent.connect(on_sent)
	GameState.rent_reminder.connect(on_reminder)
	GameState.rent_missed.connect(on_missed)

	GameState.money = 30000
	GameState.set_time(7, 17 * 60.0)
	GameState.advance(90.0)
	check(reminders == [GameState.RENT], "on Sunday evening, a reminder comes: rent is due tomorrow")
	GameState.set_time(8, 7 * 60.0 + 30.0)
	GameState.advance(60.0)
	check(GameState.money == 30000 - 14000 and sent == [[14000, "LANDLADY"]] and GameState.rent_owed == 0,
			"on Monday morning, the week's rent (GH₵140.00) goes to the landlady by mobile money")
	GameState.advance(60.0)
	check(GameState.money == 16000 and GameState.next_rent_day == 15, "  ...only once, and the next rent is due a week later")

	GameState.money = 5000
	GameState.set_time(15, 7 * 60.0 + 59.0)
	GameState.advance(2.0)
	check(GameState.rent_owed == 14000 and GameState.money == 5000 and missed == [14000] and GameState.is_room_locked(),
			"when she can't pay, she owes the rent and her room is locked")
	GameState.set_needs(80.0, 40.0)
	check(not GameState.sleep(true) and not GameState.sleeping, "  ...so she can't sleep in her bed")
	GameState.money = 20000
	check(GameState.pay_rent() and GameState.rent_owed == 0 and GameState.money == 6000 and not GameState.is_room_locked(),
			"paying what she owes unlocks it")

	GameState.payment_sent.disconnect(on_sent)
	GameState.rent_reminder.disconnect(on_reminder)
	GameState.rent_missed.disconnect(on_missed)


func _check_in_game() -> void:
	_start_over()
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	var phone := main.get_node("HUD/Phone") as Phone
	var home := main.get_node("Home") as Home

	GameState.receive(2000, "SERWAA")
	GameState.pay(500, "CHOP BAR")
	GameState.set_needs(80.0, 50.0)
	await _press_at_door(main)
	await wait_until(func() -> bool: return GameState.in_bed, 4.0)
	var text := phone.shown_sms()
	check(GameState.has_save() and text == PackedStringArray(["GAME SAVED", "DAY 1", "IN +GH₵20.00", "OUT -GH₵5.00"]),
			"going to bed at home saves the game, and the phone sums up the day: %s" % " / ".join(text))
	check(phone.can_show("".join(text)), "  ...and its screen can draw every character (the + too)")

	GameState.set_needs(80.0, 100.0) # rested: she wakes up
	await wait_until(func() -> bool: return (main.get_node("Player") as Player).is_free(), 4.0)
	GameState.money = 1000
	GameState.next_rent_day = GameState.day
	GameState.set_time(GameState.day, 7 * 60.0 + 59.0)
	GameState.advance(2.0)
	await wait_physics_frames(3)
	text = phone.shown_sms()
	check(not text.is_empty() and text[0] == "RENT DUE!" and "Rent day" in home.landlady.saying()
			and home.door.get_sign().text == "Pay rent  GH₵140.00",
			"when the rent can't be paid, the phone says RENT DUE!, Auntie Adwoa says so, and the door asks for it")
	await _press_at_door(main)
	check(GameState.is_room_locked() and "No money" in home.landlady.saying() and not GameState.sleeping,
			"  ...with too little money, the door stays locked: \"%s\"" % home.landlady.saying())
	GameState.money = 20000
	await _press_at_door(main)
	check(not GameState.is_room_locked() and GameState.money == 6000 and "Thank you" in home.landlady.saying()
			and not home.door.get_sign().text.begins_with("Pay rent"),
			"paying the rent at the door unlocks her room")

	GameState.set_needs(80.0, 40.0)
	GameState.sleep(true)
	main.queue_free()
	await get_tree().process_frame
	GameState.reset()
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	check(GameState.load_game(), "the saved game loads when the game starts again")
	(main as Node).call("continue_from_save")
	await wait_physics_frames(30)
	var player := main.get_node("Player") as Player
	var model := player.get_node("Model") as PlayerModel
	home = main.get_node("Home") as Home
	var gap := Vector2(player.global_position.x - home.door.global_position.x,
			player.global_position.z - home.door.global_position.z).length()
	check(GameState.in_bed and GameState.sleeping and gap < 0.3 and model.faded() > 0.99 and home.is_snoring(),
			"  ...with her back in her bed at home, asleep")
	var woke: bool = await wait_until(func() -> bool: return not GameState.sleeping, 8.0)
	await wait_physics_frames(40)
	check(woke and player.is_free() and model.faded() < 0.01, "  ...and she gets up once she's rested")
	main.queue_free()
	await get_tree().process_frame


# Puts her at her front door and presses E.
func _press_at_door(main: Node) -> void:
	var door := (main.get_node("Home") as Home).door
	teleport(main.get_node("Player") as Player, door.global_position + Vector3(0, 0.05, 0.4))
	await wait_physics_frames(3)
	await press_action("interact")
	await wait_physics_frames(2)


## Starts from a fresh game with the clock stopped and no saved game.
func _start_over() -> void:
	GameState.delete_save()
	GameState.reset()
	GameState.time_speed = 0.0
