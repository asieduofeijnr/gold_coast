@tool
class_name Trotro
extends Vehicle
## A trotro, the minibuses that carry Ghana: a classic cream one with a blue
## stripe (the model is from blender/scripts/build_vehicles.py). It comes along
## the road, stops at each trotro station so people can get off and on while
## its mate jumps down calling where it's going, then drives off the far end of
## the road. A while later, another one comes. (Driving, turning its wheels, and
## honking at anyone in its way are Vehicle's.)
##
## Its door slides open on its right (+X). Turned in the main scene, it drives
## toward -X, with its door on the pavement side.

## Sent when it stops at a station.
signal stopped(station: TrotroStation)

const LENGTH := 4.9
const WIDTH := 1.95
const HEIGHT := 2.38
const WHEEL_RADIUS := 0.34
## Where its door is, on the trotro: people get on and off just outside it.
const DOOR := Vector3(1.45, 0.0, -0.6)
## How far its door slides back to open, in metres.
const DOOR_SLIDE := 1.0
const MODEL := preload("res://art/models/vehicles/trotro.glb")

## The stations it stops at, in the order it reaches them.
@export var stations: Array[TrotroStation] = []
## How long it waits at a station once everyone's on, in seconds.
@export var stop_seconds := 3.0
## Where it's going: the mate calls it, and it's on the card in the windscreen.
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

var _door: Node3D
var _door_closed_z := 0.0
var _mate: Townsperson


func _ready() -> void:
	super()
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


func get_size() -> Vector3:
	return Vector3(WIDTH, HEIGHT, LENGTH)


func get_wheel_radius() -> float:
	return WHEEL_RADIUS


## Where people step on and off, just outside its door, in the world.
func door_position() -> Vector3:
	var door := to_global(DOOR)
	return Vector3(door.x, 0.0, door.z)


## The mate, who jumps down at every station (for tests).
func get_mate() -> Townsperson:
	return _mate


## Whether its sliding door is open (for tests).
func is_door_open() -> bool:
	return _door.position.z > _door_closed_z + DOOR_SLIDE / 2.0


## One trip along the road: in from the start, a stop at each station, and off
## the far end. Does nothing if it's already on a trip.
func make_trip() -> void:
	if state != State.AWAY:
		return
	_set_off()
	for station in stations:
		await _drive_to(station.global_position.x - (door_position().x - global_position.x))
		await _stop_at(station)
	await _drive_to(end_x, false)
	_park_away()


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


func _ignores(person: Node3D) -> bool:
	return person == _mate


func _first_wait() -> float:
	return randf_range(28.0, 36.0) # time for the first people to reach the stations


# The door slides back along its side to open, and forward to close.
func _slide_door(open: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_door, "position:z", _door_closed_z + (DOOR_SLIDE if open else 0.0), 0.4)


func _model() -> PackedScene:
	return MODEL


# Its sayings, painted on: one across the back, one along the side the camera
# sees, and where it's going on the card in the windscreen.
func _dress() -> void:
	_door = _body.find_child("Door", true, false) as Node3D
	_door_closed_z = _door.position.z
	_write("BackSlogan", slogan, Palette.ColorName.TILE_RED, 0.0028, WIDTH - 0.25)
	_write("SideSlogan", side_slogan, Palette.ColorName.ENAMEL_RIM, 0.004, 2.6)
	_write("DestinationCard", destination, Palette.ColorName.DARK_BROWN, 0.0017, 0.54, Palette.ColorName.PAPER)
