extends TestCase
## Checks the road's traffic, and the trotro station's sign:
## - the trotro is the cream one with the blue stripe: its four wheels turn as
##   it drives, its sliding door opens at a station and closes after, and its
##   sayings fit on it
## - the Uber, a silver Toyota Yaris with Uber stickers, drives through town the
##   other way, in the other lane, turning its wheels, and leaves at the far
##   end. It honks and waits for anyone standing in its way, and it's solid.
## - a station's sign is wide enough for its words, and clear of its shelter

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.set_time(1, 10 * 60.0)
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	_check_station_signs(main)
	await _check_trotro(main)
	await _check_uber(main)
	main.queue_free()
	await get_tree().process_frame
	GameState.reset()


func _check_station_signs(main: Node) -> void:
	var fits := true
	var clear := true
	var sizes: Array[String] = []
	for station: TrotroStation in [main.get_node("TrotroStationEast"), main.get_node("TrotroStationWest")]:
		var signpost := _all_in(station, "Signpost")[0] as Signpost
		var writing := (_all_in(signpost, "Label3D")[0] as Label3D).get_aabb().size.x
		var board := 0.0
		for box: MeshInstance3D in _all_in(signpost, "MeshInstance3D"):
			board = maxf(board, box.mesh.get_aabb().size.x)
		fits = fits and writing > 0.5 and writing + 0.1 <= board
		if station.shelter:
			clear = clear and absf(signpost.position.x) - board / 2.0 >= TrotroStation.ROOF.x / 2.0
		sizes.append("%s, %.2f m of writing on a %.2f m board" % [signpost.text, writing, board])
	check(fits, "each trotro station's sign is wide enough for its words (%s)" % "; ".join(sizes))
	check(clear, "  ...and the station's sign is clear of its shelter's roof")


func _check_trotro(main: Node) -> void:
	var trotro := main.get_node("Trotro") as Trotro
	var wheels := trotro.get_wheels()
	var texts := _all_in(trotro, "Label3D").map(func(words: Label3D) -> String: return words.text)
	var back := _label_with(trotro, trotro.slogan)
	check(wheels.size() == 4 and trotro.destination in texts and trotro.side_slogan in texts and back != null
			and back.get_aabb().size.x <= Trotro.WIDTH - 0.2,
			"the trotro has its four wheels, where it's going in the windscreen, and its sayings painted on (they fit)")
	var turned := wheels[0].rotation.x
	var stops := []
	trotro.stopped.connect(func(station: TrotroStation) -> void: stops.append(station), CONNECT_ONE_SHOT)
	trotro.make_trip()
	await wait_until(func() -> bool: return trotro.global_position.x < trotro.start_x - 6.0, 10.0)
	check(absf(wheels[0].rotation.x - turned) > 3.0, "  ...its wheels turn as it drives")
	var stopped: bool = await wait_until(func() -> bool: return not stops.is_empty(), 30.0)
	await wait_physics_frames(40)
	var open := trotro.is_door_open()
	var left: bool = await wait_until(func() -> bool: return trotro.state == Trotro.State.DRIVING, 30.0)
	await wait_physics_frames(40)
	check(stopped and open and left and not trotro.is_door_open(),
			"  ...its door slides open at the trotro station, and closed when it goes")


func _check_uber(main: Node) -> void:
	var uber := main.get_node("Uber") as Car
	var trotro := main.get_node("Trotro") as Trotro
	var player := main.get_node("Player") as Player
	var stickers := _all_in(uber, "Label3D").filter(func(words: Label3D) -> bool: return words.text == "Uber")
	check(not uber.visible and uber.state == Vehicle.State.AWAY and stickers.size() == 2,
			"the Uber waits off the map until it's time to come, with an Uber sticker front and back")
	check(uber.collision_layer == 1 << (Vehicle.VEHICLE_LAYER - 1)
			and player.collision_mask & uber.collision_layer != 0,
			"  ...and it's solid: she bumps into it, like the trotro")
	var wheels := uber.get_wheels()
	var turned := wheels[0].rotation.x
	uber.make_trip()
	await wait_physics_frames(30)
	var east := -uber.global_basis.z # its front
	check(uber.visible and uber.global_position.x > uber.start_x and east.x > 0.99
			and uber.global_position.z > 0.0 and trotro.global_position.z < 0.0,
			"the Uber comes along the road from the west, facing east, in the other lane from the trotro's")
	await wait_until(func() -> bool: return uber.global_position.x > -20.0, 15.0)
	check(wheels.size() == 4 and absf(wheels[0].rotation.x - turned) > 3.0, "  ...its wheels turn as it drives")

	var honks := [0]
	uber.honked.connect(func() -> void: honks[0] += 1)
	teleport(player, Vector3(uber.global_position.x + 14.0, 0.05, uber.global_position.z)) # standing in its lane
	var honked: bool = await wait_until(func() -> bool: return honks[0] > 0, 10.0)
	await wait_until(func() -> bool: return uber.speed < 0.1, 5.0) # it brakes from 7 m/s
	await wait_physics_frames(30)
	var gap := player.global_position.x - uber.global_position.x
	check(honked and uber.speed < 0.1 and gap > Car.SIZE.z / 2.0 + 0.5,
			"someone standing in its lane makes the Uber honk and wait, %.1f m away" % gap)
	teleport(player, Vector3(player.global_position.x, 0.05, 5.0)) # onto the pavement
	var gone: bool = await wait_until(func() -> bool: return uber.state == Vehicle.State.AWAY, 30.0)
	check(gone and not uber.visible, "  ...and once the road is clear, it carries on and drives off the far end")


# Every node of class `type_name` in `node`'s tree, counting parts scripts made
# (and the parts of models).
func _all_in(node: Node, type_name: String) -> Array:
	var found := []
	for child in node.get_children(true):
		if child.is_class(type_name) or (child.get_script() != null and child.get_script().get_global_name() == type_name):
			found.append(child)
		found.append_array(_all_in(child, type_name))
	return found


func _label_with(node: Node, text: String) -> Label3D:
	for words: Label3D in _all_in(node, "Label3D"):
		if words.text == text:
			return words
	return null
