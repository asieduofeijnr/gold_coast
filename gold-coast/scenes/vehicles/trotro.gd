@tool
class_name Trotro
extends AnimatableBody3D
## A trotro, the minibuses that carry Ghana. It comes along the road, stops at
## each trotro station so people can get off and on while its mate jumps down
## calling where it's going, then drives off the far end of the road. A while
## later, another one comes. If anyone is in the road in front of it (the player
## or a townsperson), it honks and waits.
##
## It's built from simple shapes. Its front faces -Z and its door is on its
## right (+X). Turned in the main scene, it drives toward -X, with its door on
## the pavement side. It's solid (physics layer 3), so the player can't walk
## through it, but clicks and lines of sight go straight past.

## Sent when it stops at a station, and when it honks.
signal stopped(station: TrotroStation)
signal honked

## What it's doing.
enum State { AWAY, DRIVING, STOPPED }

const LENGTH := 4.9
const WIDTH := 1.95
const WHEEL_RADIUS := 0.34
## Where its door is, on the trotro: people get on and off just outside it.
const DOOR := Vector3(1.45, 0.0, -0.4)
## The physics layer for vehicles: the player bumps into them, clicks don't.
const VEHICLE_LAYER := 3

## The stations it stops at, in the order it reaches them.
@export var stations: Array[TrotroStation] = []
## Where along X it comes from and where it leaves the map.
@export var start_x := 46.0
@export var end_x := -46.0
## Its cruising speed, and how quickly it speeds up and slows down.
@export var cruise_speed := 7.0
@export var acceleration := 2.5
@export var braking := 3.5
## How long it waits at a station once everyone's on, in seconds.
@export var stop_seconds := 3.0
## How long until the next trotro comes, in seconds (a random time between the two).
@export var gap_seconds := Vector2(35.0, 70.0)
## Where it's going: the mate calls it, and it's on the board in the windscreen.
@export var destination := "CIRCLE":
	set(value):
		destination = value
		_rebuild()
## The saying painted on its back, as on every trotro.
@export var slogan := "GOD'S TIME IS THE BEST":
	set(value):
		slogan = value
		_rebuild()
## The saying painted along its side.
@export var side_slogan := "SEA NEVER DRY":
	set(value):
		side_slogan = value
		_rebuild()

## What it's doing right now.
var state := State.AWAY
## How fast it's going, in metres per second.
var speed := 0.0

var _body: Node3D
var _solid: CollisionShape3D
var _door: Node3D
var _wheels: Array[Node3D] = []
var _mate: Townsperson
var _horn: AudioStreamPlayer3D
var _honked_at := -INF


func _ready() -> void:
	collision_layer = 1 << (VEHICLE_LAYER - 1)
	collision_mask = 0
	_rebuild()
	if Engine.is_editor_hint():
		return
	_mate = Townsperson.new()
	_mate.body = Townsperson.Body.MAN
	_mate.person_name = "The mate"
	_mate.top_color = Palette.ColorName.KENTE_GOLD
	_mate.bottom_color = Palette.ColorName.DARK_BROWN
	_mate.trim_color = Palette.ColorName.TILE_RED
	_mate.visible = false
	add_child(_mate, false, Node.INTERNAL_MODE_BACK)
	_horn = AudioStreamPlayer3D.new()
	_horn.stream = _make_horn()
	_horn.unit_size = 12.0
	_horn.volume_db = -6.0
	add_child(_horn, false, Node.INTERNAL_MODE_BACK)
	_park_away()
	if GameState.town_life:
		_run.call_deferred(randf_range(28.0, 36.0)) # time for the first people to reach the stations


## Where people step on and off, just outside its door, in the world.
func door_position() -> Vector3:
	var door := to_global(DOOR)
	return Vector3(door.x, 0.0, door.z)


## The mate, who jumps down at every station (for tests).
func get_mate() -> Townsperson:
	return _mate


