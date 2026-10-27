class_name TownLife
extends Node3D
## The neighborhood's people going about their day:
## - people from the apartment block and the compound house who go out by
##   trotro (waiting at a station, getting on), and come back on a later one
## - people walking about, now and then saying something
## - customers buying food at Maame Esi's chop bar and eating at her table
## - shoppers haggling at the market stalls
## - other kayayei carrying loads from Madam Serwaa's stall around town
## - market women walking home with their goods when the market closes
## - girls playing ampe
## Each person follows a routine, written one step at a time. At night they go
## home. None of this changes the game's state: it's how the town feels.
##
## Its children mark places: Doors (where people come out of buildings), Edges
## (where people walk in and out of the neighborhood), and AmpeSpot.

## Things townspeople say as they walk about (Twi and Ghanaian Pidgin English).
const CHATTER := ["Chale, the sun dey hot!", "Ete sen?", "Me ho ye!", "Have you eaten?", "God is good!",
		"Ei, this trotro is late o.", "I dey come!", "How be?"]
const HAGGLING := ["How much be this?", "Auntie, reduce it small!", "Make it cheap for me!", "Give me two."]
const PRICES := ["Ten cedis only!", "For you, five cedis.", "Ei, I can't reduce it o!", "Take it, take it!"]
## What market women say as they go home at closing time.
const GOODBYES := ["Bye bye o!", "See you tomorrow!", "Chale, today was hard.", "Time to go home!",
		"My feet dey pain me o!", "Tomorrow again, by God's grace."]
## Clothes to pick from: kaba and slit, shirt and trousers, and school uniforms
## (yellow and brown, as at many Ghanaian schools).
const TOPS := [Palette.ColorName.KENTE_GOLD, Palette.ColorName.WALL_BLUE, Palette.ColorName.PALM_GREEN,
		Palette.ColorName.TILE_RED, Palette.ColorName.PAPER, Palette.ColorName.WALL_PINK, Palette.ColorName.KELEWELE_ORANGE,
		Palette.ColorName.ENAMEL_RIM]
const BOTTOMS := [Palette.ColorName.DARK_BROWN, Palette.ColorName.ENAMEL_RIM, Palette.ColorName.CLOTH_MAROON,
		Palette.ColorName.WOOD_DARK, Palette.ColorName.BAR_GREEN, Palette.ColorName.KENTE_GOLD]
## Townspeople are only out between these times (minutes after midnight).
const DAY_STARTS := 5.5 * 60.0
const DAY_ENDS := 21.0 * 60.0

## The trotro stations, so travellers can go and come back.
@export var stations: Array[TrotroStation] = []
## Maame Esi's chop bar, for its customers.
@export var chop_bar: ChopBarShop
## The market, for shoppers and kayayei.
@export var market: Market

## Everyone the town has made (for tests).
var people: Array[Townsperson] = []

@onready var _doors: Array[Node] = $Doors.get_children()
@onready var _edges: Array[Node] = $Edges.get_children()


func _ready() -> void:
	if not GameState.town_life:
		return
	# Let the walkable area finish baking before anyone asks it for a path.
	for i in 3:
		await get_tree().physics_frame
	for i in 6:
		var home: Node3D = _doors[i % 2] # the apartment block and the compound house
		_traveller(_make_person(Townsperson.Body.MAN if i % 2 == 0 else Townsperson.Body.WOMAN), home)
	for i in 3:
		_walker(_make_person(Townsperson.Body.WOMAN if i != 1 else Townsperson.Body.MAN))
	for i in 2:
		_customer(_make_person(Townsperson.Body.MAN if i == 0 else Townsperson.Body.WOMAN))
	for i in 3:
		_shopper(_make_person(Townsperson.Body.WOMAN))
	for i in 2:
		var carrier := _make_person(Townsperson.Body.WOMAN)
		carrier.top_color = Palette.ColorName.CLOTH_CREAM if i == 0 else Palette.ColorName.WALL_PINK
		_carrier(carrier)
	var girls: Array[Townsperson] = []
	for i in 3:
		girls.append(_make_person(Townsperson.Body.GIRL, true))
	_ampe(girls)
	market.seller_left.connect(_walk_home)


## Whether townspeople are out at this time of day.
static func is_daytime() -> bool:
	return GameState.minutes >= DAY_STARTS and GameState.minutes < DAY_ENDS


# --- Routines ---------------------------------------------------------------

# Someone who lives here and goes out by trotro: out of their door, to the
# nearest station, onto a trotro... and some time later back on another one,
# off at a station, and home again.
func _traveller(person: Townsperson, home: Node3D) -> void:
	await _wait(randf_range(1.0, 10.0)) # out early, to be waiting when the first trotro comes
	while is_inside_tree():
		await _until_daytime(person)
		person.appear_at(_near(home.global_position, 0.5))
		var station := _nearest_station(home.global_position)
		await station.wait_for_trotro(person)
		await _wait(randf_range(50.0, 140.0)) # away, wherever they were going
		await _until_daytime(person)
		var stop: TrotroStation = stations.pick_random()
		await stop.get_off_here(person)
		await person.walk_to(_near(home.global_position, 0.5))
		await person.vanish()
		await _wait(randf_range(15.0, 60.0)) # at home


