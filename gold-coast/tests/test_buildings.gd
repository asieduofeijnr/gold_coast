extends TestCase
## Checks the neighborhood: every building is solid (walking into it stops the
## player), what you see matches what you bump into, and the billboard stands
## at the end of the row with solid posts you can walk between.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const PUSH_STEPS := 120 # walk into something for 2 seconds

var _player: Player


func run_tests() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	_player = main.get_node("Player")
	await wait_physics_frames(10)

	var buildings: Array[PlaceholderBuilding] = []
	for child in main.get_node("Buildings").get_children():
		if child is PlaceholderBuilding:
			buildings.append(child)
	check(buildings.size() == 5, "there are 5 buildings (found %d)" % buildings.size())

	for building in buildings:
		var seen := (building.walls.mesh as BoxMesh).size
		var solid := (building.collision.shape as BoxShape3D).size
		check(seen.is_equal_approx(solid) and solid.is_equal_approx(building.size),
				"%s: what you see matches what you bump into" % building.building_name)

		var front := building.global_position.z + building.size.z / 2.0
		var path := await _walk_from(Vector3(building.global_position.x, 0.05, front + 3.0))
		var closest := INF
		for point in path:
			closest = minf(closest, point.z - front)
		check(closest > 0.2 and closest < 0.6,
				"%s: walking into it stops the player at the wall (%.2f m away)" % [building.building_name, closest])

	var billboard := main.get_node_or_null("Billboard") as Billboard
	check(billboard != null, "there's a billboard")
	if billboard == null:
		main.queue_free()
		return

	var row_end := -INF
	for building in buildings:
		row_end = maxf(row_end, building.global_position.x + building.size.x / 2.0)
	check(billboard.global_position.x > row_end, "the billboard stands at the end of the row")

	var camera := main.get_node("IsoCamera") as Camera3D
	var to_camera := camera.global_position - billboard.global_position
	var facing := billboard.global_basis.z
	check(Vector2(facing.x, facing.z).dot(Vector2(to_camera.x, to_camera.z).normalized()) > 0.5,
			"the billboard faces the camera")

	for post in billboard.posts:
		var post_at := post.global_position
		var path := await _walk_from(Vector3(post_at.x, 0.05, post_at.z + 3.0))
		var nearest := INF
		for point in path:
			nearest = minf(nearest, Vector2(point.x - post_at.x, point.z - post_at.z).length())
		check(nearest > 0.4, "  ...its posts are solid (she got within %.2f m of the middle)" % nearest)

	var under := billboard.global_position
	var walk_under := await _walk_from(Vector3(under.x, 0.05, under.z + 3.0), 180)
	check(walk_under[-1].z < under.z - 1.5, "  ...and she can walk under it, between the posts")

	main.queue_free()


## Puts the player at `start`, holds W and D together (which walks straight
## toward -Z, the far side of the road) for `steps` physics steps, and returns
## every position she passed through.
func _walk_from(start: Vector3, steps: int = PUSH_STEPS) -> Array[Vector3]:
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await wait_physics_frames(5)
	var path: Array[Vector3] = []
	Input.action_press("move_forward")
	Input.action_press("move_right")
	for i in steps:
		await get_tree().physics_frame
		path.append(_player.global_position)
	Input.action_release("move_forward")
	Input.action_release("move_right")
	await wait_physics_frames(15) # let her stop before the next walk
	return path