## Makes trips forever: comes along the road, stops at every station, leaves,
## and after a while the next one comes. Starts after `first_wait` seconds.
func _run(first_wait: float) -> void:
	await _wait(first_wait)
	while is_inside_tree():
		while not TownLife.is_daytime() or state != State.AWAY: # no trotros late at night
			await _wait(2.0)
		await make_trip()
		await _wait(randf_range(gap_seconds.x, gap_seconds.y))


## One trip along the road: in from the start, a stop at each station, and off
## the far end. Does nothing if it's already on a trip.
func make_trip() -> void:
	if state != State.AWAY:
		return
	state = State.DRIVING
	global_position.x = start_x
	reset_physics_interpolation()
	visible = true
	for station in stations:
		await _drive_to(station.global_position.x - (door_position().x - global_position.x))
		await _stop_at(station)
	await _drive_to(end_x, false)
	_park_away()


# Drives along the road (toward -X) to `target_x`, stopping there if `stop`.
# It honks and waits for anyone standing in its way.
func _drive_to(target_x: float, stop := true) -> void:
	state = State.DRIVING
	while is_inside_tree():
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		var to_go := global_position.x - target_x
		if to_go <= 0.01:
			if stop:
				global_position.x = target_x
				speed = 0.0
			return
		var wanted := cruise_speed
		if stop:
			wanted = minf(wanted, sqrt(2.0 * braking * to_go) + 0.3) # slow down to stop right at the station
		if _someone_in_the_way():
			wanted = 0.0
			_honk()
		var was := speed
		speed = move_toward(speed, wanted, (acceleration if wanted > speed else braking) * delta)
		global_position.x = maxf(global_position.x - speed * delta, target_x) if stop else global_position.x - speed * delta
		for wheel in _wheels:
			wheel.rotation.x -= speed * delta / WHEEL_RADIUS
		# It dips its nose a little when it brakes, and lifts it when it speeds up.
		var lean := clampf((was - speed) / maxf(delta, 0.001) * 0.012, -0.04, 0.04)
		_body.rotation.x = lerpf(_body.rotation.x, -lean, 0.15)


# At a station: the door slides open, the mate jumps down and calls, people get
# off and on, and then it's on its way.
func _stop_at(station: TrotroStation) -> void:
	state = State.STOPPED
	_body.rotation.x = 0.0
	_slide_door(true)
	stopped.emit(station)
	# The mate hops out and goes round to the back corner, where everyone can see
	# him, calling out where it's going.
	_mate.appear_at(door_position())
	_mate.say("%s! %s! %s!" % [destination.capitalize(), destination.capitalize(), destination.capitalize()])
	_mate.walk_to(_mate_spot()).connect(_mate.face.bind(station.global_position), CONNECT_ONE_SHOT)
	station.trotro_here = self
	await station.let_off(self)
	await station.let_on(self)
	await _wait(stop_seconds)
	await station.let_on(self) # anyone who's turned up since
	_mate.say("Let's go! Driver, move!")
	await _mate.walk_to(door_position())
	await _mate.vanish()
	_slide_door(false)
	station.trotro_here = null


# Where the mate stands while it's stopped: on the pavement side, just past its
# back corner.
func _mate_spot() -> Vector3:
	var spot := to_global(Vector3(WIDTH / 2.0 + 0.35, 0.0, LENGTH / 2.0 + 0.4))
	return Vector3(spot.x, 0.0, spot.z)


# The way ahead is blocked if the player, or a townsperson out and about, is in
# its lane just in front of it.
func _someone_in_the_way() -> bool:
	var people := get_tree().get_nodes_in_group(Townsperson.GROUP)
	people.append_array(get_tree().get_nodes_in_group("player"))
	for node in people:
		var person := node as Node3D
		if person == _mate or not person.visible:
			continue
		var ahead := global_position.x - person.global_position.x # it drives toward -X
		var front := LENGTH / 2.0
		# Look far enough ahead to stop in time at this speed, with a couple of metres to spare.
		var look_ahead := front + speed * speed / (2.0 * braking) + 2.5
		if ahead > front - 0.5 and ahead < look_ahead and absf(person.global_position.z - global_position.z) < WIDTH / 2.0 + 0.6:
			return true
	return false


