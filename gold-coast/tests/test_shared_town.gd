extends TestCase
## Checks the shared Gold Coast, against a pretend server (FakeBackend), with
## a test playing the other players:
## - offline, there's no town: she doesn't join it or tell it anything
## - logged in, she joins the town, and tells it where she is about 10 times a
##   second (her spot, which way she faces, how fast she walks, her pose)
## - another player shows up where their game says, in their own colors, with
##   their @username over their head and no star pin; they walk smoothly to where they go next,
##   facing their way, sit when they sit, and jump straight to a far-off spot
## - when they leave, they're gone; a new game still shows who's in town
## - everyone in town has the town's time of day: her clock moves on to it
##   when she joins, and is put right when it drifts. There, sleeping is a
##   quick rest and activities don't move the clock on.
## - logging out leaves the town (her own clock again); with no server, the
##   game carries on

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const AMA := {"email": "ama@example.com", "password": "kenkey-and-fish"}

var _fake: FakeBackend
var _main: Node
var _town: TownPlayers
var _player: Player


func run_tests() -> void:
	_fake = FakeBackend.new()
	_fake.accounts[AMA.email] = {"password": AMA.password, "username": "ama_osu", "display_name": "Ama Mensah"}
	Online.backend = _fake
	GameState.reset()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await wait_physics_frames(10)
	_town = _main.get_node("TownPlayers")
	_player = _main.get_node("Player")
	await _check_joining()
	await _check_clock()
	await _check_someone_else()
	await _check_leaving()
	_main.queue_free()
	await get_tree().process_frame
	# Back to how the test runner set things up.
	Online.backend = FakeBackend.new()
	Online.log_out()
	Online.play_offline()
	GameState.reset()


func _check_joining() -> void:
	await wait_physics_frames(30)
	check(not Online.in_town and not _fake.calls.has("join_town") and _fake.moves.is_empty(),
			"offline, there's no shared town: she doesn't join it or tell it anything")
	await Online.log_in(AMA.email, AMA.password)
	await wait_physics_frames(2)
	check(Online.in_town and _fake.calls.has("join_town"), "logged in, she joins the shared town")
	var before := _fake.moves.size()
	await wait_physics_frames(60) # a second
	var in_a_second := _fake.moves.size() - before
	var last: Dictionary = _fake.moves.back() if not _fake.moves.is_empty() else {}
	var spot := _player.global_position
	check(in_a_second >= 8 and in_a_second <= 12 and absf(float(last.get("x", INF)) - spot.x) < 0.02
			and absf(float(last.get("z", INF)) - spot.z) < 0.02 and last.has("f") and last.has("s") and last.has("p"),
			"  ...and tells it where she is, about 10 times a second (%d in a second): %s" % [in_a_second, last])


func _check_clock() -> void:
	GameState.set_time(2, 14 * 60.0)
	_fake.tell_time(3 * 60.0) # the town says 03:00
	await wait_physics_frames(3)
	check(GameState.shared_clock and GameState.day == 3 and absf(GameState.minutes - 180.0) < 0.5,
			"in the town, her clock follows the town's: at 14:00 when the town says 03:00, it's 03:00 the next day")
	var hers := GameState.minutes
	_fake.tell_time(hers + 5.0) # her clock has fallen 5 minutes behind (say, a menu was open)
	await wait_physics_frames(3)
	var caught_up := absf(GameState.minutes - (hers + 5.0)) < 0.5
	hers = GameState.minutes
	_fake.tell_time(hers - 3.0) # and now 3 minutes ahead
	await wait_physics_frames(3)
	check(caught_up and absf(GameState.minutes - (hers - 3.0)) < 0.5, "  ...and is put right when it drifts, either way")
	GameState.set_needs(80.0, 20.0)
	var slept := GameState.sleep()
	var speed := GameState.time_speed
	var fell_asleep_at := GameState.now()
	await wait_until(func() -> bool: return not GameState.sleeping, 15.0)
	var night := GameState.now() - fell_asleep_at
	check(slept and speed == 1.0 and not GameState.sleeping and GameState.energy >= 99.0 and night < 15.0,
			"there, sleeping is a quick rest: rested in seconds, and the night doesn't pass (%.0f game minutes)" % night)
	var lesson_at := GameState.now()
	GameState.start_activity("Teaching a lesson", 60.0, 5.0)
	speed = GameState.time_speed
	await wait_until(func() -> bool: return GameState.activity == "", 8.0)
	var lesson := GameState.now() - lesson_at
	check(speed == 1.0 and GameState.activity == "" and lesson < 8.0,
			"  ...and a lesson takes its few seconds without moving the clock on (%.0f game minutes, not 60)" % lesson)


