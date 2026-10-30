@tool
class_name TrotroStation
extends Node3D
## A trotro station by the road: a painted sign, a bench, and (at a big station)
## a shelter with a zinc roof. People wait here for the trotro, on the bench if
## there's room. When it stops, anyone getting off steps down first, then
## everyone waiting gets on.
##
## Place it on the pavement's edge by the road, with its -Z pointing away from
## the road. The trotro stops with its door level with it.

## The shelter's zinc roof.
const ROOF := Vector3(3.0, 0.06, 2.0)

## The words on the station's sign.
@export var title := "TROTRO STATION":
	set(value):
		title = value
		_rebuild()
## Whether it has a shelter over the bench.
@export var shelter := true:
	set(value):
		shelter = value
		_rebuild()

## People waiting for the trotro here.
var waiting: Array[Townsperson] = []
## People on the trotro who'll get off here.
var getting_off: Array[Townsperson] = []
## The trotro stopped here, or null.
var trotro_here: Trotro

# The bench's two seats, and who's sitting on them.
var _seats: Array[Marker3D] = []
var _sitting := {}
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


## Has `person` wait here for the trotro (on the bench if there's room), and
## returns once they've got on it.
func wait_for_trotro(person: Townsperson) -> void:
	var seat: Marker3D = null
	for spot in _seats:
		if not _sitting.has(spot):
			seat = spot
			break
	if seat != null:
		_sitting[seat] = person
		await person.walk_to(seat.global_position + seat.global_basis.z * -0.5)
		person.place_at(seat)
		person.hold(&"sit")
	else:
		await person.walk_to(_standing_spot())
		person.face(global_position + Vector3(0.0, 0.0, 3.0))
	waiting.append(person)
	await person.boarded
	if seat != null:
		_sitting.erase(seat)


## Has `person` ride the trotro until it stops here, and returns once they've
## got off (just outside its door).
func get_off_here(person: Townsperson) -> void:
	getting_off.append(person)
	await person.got_off


## The trotro has stopped: people getting off here step down, one at a time.
func let_off(trotro: Trotro) -> void:
	var leaving := getting_off.duplicate()
	getting_off.clear()
	for person: Townsperson in leaving:
		if is_instance_valid(person):
			person.appear_at(trotro.door_position() + Vector3(randf_range(-0.3, 0.3), 0.0, -0.3))
			person.got_off.emit()
			await get_tree().create_timer(0.7, false).timeout


## The trotro has stopped: everyone waiting walks to its door and gets on.
## Returns once they're all on (or after 12 seconds, whichever comes first).
func let_on(trotro: Trotro) -> void:
	var boarding := waiting.duplicate()
	waiting.clear()
	for person: Townsperson in boarding:
		person.board(trotro.door_position())
	var time_left := 12.0
	while time_left > 0.0 and boarding.any(func(person: Townsperson) -> bool: return is_instance_valid(person) and person.visible):
		await get_tree().physics_frame
		time_left -= get_physics_process_delta_time()


# A spot on the pavement near the sign, for someone standing to wait.
func _standing_spot() -> Vector3:
	return global_position + global_basis * Vector3(randf_range(-1.6, 1.6), 0.0, randf_range(-1.0, -0.6))


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	_seats.clear()

	var wood := Palette.ColorName.WOOD_LIGHT
	var dark := Palette.ColorName.WOOD_DARK
	# The bench, facing the road.
	_add(Shapes.box(Vector3(1.6, 0.05, 0.34), Vector3(0, 0.395, -1.45), wood))
	for x in [-0.7, 0.7]:
		_add(Shapes.box(Vector3(0.05, 0.37, 0.3), Vector3(x, 0.185, -1.45), dark))
	_add(Shapes.box(Vector3(1.6, 0.3, 0.04), Vector3(0, 0.65, -1.62), wood)) # backrest
	for x in [-0.45, 0.45]:
		var seat := Marker3D.new()
		seat.position = Vector3(x, 0, -1.45)
		seat.rotation.y = PI # sitting facing the road (+Z)
		_add(seat)
		_seats.append(seat)
	if shelter:
		for x in [-1.3, 1.3]:
			for z in [-0.35, -1.85]:
				_add(Shapes.box(Vector3(0.08, 2.4, 0.08), Vector3(x, 1.2, z), Palette.ColorName.ZINC_DARK))
		var roof := Shapes.box(ROOF, Vector3(0, 2.45, -1.1), Palette.ColorName.ZINC_LIGHT)
		roof.rotation.x = 0.08 # sloping toward the back, for the rain
		_add(roof)
	# The sign stands at the bench's end, or (with a shelter) far enough along
	# that its whole board is clear of the roof.
	var signpost := Signpost.new()
	signpost.text = title
	var along := ROOF.x / 2.0 + 0.15 + signpost.board_width() / 2.0 if shelter else 1.2
	signpost.position = Vector3(-along, 0, -0.3)
	_add(signpost)


func _add(node: Node3D) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
