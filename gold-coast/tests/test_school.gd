extends TestCase
## Checks teaching at Nkabom M/A Basic School: without a teaching certificate the
## headmistress sends her to the training college; with one she teaches at the
## blackboard, with pupils on the benches, and each lesson pays GH₵50 by mobile
## money, up to three a day, on school days from 08:00. On Saturdays the
## school is closed. The mango tree in the yard doesn't hide the school's sign.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _player: Player
var _school: School


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_time(1, 9 * 60.0) # Monday morning
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	_player = main.get_node("Player")
	_school = main.get_node("School")
	var phone := main.get_node("HUD/Phone") as Phone
	var model := _player.get_node("Model") as PlayerModel
	var lesson := _school.lesson
	await wait_physics_frames(10)
	_check_sign_in_view(main)

	await _press_at_blackboard()
	check(lesson.prompt.begins_with("Teach a lesson (needs") and "Sankofa" in _school.headmistress.saying()
			and GameState.activity == "",
			"without a teaching certificate, Mrs. Ofori sends her to the training college: \"%s\""
			% _school.headmistress.saying())

	GameState.skills.append("teaching")
	lesson.refresh()
	check(lesson.prompt == "Teach a lesson  +GH₵50.00", "with a certificate, the sign offers a lesson: %s" % lesson.prompt)
	var money := GameState.money
	await _press_at_blackboard()
	var teaching: bool = await wait_until(func() -> bool: return GameState.activity == "Teaching a lesson", 6.0)
	await wait_physics_frames(40)
	var seated := _school.pupils.filter(func(pupil: Townsperson) -> bool:
		return pupil.visible and pupil.current_animation() == &"sit").size()
	check(teaching and model.animation_player.current_animation == "teach" and seated == 8,
			"she teaches at the blackboard, with %d pupils sitting on the benches" % seated)
	var greeted: bool = await wait_until(func() -> bool:
		return _school.pupils.any(func(pupil: Townsperson) -> bool: return "mor-ning" in pupil.saying()), 3.0)
	check(greeted, "  ...who greet her: \"Gooood mor-ning, Ma-dam!\"")
	var over: bool = await wait_until(func() -> bool: return GameState.activity == "", 10.0)
	var text := phone.shown_sms()
	check(over and GameState.money == money + 5000 and text.size() == 4 and text[0] == "RECEIVED" and text[2] == "FROM SCHOOL",
			"the lesson takes a game hour and pays GH₵50.00 by mobile money: %s" % " / ".join(text))
	await wait_physics_frames(150)
	var still_sitting := _school.pupils.filter(func(pupil: Townsperson) -> bool:
		return pupil.visible and pupil.current_animation() == &"sit").size()
	check(still_sitting == 0, "  ...then the pupils get up and run off to play")

	for i in 2:
		await _press_at_blackboard()
		await wait_until(func() -> bool: return GameState.activity == "Teaching a lesson", 6.0)
		await wait_until(func() -> bool: return GameState.activity == "", 10.0)
		await wait_physics_frames(30)
	check(GameState.jobs_done_today("teaching") == 3 and GameState.money == money + 15000
			and lesson.prompt == "No more work today", "she can teach three lessons a day (GH₵150.00)")
	await _press_at_blackboard()
	check(GameState.activity == "" and "all the classes" in _school.headmistress.saying(),
			"  ...after that: \"%s\"" % _school.headmistress.saying())

	GameState.set_time(2, 7 * 60.0 + 30.0)
	await wait_physics_frames(2)
	check(lesson.prompt.begins_with("Lessons") and _school.headmistress.is_here(),
			"before 08:00 the headmistress is in, but lessons haven't started: %s" % lesson.prompt)
	GameState.set_time(6, 10 * 60.0)
	await wait_physics_frames(2)
	check(not _school.headmistress.is_here() and not lesson.enabled, "on Saturday the school is closed")

	main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _press_at_blackboard() -> void:
	var spot := _school.lesson.global_position
	teleport(_player, spot + Vector3(0.6, 0.05, 0.0))
	await wait_physics_frames(3)
	await press_action("interact")


# From the game camera, the school's sign can be read: lines from all over its
# front toward the camera don't run into the mango tree (or anything else).
func _check_sign_in_view(main: Node) -> void:
	var board := _school.get_node("SchoolSign") as Signboard
	var toward_camera := (main.get_node("IsoCamera") as Camera3D).global_basis.z
	var space := board.get_world_3d().direct_space_state
	var middle := board.post_height + board.board_size.y / 2.0
	var hidden := []
	for along in [-0.45, -0.25, 0.0, 0.25, 0.45]:
		for up in [-0.3, 0.0, 0.3]:
			var spot := board.to_global(Vector3(along * board.board_size.x, middle + up * board.board_size.y, 0.05))
			var line := PhysicsRayQueryParameters3D.create(spot, spot + toward_camera * 40.0, SeeThrough.SIGHT_LAYERS)
			var hit := space.intersect_ray(line)
			if not hit.is_empty():
				hidden.append(hit.collider)
	check(hidden.is_empty(), "the mango tree doesn't hide the school's sign from the camera (%d of 15 lines blocked)"
			% hidden.size())
