extends TestCase
## Checks click-to-move: clicking the ground walks her there, a marker shows
## where you clicked, she finds her way around buildings, and pressing a
## movement key takes over from a click.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _player: Player
var _camera: Camera3D


func run_tests() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	_player = main.get_node("Player")
	_camera = main.get_node("IsoCamera")
	await wait_physics_frames(10) # let the walkable area settle in

	# A click on open ground near her.
	var spot := Vector3(4.0, 0.0, 7.0)
	await _click(spot)
	check(_player.has_destination, "clicking the ground sets her off toward that spot")
	var marker := main.get_node("MoveMarker") as Node3D
	var marker_gap := Vector2(marker.global_position.x - spot.x, marker.global_position.z - spot.z).length()
	check(marker.visible and marker_gap < 0.05, "  ...a marker appears where you clicked")
	check(await _arrives(spot, 6.0), "  ...and she gets there")

	# A spot behind the Chop Bar: she has to walk around it.
	var box := (main.get_node("Buildings/ChopBar") as Building).bounds()
	teleport(_player, Vector3(box.get_center().x, 0.05, -5.0))
	var behind := Vector3(box.get_center().x, 0.0, box.position.z - 2.0)
	_player.walk_to(behind)
	check(await _arrives(behind, 25.0), "she finds her way around a building to a spot behind it")

	# The keys take over from a click.
	_player.walk_to(Vector3(-10.0, 0.0, 10.0))
	await wait_physics_frames(20)
	Input.action_press("move_forward")
	await wait_physics_frames(5)
	Input.action_release("move_forward")
	check(not _player.has_destination, "pressing a movement key cancels the click")

	main.queue_free()


## Clicks the left mouse button on the screen where `point` on the ground shows.
func _click(point: Vector3) -> void:
	await click_at(_camera.unproject_position(point))


## Waits up to `seconds` for her to reach `point`. Returns whether she did.
func _arrives(point: Vector3, seconds: float) -> bool:
	for i in int(seconds * 60.0):
		await get_tree().physics_frame
		if Vector2(_player.global_position.x - point.x, _player.global_position.z - point.z).length() < 0.45:
			return true
	return false
