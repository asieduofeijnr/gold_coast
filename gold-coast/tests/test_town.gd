extends TestCase
## Checks the living town. The trotro comes along the road, stops with its door
## at both stations (its mate calling out), people get on and off, it leaves the
## map, and it honks and waits for anyone in the road. Townspeople eat at the
## chop bar (leaving her seat free), kayayei carry loads, children play football
## and ampe, goats wander, and at closing time the market women walk home with
## their goods. Walking into the football kicks it, the street lamps come on at
## night, and passing remarks (people, the mate, animals) are in small bubbles.

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	await _check_quiet_town()
	await _check_living_town()
	GameState.town_life = false
	Engine.time_scale = 1.0
	GameState.reset()


# The things that work even with the townspeople switched off.
func _check_quiet_town() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	var player := main.get_node("Player") as Player
	var football := main.get_node("StreetFootball") as StreetFootball
	var kicks := [0]
	football.player_kicked.connect(func() -> void: kicks[0] += 1)
	football.ball.position = Vector3(0.0, StreetFootball.BALL_RADIUS, 0.0)
	football.ball_velocity = Vector3.ZERO
	var ball_spot := football.ball.global_position
	teleport(player, ball_spot + Vector3(-1.5, 0.05, 0.0))
	await wait_physics_frames(3)
	player.walk_to(ball_spot + Vector3(1.5, 0.0, 0.0))
	var kicked: bool = await wait_until(func() -> bool: return kicks[0] > 0, 4.0)
	check(kicked and football.ball_velocity.length() > 2.0 and football.ball_velocity.x > 0.0,
			"walking into the children's football kicks it the way she's going")

	var lamps := main.get_node("PowerLine") as PowerLine
	GameState.set_time(1, 20 * 60.0)
	await wait_physics_frames(2)
	var on_at_night := lamps.lamps_on()
	GameState.set_time(2, 10 * 60.0)
	await wait_physics_frames(2)
	check(on_at_night and not lamps.lamps_on(), "the street lamps come on at night and go out in the day")

	# Passing remarks are small next to what people say to her.
	var layer := CanvasLayer.new()
	add_child(layer)
	var normal := SpeechBubble.new()
	var small := SpeechBubble.new()
	for bubble in [normal, small]:
		bubble.speaker = "Auntie Yaa"
		layer.add_child(bubble)
	normal.say("Chale, the sun dey hot!")
	small.say("Chale, the sun dey hot!", true)
	var normal_size := normal.box_size()
	var small_size := small.box_size()
	check(small_size.x < normal_size.x * 0.75 and small_size.y < normal_size.y * 0.5,
			"a passing remark's bubble is much smaller than a normal one (%d x %d pixels, not %d x %d)"
			% [small_size.x, small_size.y, normal_size.x, normal_size.y])
	layer.queue_free()
	var chicken := main.get_node("Animals/Chicken") as Chicken
	var goat := main.get_node("Animals/Goat") as Goat
	chicken.cluck()
	goat.bleat()
	check(chicken.get_bubble().small and goat.get_bubble().small and chicken.get_bubble().text.begins_with("Kok"),
			"  ...like a chicken's \"%s\" and a goat's \"%s\"" % [chicken.get_bubble().text, goat.get_bubble().text])
	main.queue_free()
	await get_tree().process_frame


