@tool
class_name SchoolBench
extends StaticBody3D
## A long, low wooden bench for schoolchildren, with places for four pupils
## (`seats`) who sit facing its -Z. It's solid, so people walk round it.

const LENGTH := 2.8
## The seat's height: right for a child (Townsperson.CHILD_SCALE of the
## grown-ups' benches).
const HEIGHT := 0.26
const PUPILS := 4

## Where each pupil sits, facing -Z (put a child there with Townsperson.place_at()).
var seats: Array[Marker3D] = []

# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	seats.clear()
	_add(Shapes.box(Vector3(LENGTH, 0.04, 0.28), Vector3(0.0, HEIGHT - 0.02, 0.0), Palette.ColorName.WOOD_LIGHT))
	for x in [-LENGTH / 2.0 + 0.15, 0.0, LENGTH / 2.0 - 0.15]:
		_add(Shapes.box(Vector3(0.06, HEIGHT - 0.04, 0.22), Vector3(x, (HEIGHT - 0.04) / 2.0, 0.0), Palette.ColorName.WOOD_DARK))
	for i in PUPILS:
		var seat := Marker3D.new()
		seat.position = Vector3((i - (PUPILS - 1) / 2.0) * LENGTH / PUPILS, 0.0, 0.0)
		_add(seat)
		seats.append(seat)
	_add(Shapes.solid_box(Vector3(LENGTH, 1.0, 0.3), Vector3(0.0, 0.5, 0.0)))


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