func _honk() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _honked_at < 2.5:
		return
	_honked_at = now
	_horn.play()
	honked.emit()


func _park_away() -> void:
	state = State.AWAY
	speed = 0.0
	visible = false
	global_position.x = start_x
	reset_physics_interpolation()


func _slide_door(open: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_door, "position:z", DOOR.z + (1.0 if open else 0.0), 0.4)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


# Beep-beep: two short blasts of a two-note horn, made in code (no sound file).
static func _make_horn() -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	var parts := [[0.18, true], [0.08, false], [0.3, true]]
	var total := 0
	for part: Array in parts:
		total += int(part[0] * rate)
	data.resize(total * 2)
	var n := 0
	for part: Array in parts:
		var length := int(part[0] * rate)
		for i in length:
			var value := 0.0
			if part[1]:
				var t := float(n) / rate
				var fade := minf(1.0, minf(i, length - i) / 200.0)
				value = (0.35 * signf(sin(TAU * 392.0 * t)) + 0.3 * signf(sin(TAU * 494.0 * t))) * 0.6 * fade
			data.encode_s16(n * 2, int(value * 32767.0))
			n += 1
	var horn := AudioStreamWAV.new()
	horn.format = AudioStreamWAV.FORMAT_16_BITS
	horn.mix_rate = rate
	horn.data = data
	return horn


# --- Building it ----------------------------------------------------------------

