extends TestCase
## Checks looking around: the view slides when the mouse is at the window's
## edge (and stays on the map), zooming works within its limits, and walking or
## pressing Space brings the camera back to the player.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	var view := Vector2(1152, 648)
	check(IsoCamera.edge_direction(Vector2(5, 300), view, 24) == Vector2.LEFT, "mouse at the left edge slides left")
	check(IsoCamera.edge_direction(Vector2(1150, 300), view, 24) == Vector2.RIGHT, "  ...at the right edge, right")
	check(IsoCamera.edge_direction(Vector2(600, 2), view, 24) == Vector2.UP, "  ...at the top edge, up")
	check(IsoCamera.edge_direction(Vector2(600, 640), view, 24) == Vector2.DOWN, "  ...at the bottom edge, down")
	check(IsoCamera.edge_direction(Vector2(1150, 640), view, 24).is_equal_approx(Vector2.ONE.normalized()),
			"  ...in a corner, diagonally")
	check(IsoCamera.edge_direction(Vector2(600, 300), view, 24) == Vector2.ZERO, "  ...and in the middle, not at all")

	var main := MAIN_SCENE.instantiate()
	add_child(main)
	var camera := main.get_node("IsoCamera") as IsoCamera
	var player := main.get_node("Player") as Player
	await wait_physics_frames(10)

	var start := camera.focus
	camera.pan(Vector2.RIGHT, 1.0)
	var screen_right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	check(not camera.following and (camera.focus - start).normalized().dot(screen_right) > 0.99,
			"sliding right moves the view right, and the camera stops following")
	camera.pan(Vector2.RIGHT, 1000.0)
	check(absf(camera.focus.x) <= camera.pan_limit + 0.01 and absf(camera.focus.z) <= camera.pan_limit + 0.01,
			"  ...but never off the map")

	Input.action_press("move_forward")
	await wait_physics_frames(10)
	Input.action_release("move_forward")
	check(camera.following, "walking with WASD brings the camera back")
	await wait_physics_frames(90)
	var off_center := player.global_position + camera.target_offset - camera.focus
	check(Vector2(off_center.x, off_center.z).length() < 1.0, "  ...to the player")

	camera.pan(Vector2.LEFT, 0.5)
	await press_action("recenter_camera")
	check(camera.following, "pressing Space brings the camera back too")

	var normal_zoom := camera.target_size
	await _scroll_wheel(MOUSE_BUTTON_WHEEL_UP)
	check(camera.target_size < normal_zoom, "the mouse wheel zooms in")
	await _scroll_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	await _scroll_wheel(MOUSE_BUTTON_WHEEL_DOWN)
	check(camera.target_size > normal_zoom, "  ...and out")
	for i in 40:
		camera.zoom(1.0)
	check(is_equal_approx(camera.target_size, camera.max_size), "  ...as far as the furthest zoom")
	for i in 40:
		camera.zoom(-1.0)
	check(is_equal_approx(camera.target_size, camera.min_size), "  ...and as close as the closest zoom")
	await wait_physics_frames(90)
	check(absf(camera.size - camera.min_size) < 0.5, "  ...and the view eases to the zoom you asked for")

	main.queue_free()


## One click of the mouse wheel.
func _scroll_wheel(button: MouseButton) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
		await get_tree().process_frame
