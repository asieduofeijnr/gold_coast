extends TestCase
## Checks the "press E" interaction system: the sign over something she can use
## shows only when she's close, E uses the nearest thing in reach, and clicking
## (or pointing at) a building works too.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _main: Node
var _player: Player
var _camera: Camera3D


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_camera = _main.get_node("IsoCamera")
	await wait_physics_frames(10)

	await _check_signs()
	await _check_nearest()
	await _check_clicking()

	get_tree().paused = false
	_main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _check_signs() -> void:
	var counter := _main.get_node("ChopBarShop/Counter") as Interactable
	check(_player.focus == null and not counter.is_sign_showing(),
			"far from everything, no sign shows and E has nothing to use")
	teleport(_player, counter.global_position + Vector3(0, 0.05, 1.0))
	await wait_physics_frames(3)
	check(_player.focus == counter and counter.is_sign_showing(), "walking up to the Chop Bar's counter shows its sign")
	check(counter.get_sign().text == "Buy food", "  ...which says what E does there: %s" % counter.get_sign().text)
	teleport(_player, counter.global_position + Vector3(0, 0.05, counter.reach + 1.0))
	await wait_physics_frames(3)
	check(_player.focus == null and not counter.is_sign_showing(), "walking away hides it again")


func _check_nearest() -> void:
	var used := []
	var near := Interactable.new()
	near.prompt = "Near"
	var far := Interactable.new()
	far.prompt = "Far"
	_main.add_child(near)
	_main.add_child(far)
	near.global_position = Vector3(10.0, 0.0, 8.0)
	far.global_position = Vector3(11.5, 0.0, 8.0)
	near.used.connect(func(_user: Node3D) -> void: used.append("near"))
	far.used.connect(func(_user: Node3D) -> void: used.append("far"))

	teleport(_player, Vector3(10.4, 0.05, 8.5)) # both are in reach, but one is closer
	await wait_physics_frames(3)
	check(_player.focus == near and near.is_sign_showing() and not far.is_sign_showing(),
			"with two things in reach, only the nearest shows its sign")
	await press_action("interact")
	check(used == ["near"], "  ...and E uses the nearest one")

	teleport(_player, Vector3(16.0, 0.05, 8.0))
	await wait_physics_frames(3)
	await press_action("interact")
	check(used == ["near"], "E does nothing when nothing is in reach")
	near.queue_free()
	far.queue_free()


func _check_clicking() -> void:
	var shop := _main.get_node("ChopBarShop") as ChopBarShop
	var box := (_main.get_node("Buildings/ChopBar") as Building).bounds()
	teleport(_player, Vector3(-3.0, 0.05, 2.0))
	await wait_physics_frames(40) # let the camera catch up with her
	var roof := _camera.unproject_position(Vector3(box.get_center().x, box.end.y - 0.5, box.get_center().z))

	_player.point_at(roof)
	check(_player.hovered == shop.counter and shop.counter.is_sign_showing() and shop.counter.get_sign().with_mouse,
			"pointing at the Chop Bar shows its counter's sign, with a mouse instead of the E key")
	var stall := _camera.unproject_position(shop.get_node("FoodCounter").global_position + Vector3(0, 0.5, 0))
	check(_player.interactable_at(stall) == shop.counter, "  ...and so does pointing at Maame Esi's food stall")
	_player.point_at(_camera.unproject_position(Vector3(0.0, 0.0, 6.0)))
	check(_player.hovered == null, "pointing at bare ground points at nothing")

	await click_at(roof)
	check(_player.has_destination and not shop.board.is_open(), "clicking the Chop Bar sends her walking to its counter")
	var opened: bool = await wait_until(func() -> bool: return shop.board.is_open(), 10.0)
	var gap := Vector2(_player.global_position.x - shop.counter.global_position.x,
			_player.global_position.z - shop.counter.global_position.z).length()
	check(opened and gap <= shop.counter.reach, "  ...and when she gets there, she uses it: the menu opens (%.1f m away)" % gap)
	shop.board.close()
	await get_tree().process_frame