# Someone walking about: in from the edge of the neighborhood, to a few places,
# and off again.
func _walker(person: Townsperson) -> void:
	await _wait(randf_range(1.0, 20.0))
	while is_inside_tree():
		await _until_daytime(person)
		person.appear_at(_near((_edges.pick_random() as Node3D).global_position, 1.0))
		for i in randi_range(2, 4):
			await person.walk_to(_near(_somewhere_to_go(), 1.0))
			if randf() < 0.4:
				person.say(_greeting() if randf() < 0.3 else CHATTER.pick_random())
			await _wait(randf_range(2.0, 6.0))
		await person.walk_to((_edges.pick_random() as Node3D).global_position)
		await person.vanish()
		await _wait(randf_range(10.0, 40.0))


# A customer at Maame Esi's chop bar: they order at her stall, then sit at the
# bench across from the player's to eat (or take it away if it's taken).
func _customer(person: Townsperson) -> void:
	await _wait(randf_range(5.0, 40.0))
	var table := chop_bar.table
	while is_inside_tree():
		await _until_daytime(person)
		person.appear_at(_near(_doors_and_edges().pick_random().global_position, 0.8))
		await person.walk_to(chop_bar.counter.global_position + Vector3(1.0, 0.0, 0.2))
		person.face(chop_bar.vendor.global_position)
		var dish: Food = chop_bar.menu[randi() % 4] # one of the proper meals
		person.say("%s, please!" % dish.title)
		await _wait(1.5)
		if not table.guest_seated:
			table.guest_seated = true
			chop_bar.vendor.call_out("Sit down, my dear. It's coming!")
			await person.walk_to(table.guest_seat.global_position + table.guest_seat.global_basis.z * 0.45)
			person.place_at(table.guest_seat)
			person.hold(&"eat")
			table.serve(dish, true)
			await _wait(randf_range(15.0, 30.0))
			table.clear(true)
			person.hold(&"")
			table.guest_seated = false
		else:
			chop_bar.vendor.call_out("Here you are! Enjoy.")
			await _wait(2.0)
		await person.walk_to(_near(_doors_and_edges().pick_random().global_position, 0.8))
		await person.vanish()
		await _wait(randf_range(30.0, 90.0))


# A shopper at the market: a few stalls, a bit of haggling, and home.
func _shopper(person: Townsperson) -> void:
	await _wait(randf_range(2.0, 30.0))
	while is_inside_tree():
		await _until_daytime(person)
		await _until_market_opens(person)
		person.appear_at(_near(_doors_and_edges().pick_random().global_position, 0.8))
		var stalls := market.shopping_stalls()
		stalls.shuffle()
		for stall in stalls.slice(0, randi_range(2, 3)):
			if not market.is_open():
				break # closing time: off home
			await person.walk_to(_near(stall.front_spot(), 0.3))
			person.face(stall.global_position)
			if randf() < 0.7:
				person.say(HAGGLING.pick_random())
				await _wait(1.3)
				var seller := stall.seller as Vendor
				if seller != null and seller.is_here():
					seller.call_out(PRICES.pick_random())
			await _wait(randf_range(3.0, 6.0))
		await person.walk_to(_near((_edges.pick_random() as Node3D).global_position, 1.0))
		await person.vanish()
		await _wait(randf_range(20.0, 60.0))


# Another kayayo: she takes a load from Madam Serwaa's pile, carries it on her
# head to one of the places loads go, puts it down, and comes back for more.
func _carrier(person: Townsperson) -> void:
	await _wait(randf_range(1.0, 10.0))
	if market.is_open() and is_daytime():
		person.appear_at(_near(market.load_pile_spot(), 1.5))
	while is_inside_tree():
		await _until_daytime(person)
		await _until_market_opens(person)
		if not person.visible: # back out in the morning
			person.appear_at(_near((_edges.pick_random() as Node3D).global_position, 1.0))
		await person.walk_to(_near(market.load_pile_spot(), 0.4))
		person.face(market.load_pile_spot() - Vector3(0.0, 0.0, 0.9))
		await _wait(1.5)
		person.carry(Market.GOODS.pick_random()[1])
		var places := get_tree().get_nodes_in_group(DeliverySpot.SPOTS_GROUP)
		var place: Node3D = places.pick_random()
		await person.walk_to(_near(place.global_position + Vector3(0.7, 0.0, 0.3), 0.3))
		await _wait(1.0)
		person.put_down()
		if randf() < 0.5:
			person.say(["Medaase!", "Next load!", "Chale, it was heavy!"].pick_random())
		await _wait(randf_range(1.0, 4.0))