func _check_living_town() -> void:
	GameState.reset()
	GameState.town_life = true
	GameState.set_time(1, 9 * 60.0)
	GameState.time_speed = 0.0 # keep it mid-morning
	Engine.time_scale = 4.0 # and let the town's day go by four times faster
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	var player := main.get_node("Player") as Player
	var trotro := main.get_node("Trotro") as Trotro
	var east := main.get_node("TrotroStationEast") as TrotroStation
	var west := main.get_node("TrotroStationWest") as TrotroStation
	var town := main.get_node("TownLife") as TownLife
	teleport(player, Vector3(8.0, 0.05, 9.0)) # out of everyone's way

	# Two passengers of our own: one waiting at the station, one riding to the stop.
	var waiter := _make_person(main, Vector3(16.0, 0.0, -6.0))
	var rider := _make_person(main, Vector3(0.0, 0.0, 0.0))
	rider.visible = false
	east.wait_for_trotro(waiter)
	west.get_off_here(rider)
	await wait_until(func() -> bool: return waiter in east.waiting, 20.0)
	await wait_until(func() -> bool: return trotro.state == Trotro.State.AWAY, 60.0)

	var stops := []
	trotro.stopped.connect(func(station: TrotroStation) -> void: stops.append(station))
	trotro.make_trip()
	var at_station: bool = await wait_until(func() -> bool: return stops.size() >= 1, 30.0)
	var door := trotro.door_position()
	check(at_station and stops[0] == east and absf(door.x - east.global_position.x) < 0.3 and absf(door.z + 3.35) < 0.3,
			"the trotro comes along the road and stops with its door at the trotro station")
	await wait_physics_frames(5)
	var mate := trotro.get_mate()
	check(mate.visible and "Circle" in mate.saying() and mate.get_bubble().small,
			"  ...its mate jumps down, calling where it's going (in a small bubble): \"%s\"" % mate.saying())
	var got_on: bool = await wait_until(func() -> bool: return not waiter.visible, 20.0)
	check(got_on and waiter not in east.waiting, "  ...and the people waiting there get on")
	var at_stop: bool = await wait_until(func() -> bool: return stops.size() >= 2, 40.0)
	await wait_physics_frames(15)
	var rider_gap := Vector2(rider.global_position.x - trotro.door_position().x, rider.global_position.z - trotro.door_position().z).length()
	check(at_stop and stops[1] == west and rider.visible and rider_gap < 2.5,
			"it stops at the trotro stop too, and a passenger gets off there")
	var gone: bool = await wait_until(func() -> bool: return trotro.state == Trotro.State.AWAY, 40.0)
	check(gone and not trotro.visible, "  ...then it drives off the end of the road")

	await wait_until(func() -> bool: return trotro.state == Trotro.State.AWAY, 60.0)
	var honks := [0]
	trotro.honked.connect(func() -> void: honks[0] += 1)
	teleport(player, Vector3(32.0, 0.05, -1.9)) # standing in its lane
	trotro.make_trip()
	var honked: bool = await wait_until(func() -> bool: return honks[0] > 0, 20.0)
	await wait_physics_frames(40)
	var gap := trotro.global_position.x - player.global_position.x
	check(honked and trotro.speed < 0.1 and gap > Trotro.LENGTH / 2.0 + 0.5,
			"someone standing in the road makes the trotro honk and wait, %.1f m away" % gap)
	teleport(player, Vector3(32.0, 0.05, 8.0))
	var carried_on: bool = await wait_until(func() -> bool: return trotro.global_position.x < 30.0, 15.0)
	check(carried_on, "  ...and once the road is clear, it carries on")

	var table := (main.get_node("ChopBarShop") as ChopBarShop).table
	var eating: bool = await wait_until(func() -> bool: return table.guest_seated and table.is_served(true), 90.0)
	check(eating and not table.is_served(), "a customer sits and eats at the far side of Maame Esi's table, leaving her place free")
	var carrying: bool = await wait_until(func() -> bool:
		return town.people.any(func(person: Townsperson) -> bool: return person.visible and person.is_carrying()), 60.0)
	check(carrying, "other kayayei carry loads on their heads")
	var out := town.people.filter(func(person: Townsperson) -> bool: return person.visible).size()
	check(out >= 8, "townspeople are out and about (%d of %d)" % [out, town.people.size()])

	var football := main.get_node("StreetFootball") as StreetFootball
	var ball_was := football.ball.global_position
	var rolled := 0.0 # how far the ball goes in all (it may end up back where it started)
	for i in 300:
		await get_tree().physics_frame
		rolled += football.ball.global_position.distance_to(ball_was)
		ball_was = football.ball.global_position
	var playing := football.kids.filter(func(kid: Townsperson) -> bool: return kid.visible).size()
	check(rolled > 3.0 and playing == 4,
			"children play football: the ball goes back and forth between them (%.0f m)" % rolled)
	var girls := town.people.filter(func(person: Townsperson) -> bool:
		return person.visible and person.current_animation() == &"ampe")
	check(girls.size() == 3, "three girls are playing ampe (%d jumping)" % girls.size())
	var goat := main.get_node("Animals/Goat") as Goat
	var goat_was := goat.global_position
	await wait_physics_frames(240)
	check(goat.global_position.distance_to(goat_was) > 0.3, "goats wander about")

	# Closing time: the first market woman packs up and walks home with her goods.
	var market := main.get_node("Market") as Market
	var first: Vendor = market.sellers()[0]
	var her_place := first.global_position
	GameState.set_time(1, 18 * 60.0)
	await wait_physics_frames(2)
	var going_home: Array[Townsperson] = []
	for node in get_tree().get_nodes_in_group(Townsperson.GROUP):
		if (node as Townsperson).person_name == first.person_name and (node as Townsperson).visible:
			going_home.append(node)
	await wait_physics_frames(90)
	check(not first.is_here() and going_home.size() == 1 and going_home[0].is_carrying()
			and going_home[0].global_position.distance_to(her_place) > 1.5,
			"at closing time, %s packs up and walks home with her goods on her head" % first.person_name)

	main.queue_free()
	await get_tree().process_frame


func _make_person(main: Node, at: Vector3) -> Townsperson:
	var person := Townsperson.new()
	person.body = Townsperson.Body.MAN
	main.add_child(person)
	person.appear_at(at)
	return person
