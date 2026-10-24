extends TestCase
## Checks that WASD moves the player the right way on screen, that the
## player stays on the ground, and that the camera keeps up.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const HOLD_STEPS := 60 # hold a key for 60 physics steps = 1 second
const SETTLE_STEPS := 30 # half a second to land, stop, and let the camera catch up

var _player: Player
var _camera: Camera3D


func run_tests() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	_player = main.get_node("Player")
	_camera = main.get_node("IsoCamera")

	await wait_physics_frames(SETTLE_STEPS)
	check(_is_standing(), "player starts standing on the ground")

	await _check_direction("move_forward", Vector2.UP, "W / Up walks up the screen")
	await _check_direction("move_back", Vector2.DOWN, "S / Down walks down the screen")
	await _check_direction("move_left", Vector2.LEFT, "A / Left walks left on screen")
	await _check_direction("move_right", Vector2.RIGHT, "D / Right walks right on screen")

	var off_center := _to_screen(_player.global_position + Vector3.UP - _camera.global_position)
	check(off_center.length() < 1.0, "camera keeps the player in the middle of the screen")

	main.queue_free()


func _check_direction(action: StringName, expected: Vector2, description: String) -> void:
	var start := _player.global_position
	Input.action_press(action)
	await wait_physics_frames(HOLD_STEPS)
	Input.action_release(action)
	await wait_physics_frames(SETTLE_STEPS)
	var moved := _player.global_position - start

	var distance := Vector2(moved.x, moved.z).length()
	var on_screen := _to_screen(moved).normalized()
	check(distance > _player.walk_speed * 0.6 and on_screen.dot(expected) > 0.98,
			"%s (walked %.1f m)" % [description, distance])
	check(_is_standing(), "  ...and is still standing on the ground")
	check(Vector2(_player.velocity.x, _player.velocity.z).length() < 0.01,
			"  ...and stops after letting go")


## How a movement in the world looks on screen. Screen x points right and
## screen y points down. (For an orthographic camera this is exact.)
func _to_screen(world_offset: Vector3) -> Vector2:
	var basis := _camera.global_basis
	return Vector2(world_offset.dot(basis.x), -world_offset.dot(basis.y))


func _is_standing() -> bool:
	return _player.is_on_floor() and absf(_player.global_position.y) < 0.05
