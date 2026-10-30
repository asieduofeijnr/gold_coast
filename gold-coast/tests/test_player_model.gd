extends TestCase
## Checks the player's 3D character: she's the right size, faces the way she
## walks, and switches between her standing and walking animations. A gold pin
## with a black star floats over her head (and nobody else's), except while
## she's indoors. When she sits, her slit still covers her legs.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const CHARACTER := preload("res://art/models/characters/player_character.glb")


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
	await _check_slit_when_sitting()


# Sitting, the bottom of her slit goes round her ankles, so it covers her legs
# down to her feet. (When her hips kept a share of it, it stayed behind under
# the stool, and her legs came out of it.)
func _check_slit_when_sitting() -> void:
	var character := CHARACTER.instantiate() as Node3D
	add_child(character)
	var skeleton := character.find_child("Skeleton3D") as Skeleton3D
	var body := character.find_child("Body") as MeshInstance3D
	var animation_player := character.find_child("AnimationPlayer") as AnimationPlayer
	animation_player.play("sit")
	animation_player.seek(0.0, true)
	await wait_physics_frames(2)
	var hem := Vector3.ZERO
	var count := 0
	for surface in body.mesh.get_surface_count():
		var material := body.mesh.surface_get_material(surface)
		if material == null or material.resource_name not in ["cloth_maroon", "cloth_ochre"]: # the slit and its trim
			continue
		var arrays := body.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			if vertices[i].y < 0.18: # its bottom edge
				hem += _posed(body, skeleton, arrays, i)
				count += 1
	hem /= maxf(count, 1.0)
	var ankles := (skeleton.get_bone_global_pose(skeleton.find_bone("LeftFoot")).origin
			+ skeleton.get_bone_global_pose(skeleton.find_bone("RightFoot")).origin) / 2.0
	var gap := Vector2(hem.x - ankles.x, hem.z - ankles.z).length()
	check(count > 0 and gap < 0.03,
			"sitting, the bottom of her slit is round her ankles (%.2f m from them), so it covers her legs" % gap)
	character.queue_free()


# Where vertex `i` of a surface's `arrays` is once the skeleton has bent it:
# each of its bones moves it, by that bone's share (as the graphics card does).
func _posed(body: MeshInstance3D, skeleton: Skeleton3D, arrays: Array, i: int) -> Vector3:
	var vertex: Vector3 = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array)[i]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	@warning_ignore("integer_division")
	var per_vertex := bones.size() / (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var posed := Vector3.ZERO
	for k in per_vertex:
		var weight := weights[i * per_vertex + k]
		if weight > 0.0:
			var bind := bones[i * per_vertex + k]
			var bone := skeleton.find_bone(body.skin.get_bind_name(bind))
			posed += weight * (skeleton.get_bone_global_pose(bone) * body.skin.get_bind_pose(bind) * vertex)
	return posed


# How many player pins there are in `node`, counting parts scripts made.
func _pins_in(node: Node) -> int:
	var count := 1 if node is PlayerMarker else 0
	for child in node.get_children(true):
		count += _pins_in(child)
	return count
