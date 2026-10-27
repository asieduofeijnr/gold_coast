extends TestCase
## Checks Sankofa Training College: E at the registrar's desk opens the board of
## courses (and pauses the game), enrolling pays the fees by mobile money (or
## fails cleanly), going to a class takes her inside for two game hours, it's
## one class a day, and after a course's last class the phone shows her
## certificate. The college is closed at night and on Sundays.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _main: Node
var _player: Player
var _college: TrainingCollege
var _phone: Phone


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_time(1, 9 * 60.0) # Monday morning
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_college = _main.get_node("College")
	_phone = _main.get_node("HUD/Phone")
	await wait_physics_frames(10)
	var board := _college.board
	var model := _player.get_node("Model") as PlayerModel

	await _press_at_desk()
	check(board.is_open() and get_tree().paused and board.courses.size() == 3,
			"E at the registrar's desk opens the board of %d courses, and the game pauses" % board.courses.size())
	check(board.line.begins_with("Welcome to Sankofa"), "  ...and Madam Afriyie welcomes her: \"%s\"" % board.line)

	board.selected = _row("teaching")
	await press_action("ui_accept")
	var text := _phone.shown_sms()
	check(not GameState.is_enrolled("teaching") and GameState.money == 10000 and not text.is_empty()
			and text[0] == "PAYMENT FAILED" and board.is_open(),
			"with too little money for the teaching fees (GH₵350.00), enrolling fails: %s" % " / ".join(text))

	board.selected = _row("momo_agent")
	await press_action("ui_accept")
	text = _phone.shown_sms()
	check(GameState.is_enrolled("momo_agent") and GameState.money == 2000
			and text == PackedStringArray(["PAYMENT SENT", "GH₵80.00", "TO COLLEGE", "BAL GH₵20.00"]),
			"enrolling to be a mobile money agent pays GH₵80.00 by mobile money: %s" % " / ".join(text))

	await press_action("ui_accept")
	check(not board.is_open() and not get_tree().paused, "choosing it again sends her to its class (the board closes)")
	var in_class: bool = await wait_until(func() -> bool: return GameState.activity.begins_with("In class"), 10.0)
	var clock := GameState.now()
	await wait_physics_frames(30)
	check(in_class and _player.indoors and model.faded() > 0.9 and model.shown_activity() == "In class: Mobile Money Agent",
			"  ...she goes inside, out of sight, with \"%s\" over the door" % model.shown_activity())
	var over: bool = await wait_until(func() -> bool: return GameState.activity == "", 12.0)
	text = _phone.shown_sms()
	check(over and absf(GameState.now() - clock - TrainingCollege.CLASS_MINUTES) < 2.0 and GameState.has_skill("momo_agent"),
			"the class takes two game hours, and as it's a one-class course, she has the certificate")
	check(text == PackedStringArray(["CERTIFICATE!", "MOMO AGENT", "SANKOFA", "COLLEGE"]),
			"  ...the phone says so: %s" % " / ".join(text))
	await wait_physics_frames(40)
	check(not _player.indoors and model.faded() < 0.1, "  ...and she comes back out")

	# Dressmaking takes two classes, one a day.
	GameState.money = 30000
	await _press_at_desk()
	board.selected = _row("dressmaking")
	await press_action("ui_accept")
	await press_action("ui_accept")
	await wait_until(func() -> bool: return GameState.activity.begins_with("In class"), 10.0)
	await wait_until(func() -> bool: return GameState.activity == "", 12.0)
	check(GameState.classes_done("dressmaking") == 1 and not GameState.has_skill("dressmaking"),
			"after her first dressmaking class she's done 1 of 2")
	await wait_physics_frames(40)
	await _press_at_desk()
	board.selected = _row("dressmaking")
	await press_action("ui_accept")
	check(board.is_open() and "tomorrow" in board.line and GameState.activity == "",
			"  ...a second one the same day isn't allowed: \"%s\"" % board.line)
	await press_action("ui_cancel")

	GameState.set_time(2, 7 * 60.0 + 30.0)
	await _press_at_desk()
	board.selected = _row("dressmaking")
	await press_action("ui_accept")
	check(board.is_open() and "eight" in board.line and GameState.activity == "",
			"classes don't start before 08:00: \"%s\"" % board.line)
	await press_action("ui_cancel")
	GameState.set_time(2, 9 * 60.0)
	await _press_at_desk()
	board.selected = _row("dressmaking")
	await press_action("ui_accept")
	await wait_until(func() -> bool: return GameState.activity.begins_with("In class"), 10.0)
	await wait_until(func() -> bool: return GameState.activity == "", 12.0)
	check(GameState.has_skill("dressmaking"), "the next day's class finishes the dressmaking certificate")
	await wait_physics_frames(40)

	GameState.set_time(2, 20 * 60.0)
	await wait_physics_frames(2)
	check(not _college.registrar.is_here() and not _college.desk_spot.enabled,
			"at night Madam Afriyie has gone home, and the college is closed")
	GameState.set_time(7, 10 * 60.0)
	await wait_physics_frames(2)
	check(not _college.registrar.is_here() and not _college.desk_spot.enabled, "  ...and on Sundays")
	GameState.set_time(3, 10 * 60.0)
	await wait_physics_frames(2)
	check(_college.registrar.is_here() and _college.desk_spot.enabled, "  ...she's back on a weekday morning")

	get_tree().paused = false
	_main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _press_at_desk() -> void:
	teleport(_player, _college.desk_spot.global_position + Vector3(0, 0.05, 0.3))
	await wait_physics_frames(3)
	await press_action("interact")


# The board's row for the course with this id.
func _row(course_id: String) -> int:
	for i in _college.courses.size():
		if _college.courses[i].id == course_id:
			return i
	return -1
