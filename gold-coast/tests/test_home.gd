extends TestCase
## Checks home and sleep: E at her compound house door puts her to bed when
## she's even a little tired (the street needs her properly tired), she goes
## inside with "Z z z" over the door, her bed rests her faster, and she comes
## back out when she wakes. Clicking the house walks her home to bed. Outside,
## mosquitoes wake her up.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _main: Node
var _player: Player
var _model: PlayerModel
var _home: Home
var _phone: Phone


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_model = _player.get_node("Model")
	_home = _main.get_node("Home")
	_phone = _main.get_node("HUD/Phone")
	await wait_physics_frames(10)

	await _check_bed()
	await _check_clicking_home()
	await _check_mosquitoes()

	_main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _check_bed() -> void:
	var door := _home.door
	GameState.set_needs(80.0, 100.0)
	teleport(_player, door.global_position + Vector3(0, 0.05, 0.5))
	await wait_physics_frames(3)
	check(_player.focus == door and door.get_sign().text == "Home (not sleepy yet)",
			"at her door when she's wide awake, the sign says she isn't sleepy")
	await press_action("interact")
	check(not GameState.sleeping and _phone.shown_title() == "NOT SLEEPY", "  ...and E there just says NOT SLEEPY")

	GameState.set_needs(80.0, 95.0)
	await wait_physics_frames(3)
	await press_action("sleep")
	check(not GameState.sleeping and door.get_sign().text == "Go to bed",
			"a little tired, she can't sleep on the street with Z, but her door says Go to bed")

	GameState.set_needs(80.0, 60.0)
	await press_action("interact")
	var in_bed: bool = await wait_until(func() -> bool: return GameState.in_bed, 4.0)
	await wait_physics_frames(40)
	check(in_bed and GameState.sleeping and _model.faded() > 0.99 and _home.is_snoring(),
			"E at the door puts her to bed: she goes inside, and Z z z floats over the door")
	check(_phone.screen_title == "SWEET DREAMS", "  ...and the phone says SWEET DREAMS")
	var energy := GameState.energy
	var since := GameState.now()
	await wait_physics_frames(20)
	var rate := (GameState.energy - energy) / ((GameState.now() - since) / 60.0)
	check(absf(rate - GameState.bed_energy_per_hour) < 0.5, "  ...where she rests at %.1f energy an hour" % rate)
	var woke: bool = await wait_until(func() -> bool: return not GameState.sleeping, 6.0)
	await wait_physics_frames(40)
	check(woke and GameState.energy == GameState.FULL and _model.faded() < 0.01 and not _home.is_snoring() and _player.is_free(),
			"rested, she wakes up and comes back out")


func _check_clicking_home() -> void:
	GameState.set_needs(80.0, 50.0)
	teleport(_player, Vector3(-20.0, 0.05, 1.0))
	await wait_physics_frames(40) # let the camera catch up with her
	var camera := _main.get_node("IsoCamera") as Camera3D
	var box := (_main.get_node("Buildings/CompoundHouse") as Building).bounds()
	await click_at(camera.unproject_position(Vector3(box.get_center().x, box.end.y - 0.4, box.get_center().z)))
	var asleep: bool = await wait_until(func() -> bool: return GameState.in_bed, 10.0)
	check(asleep, "clicking her house walks her home and puts her to bed")
	GameState.set_needs(80.0, 100.0) # she's rested now
	await wait_until(func() -> bool: return _player.is_free(), 3.0)


func _check_mosquitoes() -> void:
	GameState.set_needs(80.0, 10.0)
	teleport(_player, Vector3(0.0, 0.05, 8.0))
	await wait_physics_frames(3)
	await press_action("sleep")
	var asleep_outside := GameState.sleeping and not GameState.in_bed
	var bitten: bool = await wait_until(func() -> bool: return not GameState.sleeping, 8.0)
	var text := _phone.shown_sms()
	check(asleep_outside and bitten and text.size() > 0 and text[0] == "MOSQUITOES!",
			"sleeping on the street, mosquitoes wake her after 4 hours, and the phone says so: %s" % " / ".join(text))
	check(GameState.energy < GameState.FULL, "  ...before she's fully rested (energy %.0f)" % GameState.energy)
