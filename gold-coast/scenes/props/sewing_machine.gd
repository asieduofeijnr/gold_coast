@tool
class_name SewingMachine
extends StaticBody3D
## A treadle sewing machine on its wooden table, the kind every Ghanaian
## dressmaker has: a black machine with gold lines, a wheel on its right, and an
## iron treadle underneath, with cloth on the table and a stool to sit on.
## Whoever sews sits on the stool (at this node, facing -Z), with the table in
## front of them. While `sewing` is on, the wheels spin. It's solid.

const TABLE_TOP := 0.72
## The table's width (x) and depth (z), and how far in front of the stool its
## middle is (the "sew" animation leans in to a table there).
const TABLE := Vector2(0.9, 0.48)
const TABLE_AT := -0.5

## Whether someone's sewing at it: the wheels spin.
var sewing := false

var _wheels: Array[Node3D] = []
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _process(delta: float) -> void:
	if sewing:
		for wheel in _wheels:
			wheel.rotation.x -= delta * 9.0


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	_wheels.clear()
	var middle := Vector3(0.0, 0.0, TABLE_AT)
	var iron := Palette.ColorName.SHITO_BLACK
	# The table on its iron frame, with a drawer and the treadle near the ground.
	_add(Shapes.box(Vector3(TABLE.x, 0.04, TABLE.y), middle + Vector3(0.0, TABLE_TOP - 0.02, 0.0), Palette.ColorName.WOOD_LIGHT))
	_add(Shapes.box(Vector3(0.28, 0.1, TABLE.y - 0.04), middle + Vector3(-0.27, TABLE_TOP - 0.09, 0.0), Palette.ColorName.WOOD_DARK))
	for side in [-1.0, 1.0]:
		_add(Shapes.box(Vector3(0.05, TABLE_TOP - 0.04, TABLE.y - 0.08),
				middle + Vector3(side * (TABLE.x / 2.0 - 0.07), (TABLE_TOP - 0.04) / 2.0, 0.0), iron))
	var treadle := Shapes.box(Vector3(0.5, 0.03, 0.3), middle + Vector3(0.0, 0.1, 0.12), iron)
	treadle.rotation.x = 0.15
	_add(treadle)
	_add_wheel(middle + Vector3(TABLE.x / 2.0 - 0.13, 0.36, 0.0), 0.17) # the big wheel the treadle turns
	# The machine: base, pillar, arm, and the needle end, with gold lines.
	var machine_y := TABLE_TOP
	_add(Shapes.box(Vector3(0.42, 0.04, 0.2), middle + Vector3(0.0, machine_y + 0.02, 0.0), iron))
	_add(Shapes.box(Vector3(0.09, 0.2, 0.12), middle + Vector3(0.15, machine_y + 0.14, 0.0), iron))
	_add(Shapes.box(Vector3(0.38, 0.08, 0.11), middle + Vector3(0.0, machine_y + 0.25, 0.0), iron))
	_add(Shapes.box(Vector3(0.07, 0.15, 0.09), middle + Vector3(-0.17, machine_y + 0.16, 0.0), iron))
	_add(Shapes.box(Vector3(0.006, 0.08, 0.006), middle + Vector3(-0.17, machine_y + 0.06, 0.0), Palette.ColorName.ALUMINIUM))
	for y in [0.225, 0.275]:
		_add(Shapes.box(Vector3(0.3, 0.008, 0.005), middle + Vector3(0.0, machine_y + y, 0.057), Palette.ColorName.KENTE_GOLD))
	_add_wheel(middle + Vector3(0.23, machine_y + 0.21, 0.0), 0.07)
	# Cloth being sewn, and more waiting in a pile.
	_add(Shapes.box(Vector3(0.36, 0.015, 0.3), middle + Vector3(-0.2, TABLE_TOP + 0.008, 0.04), Palette.ColorName.KENTE_GOLD))
	var pile := [Palette.ColorName.WALL_BLUE, Palette.ColorName.TILE_RED, Palette.ColorName.PALM_GREEN]
	for i in pile.size():
		_add(Shapes.box(Vector3(0.18, 0.03, 0.2), middle + Vector3(0.36, TABLE_TOP + 0.015 + i * 0.03, -0.1), pile[i]))
	# The stool.
	_add(Shapes.box(Vector3(0.36, 0.04, 0.32), Vector3(0.0, 0.4, 0.0), Palette.ColorName.WOOD_LIGHT))
	for x in [-0.14, 0.14]:
		for z in [-0.12, 0.12]:
			_add(Shapes.box(Vector3(0.04, 0.38, 0.04), Vector3(x, 0.19, z), Palette.ColorName.WOOD_DARK))
	_add(Shapes.solid_box(Vector3(TABLE.x + 0.1, 1.0, TABLE.y + 0.6), Vector3(0.0, 0.5, TABLE_AT + 0.22)))


# A wheel that turns on an axle along X: a disc with a spoke, so you can see it go round.
func _add_wheel(at: Vector3, radius: float) -> void:
	var wheel := Node3D.new()
	wheel.position = at
	var disc := Shapes.cylinder(radius, radius, 0.025, Vector3.ZERO, Palette.ColorName.ALUMINIUM if radius < 0.1 else Palette.ColorName.SHITO_BLACK)
	disc.rotation.z = PI / 2.0
	wheel.add_child(disc)
	wheel.add_child(Shapes.box(Vector3(0.03, radius * 1.8, 0.02), Vector3(0.016, 0.0, 0.0), Palette.ColorName.KENTE_GOLD))
	_add(wheel)
	_wheels.append(wheel)


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
