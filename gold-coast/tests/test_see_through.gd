extends TestCase
## Checks see-through buildings: a building standing between the camera and the
## player fades out, so she stays visible behind every building, and it turns
## solid again when she moves on.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	var player: Player = main.get_node("Player")
	var buildings: Array[Building] = []
	for child in main.get_node("Buildings").get_children():
		if child is Building:
			buildings.append(child)
	await wait_physics_frames(20)
	check(_faded(buildings).is_empty(), "no building fades while she's out on the road")

	for building in buildings:
		# Just behind the building, as seen from the camera.
		var box := building.bounds()
		var spot := Vector3(box.get_center().x, 0.05, box.position.z - 1.5)
		teleport(player, spot)
		await wait_physics_frames(30)
		check(building.fade > 0.5, "%s fades when she's behind it" % building.building_name)
		# Lines of sight run toward the camera, which is off to the right (+x), so
		# buildings entirely to her left can never be in the way.
		var off_to_the_left := buildings.filter(func(other: Building) -> bool: return other.bounds().end.x < spot.x - 0.5)
		var wrongly_faded := off_to_the_left.filter(func(other: Building) -> bool: return other.fade > 0.0)
		check(wrongly_faded.is_empty(), "  ...while buildings off to the side stay solid")

	teleport(player, Vector3(0.0, 0.05, 5.0))
	await wait_physics_frames(30)
	check(_faded(buildings).is_empty(), "every building turns solid again when she's back on the road")

	main.queue_free()


func _faded(buildings: Array[Building]) -> Array:
	return buildings.filter(func(building: Building) -> bool: return building.fade > 0.0)
