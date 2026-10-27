@tool
class_name ChopTable
extends StaticBody3D
## A wooden table with a bench on each side, outside the chop bar, where people
## sit and eat. The table is solid; the benches aren't, so people can slide in.
## The table runs along X. The player sits on the bench on its -Z side, facing
## +Z (`seat`); townspeople use the bench across from her (`guest_seat`).

const TABLE_SIZE := Vector3(1.3, 0.72, 0.7)
const TOP := 0.05 # how thick the table top and bench seats are
const SEAT_HEIGHT := 0.42
const SEAT_DEPTH := 0.3
## How far each bench is from the middle of the table.
const BENCH_GAP := 0.56

## Where she sits to eat: on the -Z bench, facing the table. Made by this script.
var seat: Marker3D
## Where a townsperson sits to eat: on the +Z bench, facing her side.
var guest_seat: Marker3D
## Whether a townsperson is sitting at the guest seat (TownLife keeps track).
var guest_seated := false

var _bowl: FoodBowl
var _guest_bowl: FoodBowl
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


## Puts a bowl of `food` on the table in front of her seat (or the guest seat).
func serve(food: Food, for_guest := false) -> void:
	var bowl := _guest_bowl if for_guest else _bowl
	bowl.food = food
	bowl.visible = true


## Takes the bowl away (from her place, or the guest's).
func clear(for_guest := false) -> void:
	(_guest_bowl if for_guest else _bowl).visible = false


## Whether there's food on the table at her place (or the guest's).
func is_served(for_guest := false) -> bool:
	return (_guest_bowl if for_guest else _bowl).visible


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()

	var wood := Palette.ColorName.WOOD_LIGHT
	var legs := Palette.ColorName.WOOD_DARK
	var half := TABLE_SIZE / 2.0
	_add(Shapes.box(Vector3(TABLE_SIZE.x, TOP, TABLE_SIZE.z), Vector3(0, TABLE_SIZE.y - TOP / 2.0, 0), wood))
	for x in [-1, 1]:
		for z in [-1, 1]:
			_add(Shapes.box(Vector3(0.06, TABLE_SIZE.y - TOP, 0.06),
					Vector3(x * (half.x - 0.08), (TABLE_SIZE.y - TOP) / 2.0, z * (half.z - 0.08)), legs))
	for side in [-1, 1]:
		var z: float = side * BENCH_GAP
		_add(Shapes.box(Vector3(TABLE_SIZE.x + 0.1, TOP, SEAT_DEPTH), Vector3(0, SEAT_HEIGHT - TOP / 2.0, z), wood))
		for x in [-1, 1]:
			_add(Shapes.box(Vector3(0.05, SEAT_HEIGHT - TOP, SEAT_DEPTH - 0.06),
					Vector3(x * (half.x - 0.05), (SEAT_HEIGHT - TOP) / 2.0, z), legs))
	_add(Shapes.solid_box(TABLE_SIZE, Vector3(0, half.y, 0)))

	seat = Marker3D.new()
	seat.position = Vector3(0, 0, -BENCH_GAP)
	seat.rotation.y = PI # she faces its -Z, which points at the table
	_add(seat)
	guest_seat = Marker3D.new()
	guest_seat.position = Vector3(0.2, 0, BENCH_GAP) # its -Z already points at the table
	_add(guest_seat)

	_bowl = FoodBowl.new()
	_bowl.position = Vector3(0, TABLE_SIZE.y, -half.z + 0.17)
	_bowl.visible = false
	_add(_bowl)
	_guest_bowl = FoodBowl.new()
	_guest_bowl.position = Vector3(0.2, TABLE_SIZE.y, half.z - 0.17)
	_guest_bowl.visible = false
	_add(_guest_bowl)


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
