extends TestCase
## Checks her needs: hunger and energy drain at their set rates (faster when
## walking or starving), stay between 0 and 100, and sleeping refills energy
## (faster in her bed at home, and outside the mosquitoes wake her). Running out
## of energy makes her pass out, being sleepy slows her down, and the phone shows
## it all.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	_check_draining()
	_check_sleep()
	_check_bed_and_mosquitoes()
	await _check_in_game()
	GameState.reset()


func _check_draining() -> void:
	_start_over(100.0, 100.0)
	check(is_equal_approx(GameState.hunger, 100.0) and is_equal_approx(GameState.energy, 100.0),
			"she starts full and rested")

	GameState.advance(5 * 60.0)
	check(is_equal_approx(GameState.hunger, 100.0 - 5 * GameState.hunger_per_hour)
			and is_equal_approx(GameState.energy, 100.0 - 5 * GameState.energy_per_hour),
			"after 5 game hours, hunger and energy have drained at their set rates (now %.0f and %.0f)"
			% [GameState.hunger, GameState.energy])

	_start_over(100.0, 100.0)
	GameState.is_walking = true
	GameState.advance(60.0)
	var walking_rate := GameState.energy_per_hour + GameState.walking_energy_per_hour
	check(is_equal_approx(GameState.energy, 100.0 - walking_rate), "walking drains energy faster (%.0f an hour)" % walking_rate)

	_start_over(0.0, 100.0)
	GameState.advance(60.0)
	check(is_equal_approx(GameState.energy, 100.0 - GameState.energy_per_hour * GameState.starving_energy_multiplier),
			"when she's starving, energy drains twice as fast")

	_start_over(10.0, 100.0)
	GameState.advance(5 * 60.0)
	GameState.set_needs(150.0, 120.0)
	var capped := GameState.hunger == 100.0 and GameState.energy == 100.0
	_start_over(10.0, 100.0)
	GameState.advance(5 * 60.0)
	check(GameState.hunger == 0.0 and capped, "needs never go below 0 or above 100")

	_start_over(100.0, 100.0)
	var announced := [0]
	var listen := func(_hunger: float, _energy: float) -> void: announced[0] += 1
	GameState.needs_changed.connect(listen)
	GameState.advance(0.1)
	var after_a_moment: int = announced[0]
	GameState.advance(60.0)
	GameState.needs_changed.disconnect(listen)
	check(after_a_moment == 0 and announced[0] == 1, "needs are announced when they change by a whole point")


func _check_sleep() -> void:
	_start_over(100.0, 100.0)
	var refused := [""]
	var listen := func(reason: String) -> void: refused[0] = reason
	GameState.sleep_refused.connect(listen)
	check(not GameState.sleep() and refused[0] == "NOT SLEEPY" and not GameState.sleeping,
			"she can't sleep when she isn't tired")
	GameState.sleep_refused.disconnect(listen)

	_start_over(80.0, 60.0)
	check(GameState.sleep() and GameState.sleeping and GameState.time_speed == GameState.sleep_time_speed,
			"when she's tired she can sleep, and time speeds up")
	GameState.advance(3 * 60.0)
	check(is_equal_approx(GameState.energy, 60.0 + 3 * GameState.sleep_energy_per_hour)
			and is_equal_approx(GameState.hunger, 80.0 - 3 * GameState.hunger_per_hour * GameState.sleep_hunger_multiplier),
			"  ...sleep refills energy, and hunger drains half as fast (now %.0f and %.0f)" % [GameState.energy, GameState.hunger])
	GameState.advance(60.0)
	check(not GameState.sleeping and GameState.time_speed == 0.0, "  ...and she wakes up by herself once fully rested")

	_start_over(80.0, 2.0)
	GameState.advance(60.0)
	check(GameState.sleeping and GameState.passed_out, "when her energy runs out, she passes out")
	check(not GameState.wake_up() and GameState.sleeping, "  ...and can't be woken straight away")
	GameState.advance(2 * 60.0)
	check(GameState.wake_up() and not GameState.sleeping, "  ...but can after a couple of hours' rest")