func _check_someone_else() -> void:
	_fake.someone_moved("kofi-1", "kofi_ab", _move(2.0, 9.0, 1.5, 0.0, ""))
	await wait_physics_frames(2)
	var kofi: RemotePlayer = _town.players().get("kofi-1")
	check(_town.players().size() == 1 and kofi != null and kofi.position.distance_to(Vector3(2.0, 0.0, 9.0)) < 0.01
			and kofi.name_shown() == "@kofi_ab" and not kofi.get_model().is_marked(),
			"another player appears where their game says, with @kofi_ab over their head (and no star pin)")
	var outfit := RemotePlayer.outfit_for("kofi_ab")
	var top := Palette.color(outfit.cloth_cream)
	var body := kofi.get_model().find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var colors: PackedColorArray = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var wearing := Array(colors).any(func(color: Color) -> bool: return color.is_equal_approx(top))
	var plain := Palette.color(Palette.ColorName.CLOTH_CREAM)
	check(wearing and outfit == RemotePlayer.outfit_for("kofi_ab") and not top.is_equal_approx(plain),
			"  ...in their own colors, the same every time, and not her cream top")
	_fake.someone_moved("kofi-1", "kofi_ab", _move(4.0, 9.0, 1.57, 1.8, ""))
	await wait_physics_frames(6) # a tenth of a second
	var along := kofi.position.x - 2.0
	await wait_physics_frames(60)
	check(along > 0.05 and along < 1.9 and absf(kofi.position.x - 4.0) < 0.05
			and absf(angle_difference(kofi.rotation.y, 1.57)) < 0.05
			and kofi.get_model().animation_player.current_animation == "walk",
			"  ...walks smoothly to where they go next (%.2f m of 2 after a tenth of a second), facing their way" % along)
	_fake.someone_moved("kofi-1", "kofi_ab", _move(4.0, 9.0, 1.57, 0.0, "sit"))
	await wait_physics_frames(30)
	check(kofi.get_model().animation_player.current_animation == "sit", "  ...and sits when they sit")
	_fake.someone_moved("kofi-1", "kofi_ab", _move(30.0, -2.0, 0.0, 0.0, ""))
	await wait_physics_frames(1)
	check(kofi.position.distance_to(Vector3(30.0, 0.0, -2.0)) < 0.01,
			"  ...and far away (like after loading a game), they're put straight there")


func _check_leaving() -> void:
	var kofi: RemotePlayer = _town.players().get("kofi-1")
	_fake.someone_left("kofi-1")
	await wait_physics_frames(2)
	check(_town.players().is_empty() and not is_instance_valid(kofi), "when they leave the town, they're gone")
	_fake.someone_moved("esi-2", "esi_k", _move(6.0, 8.0, 0.0, 0.0, ""))
	var again := TownPlayers.new()
	again.player = _player
	_main.add_child(again)
	await wait_physics_frames(2)
	check(again.players().has("esi-2"), "a new game (the scene starting again) still shows whoever's in town")
	again.queue_free()
	Online.log_out()
	await wait_physics_frames(2)
	check(not Online.in_town and _fake.calls.has("leave_town") and _town.players().is_empty(),
			"logging out leaves the town, and the other players go")
	GameState.set_needs(80.0, 20.0)
	GameState.sleep()
	var speed := GameState.time_speed
	GameState.set_needs(80.0, 100.0)
	GameState.wake_up()
	check(not GameState.shared_clock and speed == GameState.sleep_time_speed,
			"  ...and her clock is her own again: sleeping makes the night go by fast")
	await Online.log_in(AMA.email, AMA.password)
	Online.leave_town()
	_fake.reachable = false
	await Online.join_town()
	check(Online.is_logged_in() and not Online.in_town, "with no server, she isn't in the town, and the game carries on")
	_fake.reachable = true


func _move(x: float, z: float, facing: float, speed: float, pose: String) -> Dictionary:
	return {"x": x, "y": 0.0, "z": z, "f": facing, "s": speed, "p": pose, "sl": false, "in": false}
