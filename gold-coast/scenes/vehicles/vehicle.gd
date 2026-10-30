@tool
class_name Vehicle
extends AnimatableBody3D
## Something that drives along the road, like a trotro or a car. Every so often
## it comes in at one end of the road (`start_x`), makes its trip, and leaves at
## the other end (`end_x`), then a while later it comes again. It speeds up and
## slows down smoothly, turns its wheels, and dips its nose when it brakes. If
## anyone is in the road in front of it (the player or a townsperson), it honks
## and waits. None come late at night.
##
## Its model (from blender/scripts/build_vehicles.py) faces -Z, with its right
## side on +X; in the main scene it's turned to face the way it drives. It's
## solid (physics layer 3), so the player can't walk through it, but clicks and
## lines of sight go straight past.
##
## Each kind of vehicle says which model it is and how big (`_model()`,
## `get_size()`, `get_wheel_radius()`), and can write on it (`_dress()`).

## Sent when it honks at someone in its way.
signal honked

## What it's doing.
enum State { AWAY, DRIVING, STOPPED }

## The physics layer for vehicles: the player bumps into them, clicks don't.
const VEHICLE_LAYER := 3

## Where along X it comes from and where it leaves the map.
@export var start_x := 46.0
@export var end_x := -46.0
## Its cruising speed, and how quickly it speeds up and slows down.
@export var cruise_speed := 7.0
@export var acceleration := 2.5
@export var braking := 3.5
## How long until it comes again, in seconds (a random time between the two).
@export var gap_seconds := Vector2(35.0, 70.0)

## What it's doing right now.
var state := State.AWAY
## How fast it's going, in metres per second.
var speed := 0.0

# The model (it dips when braking), and its wheels.
var _body: Node3D
var _wheels: Array[Node3D] = []
var _solid: CollisionShape3D
var _horn: AudioStreamPlayer3D
var _honked_at := -INF


func _ready() -> void:
	collision_layer = 1 << (VEHICLE_LAYER - 1)
	collision_mask = 0
	_rebuild()
	if Engine.is_editor_hint():
		return
	_horn = AudioStreamPlayer3D.new()
	_horn.stream = _make_horn(_horn_notes())
	_horn.unit_size = 12.0
	_horn.volume_db = -6.0
	add_child(_horn, false, Node.INTERNAL_MODE_BACK)
	_park_away()
	if GameState.town_life:
		_run.call_deferred(_first_wait())


## How wide, tall, and long it is, in metres (x, y, and z).
func get_size() -> Vector3:
	return Vector3(1.8, 1.5, 4.0)


## How big its wheels are (for turning them as it goes).
func get_wheel_radius() -> float:
	return 0.3


## Which way along X it drives: 1 (toward +X) or -1.
func heading() -> float:
	return signf(end_x - start_x)


## Its wheels (for tests).
func get_wheels() -> Array[Node3D]:
	return _wheels


## One trip along the road: in from the start and off the far end. Does
## nothing if it's already on one.
func make_trip() -> void:
	if state != State.AWAY:
		return
	_set_off()
	await _drive_to(end_x, false)
	_park_away()


# Its model, as a scene (each kind of vehicle has its own).
func _model() -> PackedScene:
	return null


# Writes on the model and finds its moving parts, once it's made (each kind of
# vehicle does its own).
func _dress() -> void:
	pass


# How long it waits before its first trip, in seconds.
func _first_wait() -> float:
	return randf_range(gap_seconds.x, gap_seconds.y)


# Its horn's two notes, in hertz.
func _horn_notes() -> Vector2:
	return Vector2(392.0, 494.0)


# Whether it doesn't mind `person` in its way (like a trotro's own mate).
func _ignores(_person: Node3D) -> bool:
	return false


# Makes trips forever, starting after `first_wait` seconds: a trip, a wait,
# another trip.
func _run(first_wait: float) -> void:
	await _wait(first_wait)
	while is_inside_tree():
		while not TownLife.is_daytime() or state != State.AWAY: # none late at night
			await _wait(2.0)
		await make_trip()
		await _wait(randf_range(gap_seconds.x, gap_seconds.y))


# Comes onto the road at the start.
func _set_off() -> void:
	state = State.DRIVING
	global_position.x = start_x
	reset_physics_interpolation()
	visible = true