# A market woman going home at closing time, with her goods in a headpan on
# her head. (The Market has already taken her away from her stall; this is
# her walking off. She's back at her place before the market opens.)
func _walk_home(seller: Vendor, goods_color: Palette.ColorName) -> void:
	var person := Townsperson.new()
	person.person_name = seller.person_name
	person.top_color = seller.top_color
	person.bottom_color = seller.skirt_color
	person.trim_color = seller.trim_color
	person.headwrap_color = seller.headwrap_color
	add_child(person)
	person.appear_at(seller.global_position)
	person.rotation.y = seller.rotation.y
	person.carry(goods_color)
	if randf() < 0.5:
		person.say(GOODBYES.pick_random())
	await _walk_off(person)
	person.queue_free()


# Girls playing ampe in a little circle, now and then calling out.
func _ampe(girls: Array[Townsperson]) -> void:
	var middle := ($AmpeSpot as Node3D).global_position
	while is_inside_tree():
		if not is_daytime():
			for girl in girls:
				girl.vanish()
			while not is_daytime():
				await _wait(5.0)
		for i in girls.size():
			var angle := TAU * i / girls.size()
			girls[i].appear_at(middle + Vector3(cos(angle), 0.0, sin(angle)) * 0.75)
			girls[i].face(middle)
			girls[i].hold(&"ampe")
		while is_daytime():
			await _wait(randf_range(4.0, 9.0))
			girls.pick_random().say(["Ampe!", "Your turn!", "Ei, you lost!", "Again! Again!"].pick_random())


# --- Helpers ----------------------------------------------------------------

func _make_person(body: Townsperson.Body, in_uniform := false) -> Townsperson:
	var person := Townsperson.new()
	person.body = body
	if in_uniform:
		person.top_color = Palette.ColorName.KENTE_GOLD
		person.bottom_color = Palette.ColorName.WOOD_DARK
	else:
		person.top_color = TOPS.pick_random()
		person.bottom_color = BOTTOMS.pick_random()
		person.headwrap_color = TOPS.pick_random()
		person.trim_color = BOTTOMS.pick_random()
	person.walk_speed = randf_range(1.15, 1.45)
	person.visible = false
	add_child(person)
	people.append(person)
	return person


# At night, they're at home: they vanish until morning, and come back out
# from the edge of the neighborhood.
func _until_daytime(person: Townsperson) -> void:
	if is_daytime():
		return
	if person.visible:
		await person.vanish()
	while not is_daytime():
		await _wait(5.0)


# While the market's closed, shoppers and kayayei are at home: they walk off
# the edge of the neighborhood, and come back once it opens.
func _until_market_opens(person: Townsperson) -> void:
	if market.is_open():
		return
	if person.visible:
		await _walk_off(person)
	while not market.is_open():
		await _wait(5.0)


# Walks off the edge of the neighborhood and vanishes there: home. They're gone
# within the hour, even if they haven't got there (if the clock races on while
# the player sleeps, nobody's still on their way when the market opens again).
func _walk_off(person: Townsperson) -> void:
	person.walk_to(_near((_edges.pick_random() as Node3D).global_position, 1.0))
	var set_off := GameState.now()
	while person.walking and GameState.now() - set_off < 60.0:
		await _wait(0.25)
	await person.vanish()


# "Good morning!", "Good afternoon!", or "Good evening!", whatever the time.
func _greeting() -> String:
	if GameState.minutes < 12.0 * 60.0:
		return "Good morning!"
	return "Good afternoon!" if GameState.minutes < 16.5 * 60.0 else "Good evening!"


func _nearest_station(point: Vector3) -> TrotroStation:
	var nearest: TrotroStation = stations[0]
	for station in stations:
		if station.global_position.distance_to(point) < nearest.global_position.distance_to(point):
			nearest = station
	return nearest


# A place worth walking to: a door, the market, a station, or the chop bar.
func _somewhere_to_go() -> Vector3:
	var places: Array[Vector3] = [market.load_pile_spot() + Vector3(-6.0, 0.0, 2.0),
			chop_bar.counter.global_position + Vector3(2.0, 0.0, 1.5)]
	for station in stations:
		places.append(station.global_position + Vector3(2.5, 0.0, -1.0))
	for door in _doors:
		places.append((door as Node3D).global_position)
	return places.pick_random()


func _doors_and_edges() -> Array[Node3D]:
	var places: Array[Node3D] = []
	for node in _doors + _edges:
		places.append(node as Node3D)
	return places


# `point`, moved a little at random so people don't all stand on the same spot.
func _near(point: Vector3, spread: float) -> Vector3:
	return point + Vector3(randf_range(-spread, spread), 0.0, randf_range(-spread, spread))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout
