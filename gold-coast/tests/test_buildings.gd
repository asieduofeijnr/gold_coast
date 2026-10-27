extends TestCase
## Checks the neighborhood: every building is solid (walking into it stops the
## player), its collision covers its whole base (plinth and steps), and the
## billboard stands at the end of the row along the road, with solid posts you
## can walk between.
## Buildings' names don't float over them all the time: pointing at one with the
## mouse shows what it is, with its own name underneath.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const PUSH_STEPS := 120 # walk into something for 2 seconds

var _player: Player


func run_tests() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	_player = main.get_node("Player")
	await wait_physics_frames(10)

	var buildings: Array[Building] = []
	for child in main.get_node("Buildings").get_children():
		if child is Building:
			buildings.append(child)
	check(buildings.size() == 7, "there are 7 buildings (found %d)" % buildings.size())

	var row_end := -INF
	for building in buildings:
		var solid := _collision_box(building)
		var base := _mesh_box(building, "Base")
		check(solid.size != Vector3.ZERO and _same_footprint(solid, base),
				"%s: its collision covers its base" % building.building_name)
		if solid.end.z < 0.0: # the row along the far side of the road (the school and college are on the near side)
			row_end = maxf(row_end, solid.end.x)

		# The front faces +Z, so the front of the collision is its largest z.
		var front := solid.end.z
		var path := await _walk_from(Vector3(solid.get_center().x, 0.05, front + 3.0))
		var closest := INF
		for point in path:
			closest = minf(closest, point.z - front)
		check(closest > 0.2 and closest < 0.6,
				"%s: walking into it stops the player at its edge (%.2f m away)" % [building.building_name, closest])

	var billboard := main.get_node_or_null("Billboard") as Billboard
	check(billboard != null, "there's a billboard")
	if billboard == null:
		main.queue_free()
		return

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

	await _check_names(main, buildings)
	main.queue_free()


# No names floating over the buildings; pointing at one shows its name.
func _check_names(main: Node, buildings: Array[Building]) -> void:
	var labels := 0
	for building in buildings:
		labels += _labels_in(building)
	check(labels == 0, "no names float over the buildings all the time (found %d)" % labels)
	var names := main.get_node("BuildingNames") as BuildingNames
	var camera := main.get_node("IsoCamera") as Camera3D
	var screen := Rect2(Vector2.ZERO, camera.get_viewport().get_visible_rect().size)
	for building in buildings:
		var box := building.bounds()
		var roof := camera.unproject_position(Vector3(box.get_center().x, box.end.y - 0.4, box.get_center().z))
		var plate := names.nameplate
		check(names.point_at(roof) == building and plate.is_showing() and plate.title == building.building_name
				and plate.subtitle == building.subtitle and plate.subtitle != "" and screen.has_point(plate.position),
				"pointing at the %s shows its name: %s / %s" % [building.building_name, plate.title, plate.subtitle])
	var kiosk := main.get_node("Buildings/MobileMoneyKiosk") as Building
	var apartments := main.get_node("Buildings/ApartmentBlock") as Building
	check(kiosk.building_name == "Mobile Money Vendor" and apartments.subtitle == "Adom Court",
			"  ...like \"Mobile Money Vendor\" (%s) and \"Apartment Block\" (%s)" % [kiosk.subtitle, apartments.subtitle])
	names.point_at(camera.unproject_position(Vector3(0.0, 0.0, 6.0)))
	check(names.pointed == null and not names.nameplate.is_showing(), "  ...and pointing away from it hides the name again")


# How many 3D labels are in `node`, counting the parts its scripts made.
func _labels_in(node: Node) -> int:
	var count := 1 if node is Label3D else 0
	for child in node.get_children(true):
		count += _labels_in(child)
	return count


## The box around all of a building's solid shapes (the ones that block the
## player, not the roof copy used for seeing), in world space.
func _collision_box(building: Building) -> AABB:
	var box := AABB()
	for shape_node: CollisionShape3D in building.model_instance.find_children("*", "CollisionShape3D"):
		var body := shape_node.get_parent() as CollisionObject3D
		if body == null or body.collision_layer & 1 == 0:
			continue
		var shape_box := shape_node.global_transform * shape_node.shape.get_debug_mesh().get_aabb()
		box = shape_box if box.size == Vector3.ZERO else box.merge(shape_box)
	return box


## The box around one named mesh in a building's model, in world space.
func _mesh_box(building: Building, mesh_name: String) -> AABB:
	var mesh := building.model_instance.find_child(mesh_name) as MeshInstance3D
	return mesh.global_transform * mesh.get_aabb() if mesh != null else AABB()


## Whether two boxes cover the same patch of ground (to within 5 cm).
func _same_footprint(a: AABB, b: AABB) -> bool:
	return (absf(a.position.x - b.position.x) < 0.05 and absf(a.end.x - b.end.x) < 0.05
			and absf(a.position.z - b.position.z) < 0.05 and absf(a.end.z - b.end.z) < 0.05)


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
