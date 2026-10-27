extends TestCase
## Checks the player's 3D character: she's the right size, faces the way she
## walks, and switches between her standing and walking animations. A gold pin
## with a black star floats over her head (and nobody else's), except while
## she's indoors.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	var player: Player = main.get_node("Player")
	var model := player.get_node("Model") as PlayerModel
	check(model != null, "the player uses the real character, not the capsule")
	if model == null:
		main.queue_free()
		return

	var mesh := model.find_child("Body") as MeshInstance3D
	var height := mesh.get_aabb().size.y
	check(height > 1.6 and height < 1.9, "she's about 1.7 m tall (%.2f m with her headwrap)" % height)

	# Her toes point along her foot bone, so they show which way she faces.
	var skeleton := model.find_child("Skeleton3D") as Skeleton3D
	var foot_pose := skeleton.get_bone_global_pose(skeleton.find_bone("LeftFoot"))
	var toes := skeleton.global_basis * foot_pose.basis.y
	var forward := -player.global_basis.z
	check(Vector2(toes.x, toes.z).normalized().dot(Vector2(forward.x, forward.z)) > 0.9,
			"she faces the way she walks")

	await wait_physics_frames(30)
	check(model.animation_player.current_animation == "idle", "she plays her idle animation when standing still")

	Input.action_press("move_forward")
	await wait_physics_frames(30)
	check(model.animation_player.current_animation == "walk", "she plays her walk animation when moving")
	var expected_scale := player.walk_speed / model.walk_animation_speed
	check(absf(model.animation_player.speed_scale - expected_scale) < 0.1,
			"  ...at a speed that matches her steps (x%.2f)" % model.animation_player.speed_scale)
	Input.action_release("move_forward")

	await wait_physics_frames(30)
	check(model.animation_player.current_animation == "idle", "she goes back to idle after stopping")

	# The pin over her head.
	var marker := model.get_marker()
	var camera := main.get_node("IsoCamera") as Camera3D
	var head := camera.unproject_position(player.global_position + Vector3.UP * 1.8)
	check(model.is_marked() and marker.position.y < head.y and absf(marker.position.x - head.x) < 4.0,
			"a gold pin with a black star floats over her head, so you can always pick her out")
	var pins := _pins_in(main)
	check(pins == 1, "  ...and nobody else has one (found %d)" % pins)
	player.indoors = true
	await wait_physics_frames(30)
	check(not model.is_marked(), "  ...it hides while she's indoors")
	player.indoors = false
	await wait_physics_frames(30)
	check(model.is_marked(), "  ...and comes back when she comes out")

	main.queue_free()


# How many player pins there are in `node`, counting parts scripts made.
func _pins_in(node: Node) -> int:
	var count := 1 if node is PlayerMarker else 0
	for child in node.get_children(true):
		count += _pins_in(child)
	return count