func _rebuild() -> void:
	if not is_node_ready():
		return
	if _body != null:
		_body.free()
	_wheels.clear()
	_body = Node3D.new()
	add_child(_body, false, Node.INTERNAL_MODE_FRONT)
	var white := Palette.ColorName.ROAD_MARKING
	var glass := Palette.ColorName.PHONE_BEZEL
	var half_w := WIDTH / 2.0
	var half_l := LENGTH / 2.0
	_part(Shapes.box(Vector3(WIDTH, 1.0, LENGTH), Vector3(0, 0.78, 0), white))
	_part(Shapes.box(Vector3(WIDTH - 0.06, 0.7, LENGTH - 0.3), Vector3(0, 1.63, 0.1), glass))
	_part(Shapes.box(Vector3(WIDTH, 0.14, LENGTH - 0.2), Vector3(0, 2.04, 0.05), white))
	# Pillars between the windows.
	for z in [-2.25, -1.0, 0.2, 1.3, 2.3]:
		for side in [-1, 1]:
			_part(Shapes.box(Vector3(0.05, 0.7, 0.12), Vector3(side * (half_w - 0.02), 1.63, z), white))
	# A red, gold, and green stripe along each side, like Ghana's flag.
	for side in [-1, 1]:
		var x: float = side * (half_w + 0.005)
		_part(Shapes.box(Vector3(0.01, 0.07, LENGTH - 0.1), Vector3(x, 1.08, 0), Palette.ColorName.TILE_RED))
		_part(Shapes.box(Vector3(0.01, 0.07, LENGTH - 0.1), Vector3(x, 1.0, 0), Palette.ColorName.KENTE_GOLD))
		_part(Shapes.box(Vector3(0.01, 0.07, LENGTH - 0.1), Vector3(x, 0.92, 0), Palette.ColorName.PALM_GREEN))
	# Bumpers and lights.
	for end in [-1, 1]:
		_part(Shapes.box(Vector3(WIDTH + 0.06, 0.18, 0.12), Vector3(0, 0.36, end * (half_l + 0.03)), Palette.ColorName.ZINC_DARK))
		for side in [-1, 1]:
			var light := Palette.ColorName.PAPER if end == -1 else Palette.ColorName.TILE_RED
			_part(Shapes.box(Vector3(0.3, 0.14, 0.03), Vector3(side * 0.66, 0.66, end * (half_l + 0.01)), light))
	# Wheels, with shiny hubcaps.
	for z in [-1.6, 1.55]:
		for side in [-1, 1]:
			var wheel := Node3D.new()
			wheel.position = Vector3(side * (half_w - 0.12), WHEEL_RADIUS, z)
			_part(wheel)
			var tyre := Shapes.cylinder(WHEEL_RADIUS, WHEEL_RADIUS, 0.24, Vector3.ZERO, glass)
			tyre.rotation.z = PI / 2.0
			wheel.add_child(tyre)
			var hub := Shapes.cylinder(0.16, 0.16, 0.25, Vector3.ZERO, Palette.ColorName.ALUMINIUM)
			hub.rotation.z = PI / 2.0
			wheel.add_child(hub)
			_wheels.append(wheel)
	# The sliding door, on the right. When it slides open, the dark doorway shows.
	_part(Shapes.box(Vector3(0.02, 1.45, 0.9), Vector3(half_w + 0.005, 1.08, DOOR.z), glass))
	_door = Node3D.new()
	_door.position = Vector3(half_w + 0.03, 1.08, DOOR.z)
	_part(_door)
	_door.add_child(Shapes.box(Vector3(0.03, 1.5, 0.95), Vector3.ZERO, white))
	_door.add_child(Shapes.box(Vector3(0.035, 0.5, 0.8), Vector3(0, 0.45, 0), glass))
	# A roof rack piled with luggage: sacks, a bundle in cloth, and yams.
	for side in [-1, 1]:
		_part(Shapes.box(Vector3(0.04, 0.05, LENGTH - 0.8), Vector3(side * (half_w - 0.15), 2.18, 0.2), Palette.ColorName.ZINC_DARK))
	_part(Shapes.sphere(0.28, Vector3(-0.35, 2.32, 0.9), Palette.ColorName.KENKEY_BEIGE, 0.6))
	_part(Shapes.sphere(0.26, Vector3(0.35, 2.3, 0.5), Palette.ColorName.BANKU_WHITE, 0.6))
	_part(Shapes.box(Vector3(0.6, 0.3, 0.5), Vector3(0.1, 2.3, -0.5), Palette.ColorName.CLOTH_RED))
	for i in 4:
		_part(Shapes.sphere(0.1, Vector3(-0.45 + i * 0.12, 2.25, -1.2), Palette.ColorName.WOOD_LIGHT, 1.6))
	# Its sayings, painted on: one across the back, one along the side the camera
	# sees, and where it's going on a board in the windscreen.
	_part(_words(slogan, Vector3(0, 1.12, half_l + 0.012), 0.0, Palette.ColorName.TILE_RED, 0.0028))
	_part(_words(side_slogan, Vector3(-half_w - 0.012, 0.66, 0.2), -PI / 2.0, Palette.ColorName.ENAMEL_RIM, 0.004))
	_part(_words(destination, Vector3(0, 1.82, -half_l + 0.135), PI, Palette.ColorName.KENTE_GOLD, 0.0035))
	# The solid box belongs to the trotro itself (a physics body's shapes must be
	# its own children), so it doesn't tip when the body dips.
	if _solid == null:
		_solid = Shapes.solid_box(Vector3(WIDTH, 2.0, LENGTH), Vector3(0, 1.15, 0))
		add_child(_solid, false, Node.INTERNAL_MODE_FRONT)


func _part(node: Node3D) -> void:
	_body.add_child(node)


func _words(text: String, at: Vector3, turn: float, color: Palette.ColorName, pixel_size: float) -> Label3D:
	var words := Label3D.new()
	words.text = text
	words.font_size = 64
	words.pixel_size = pixel_size
	words.outline_size = 10
	words.modulate = Palette.color(color)
	words.outline_modulate = Palette.color(Palette.ColorName.DARK_BROWN)
	words.position = at
	words.rotation.y = turn
	return words
