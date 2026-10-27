extends TestCase
## Checks activities: things that keep her busy for a while, like eating a meal
## or washing bowls. Time runs faster while she's busy, a meal gives its hunger
## back bit by bit, and when it's over everything goes back to normal.


func run_tests() -> void:
	_check_meal()
	_check_rules()
	GameState.reset()
	await get_tree().process_frame


func _check_meal() -> void:
	_start_over(40.0, 80.0)
	var changes := []
	var finished := []
	var on_change := func(activity: String) -> void: changes.append(activity)
	var on_finish := func(activity: String, completed: bool) -> void: finished.append([activity, completed])
	GameState.activity_changed.connect(on_change)
	GameState.activity_finished.connect(on_finish)

	check(GameState.start_activity("Eating waakye", 30.0, 3.0, 45.0) and GameState.activity == "Eating waakye",
			"she can start eating a meal")
	check(is_equal_approx(GameState.time_speed, 10.0) and changes == ["Eating waakye"],
			"  ...time runs faster while she eats (30 game minutes in 3 seconds), and it's announced")
	GameState.advance(15.0)
	check(is_equal_approx(GameState.activity_progress(), 0.5)
			and is_equal_approx(GameState.hunger, 40.0 + 45.0 / 2.0 - GameState.hunger_per_hour / 4.0),
			"  ...halfway through, she's had half the meal (hunger %.1f)" % GameState.hunger)
	GameState.advance(15.0)
	check(GameState.activity == "" and finished == [["Eating waakye", true]] and changes == ["Eating waakye", ""],
			"  ...after 30 game minutes she's finished")
	var after_meal := 40.0 + 45.0 - GameState.hunger_per_hour / 2.0
	check(is_equal_approx(GameState.hunger, after_meal) and GameState.time_speed == 0.0,
			"  ...she got all its hunger back (now %.1f), and time runs normally again" % GameState.hunger)
	GameState.advance(60.0)
	check(GameState.hunger < after_meal, "  ...and after the meal, hunger drains again")
	GameState.activity_changed.disconnect(on_change)
	GameState.activity_finished.disconnect(on_finish)


func _check_rules() -> void:
	_start_over(100.0, 80.0)
	GameState.start_activity("Washing bowls", 60.0, 3.0)
	check(not GameState.start_activity("Eating kelewele", 15.0, 3.0), "she can't start something while she's busy")
	check(not GameState.sleep() and not GameState.sleeping, "  ...or fall asleep")
	GameState.stop_activity()
	check(GameState.activity == "" and GameState.time_speed == 0.0, "an activity can be stopped early")

	_start_over(100.0, 50.0)
	GameState.sleep()
	check(not GameState.start_activity("Washing bowls", 60.0, 3.0), "she can't start something while she's asleep")

	_start_over(100.0, 2.0)
	var finished := []
	var on_finish := func(activity: String, completed: bool) -> void: finished.append([activity, completed])
	GameState.activity_finished.connect(on_finish)
	GameState.start_activity("Washing bowls", 60.0, 3.0)
	GameState.advance(40.0)
	GameState.activity_finished.disconnect(on_finish)
	check(GameState.passed_out and GameState.activity == "" and finished == [["Washing bowls", false]],
			"if she passes out, her activity is cut short")
	check(GameState.time_speed == GameState.sleep_time_speed, "  ...and time runs at sleeping speed, not working speed")


## Starts from a fresh game with the clock stopped and these needs.
func _start_over(hunger: float, energy: float) -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_needs(hunger, energy)
