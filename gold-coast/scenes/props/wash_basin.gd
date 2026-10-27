@tool
class_name WashBasin
extends StaticBody3D
## A big aluminium basin of soapy water on the ground beside the chop bar,
## with a pile of dirty bowls waiting to be washed. It's solid, so she stands
## beside it to wash.

const RADIUS := 0.42
const HEIGHT := 0.24

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

	_add(Shapes.cylinder(RADIUS, RADIUS * 0.78, HEIGHT, Vector3(0, HEIGHT / 2.0, 0), Palette.ColorName.ALUMINIUM))
	_add(Shapes.cylinder(RADIUS - 0.03, RADIUS - 0.03, 0.01, Vector3(0, HEIGHT - 0.04, 0), Palette.ColorName.WASH_WATER))
	# Soap suds floating on the water.
	for spot in [Vector3(0.12, 0, 0.08), Vector3(-0.15, 0, -0.05), Vector3(0.02, 0, -0.18)]:
		_add(Shapes.sphere(0.07, spot + Vector3(0, HEIGHT - 0.035, 0), Palette.ColorName.PAPER, 0.4))
	# Dirty bowls piled up beside it, waiting.
	for i in 3:
		var bowl := FoodBowl.new()
		bowl.position = Vector3(RADIUS + 0.2 + i * 0.012, i * 0.03, 0.05 - i * 0.01)
		_add(bowl)
	# Taller than the basin itself: anything lower than about knee height looks
	# like a step to the walkable area, so paths would try to climb over it.
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 1.0
	var solid := CollisionShape3D.new()
	solid.shape = shape
	solid.position.y = shape.height / 2.0
	_add(solid)


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