# Drives along the road to `target_x`, stopping there if `stop`. It honks and
# waits for anyone standing in its way.
func _drive_to(target_x: float, stop := true) -> void:
	state = State.DRIVING
	while is_inside_tree():
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		var to_go := (target_x - global_position.x) * heading()
		if to_go <= 0.01:
			if stop:
				global_position.x = target_x
				speed = 0.0
			return
		var wanted := cruise_speed
		if stop:
			wanted = minf(wanted, sqrt(2.0 * braking * to_go) + 0.3) # slow down to stop right at the spot
		if _someone_in_the_way():
			wanted = 0.0
			_honk()
		var was := speed
		speed = move_toward(speed, wanted, (acceleration if wanted > speed else braking) * delta)
		var step := minf(speed * delta, to_go) if stop else speed * delta
		global_position.x += step * heading()
		for wheel in _wheels:
			wheel.rotation.x -= step / get_wheel_radius()
		# It dips its nose a little when it brakes, and lifts it when it speeds up.
		var lean := clampf((was - speed) / maxf(delta, 0.001) * 0.012, -0.04, 0.04)
		_body.rotation.x = lerpf(_body.rotation.x, -lean, 0.15)


# The way ahead is blocked if the player, or a townsperson out and about, is in
# its lane just in front of it.
func _someone_in_the_way() -> bool:
	var people := get_tree().get_nodes_in_group(Townsperson.GROUP)
	people.append_array(get_tree().get_nodes_in_group("player"))
	var size := get_size()
	var front := size.z / 2.0
	# It looks far enough ahead to stop in time at this speed, with a couple of metres to spare.
	var look_ahead := front + speed * speed / (2.0 * braking) + 2.5
	for node in people:
		var person := node as Node3D
		if not person.visible or _ignores(person):
			continue
		var ahead := (person.global_position.x - global_position.x) * heading()
		if ahead > front - 0.5 and ahead < look_ahead and absf(person.global_position.z - global_position.z) < size.x / 2.0 + 0.6:
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


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


# Beep-beep: two short blasts of a two-note horn, made in code (no sound file).
static func _make_horn(notes: Vector2) -> AudioStreamWAV:
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
				value = (0.35 * signf(sin(TAU * notes.x * t)) + 0.3 * signf(sin(TAU * notes.y * t))) * 0.6 * fade
			data.encode_s16(n * 2, int(value * 32767.0))
			n += 1
	var horn := AudioStreamWAV.new()
	horn.format = AudioStreamWAV.FORMAT_16_BITS
	horn.mix_rate = rate
	horn.data = data
	return horn


# --- Building it ----------------------------------------------------------------

func _rebuild() -> void:
	if not is_node_ready() or _model() == null:
		return
	if _body != null:
		_body.free()
	_body = _model().instantiate() as Node3D
	add_child(_body, false, Node.INTERNAL_MODE_FRONT)
	_wheels.clear()
	for wheel in _body.find_children("Wheel*", "", true, false):
		_wheels.append(wheel as Node3D)
	# The solid box belongs to the vehicle itself (a physics body's shapes must
	# be its own children), so it doesn't tip when the model dips.
	if _solid == null:
		var size := get_size()
		_solid = Shapes.solid_box(Vector3(size.x, size.y - 0.15, size.z), Vector3(0.0, (size.y + 0.15) / 2.0, 0.0))
		add_child(_solid, false, Node.INTERNAL_MODE_FRONT)
	_dress()


# Writes `text` on the model at its marker `marker_name` (an empty in the
# model, facing out), in `color`, at most `pixel_size` big and `max_width`
# metres wide.
func _write(marker_name: String, text: String, color: Palette.ColorName, pixel_size: float, max_width: float,
		outline := Palette.ColorName.DARK_BROWN) -> Label3D:
	var marker := _body.find_child(marker_name, true, false) as Node3D
	var words := Label3D.new()
	words.text = text
	words.font_size = 64
	words.outline_size = 10
	var width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x + 20.0
	words.pixel_size = minf(pixel_size, max_width / width)
	words.modulate = Palette.color(color)
	words.outline_modulate = Palette.color(outline)
	marker.add_child(words)
	return words