func _check_bed_and_mosquitoes() -> void:
	_start_over(80.0, 95.0)
	check(not GameState.sleep() and GameState.sleep(true) and GameState.in_bed,
			"a little tired, she can't sleep outside, but she can in her bed at home")

	_start_over(80.0, 10.0)
	GameState.sleep(true)
	for hour in 4:
		GameState.advance(60.0)
	check(is_equal_approx(GameState.energy, 10.0 + 4 * GameState.bed_energy_per_hour),
			"her bed refills energy faster than the street (%.0f an hour instead of %.1f)"
			% [GameState.bed_energy_per_hour, GameState.sleep_energy_per_hour])
	check(GameState.sleeping, "  ...and after 4 hours in bed she's still asleep: no mosquitoes indoors")

	_start_over(80.0, 10.0)
	var bitten := [false]
	var listen := func() -> void: bitten[0] = true
	GameState.mosquitoes_woke_her.connect(listen)
	GameState.sleep()
	for hour in 3:
		GameState.advance(60.0)
	var asleep_after_3 := GameState.sleeping
	GameState.advance(60.0)
	GameState.mosquitoes_woke_her.disconnect(listen)
	check(asleep_after_3 and not GameState.sleeping and bitten[0],
			"sleeping outside, mosquitoes wake her after %.0f hours" % GameState.mosquito_hours)
	check(is_equal_approx(GameState.energy, 10.0 + 4 * GameState.sleep_energy_per_hour) and not GameState.in_bed,
			"  ...with her energy only half back (%.0f)" % GameState.energy)


func _check_in_game() -> void:
	_start_over(100.0, 10.0)
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	var player := main.get_node("Player") as Player
	var model := player.get_node("Model") as PlayerModel
	var phone := main.get_node("HUD/Phone") as Phone
	var shade := main.get_node("HUD/SleepShade") as ColorRect
	await wait_physics_frames(10)

	var start := player.global_position
	Input.action_press("move_forward")
	await wait_physics_frames(60)
	Input.action_release("move_forward")
	await wait_physics_frames(20)
	var walked := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	check(walked < player.walk_speed * 0.8 and walked > player.walk_speed * 0.5,
			"when she's sleepy she walks more slowly (%.1f m in a second instead of %.1f)" % [walked, player.walk_speed])
	check(phone.energy == GameState.energy and phone.hunger == GameState.hunger and phone.is_warning(),
			"the phone shows her needs, and warns when one is low")
	check(phone.screen_title == "Z TO SLEEP", "  ...telling you to press Z to sleep")

	GameState.set_needs(100.0, 50.0)
	await press_action("sleep")
	await wait_physics_frames(45)
	check(GameState.sleeping and model.lying() > 0.9, "pressing Z makes her lie down and sleep")
	check(shade.color.a > 0.4 and phone.screen_title == "SLEEPING...", "  ...the screen dims, and the phone says SLEEPING...")
	Input.action_press("move_forward")
	await wait_physics_frames(5)
	Input.action_release("move_forward")
	await wait_physics_frames(45)
	check(not GameState.sleeping and model.lying() < 0.1, "a movement key wakes her up, and she stands")

	GameState.time_speed = 0.0
	GameState.set_needs(10.0, 90.0)
	check(phone.screen_title == "HUNGRY!", "the phone says HUNGRY! when she needs food")
	await press_action("debug_fill_needs")
	check(GameState.hunger == 100.0 and GameState.energy == 100.0, "F6 (debug) fills both needs")
	await press_action("sleep")
	check(phone.shown_title() == "NOT SLEEPY" and not GameState.sleeping, "pressing Z when she's rested says NOT SLEEPY")

	main.queue_free()


## Starts from a fresh game with the clock stopped and these needs.
func _start_over(hunger: float, energy: float) -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_needs(hunger, energy)
