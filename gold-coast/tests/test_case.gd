class_name TestCase
extends Node
## Base class for test files. Each test file extends this, overrides
## run_tests(), and calls check() for every thing it wants to verify.

var failures := 0


## Override this in each test file.
func run_tests() -> void:
	await get_tree().process_frame


## Records one check and prints PASS or FAIL.
func check(passed: bool, description: String) -> void:
	if passed:
		print("  PASS  ", description)
	else:
		failures += 1
		print("  FAIL  ", description)


## Waits for a number of physics steps (60 steps = 1 second of game time).
func wait_physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Presses and releases an Input Map action, as if its key were pressed.
func press_action(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
		await get_tree().process_frame


## Moves a character somewhere instantly, standing still.
func teleport(body: CharacterBody3D, to: Vector3) -> void:
	body.global_position = to
	body.velocity = Vector3.ZERO
	body.reset_physics_interpolation()


## Waits until `condition` (a function that returns true or false) comes true,
## for up to `seconds` (60 physics steps a second). Returns whether it did.
func wait_until(condition: Callable, seconds: float) -> bool:
	for i in int(seconds * 60.0):
		if condition.call():
			return true
		await get_tree().physics_frame
	return condition.call()


## Clicks the left mouse button at `screen_position`. The click is given in game
## coordinates (push_input's `true`), because in the hidden test window Godot
## would otherwise convert it from a 0 x 0 window.
func click_at(screen_position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = screen_position
		get_viewport().push_input(event, true)
		await get_tree().process_frame
		await get_tree().process_frame


## Moves the mouse pointer to `screen_position`, in game coordinates like click_at().
func move_mouse_to(screen_position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = screen_position
	get_viewport().push_input(event, true)
	await get_tree().process_frame
