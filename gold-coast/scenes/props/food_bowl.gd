@tool
class_name FoodBowl
extends Node3D
## A white enamel bowl with a blue rim, the kind every chop bar uses, filled
## with a dish: a mound of food with something on top. Dishes that don't come
## in a bowl (like pure water) show as a sachet instead. With no food, it's an
## empty bowl.

const RADIUS := 0.12
const DEPTH := 0.075

## The dish in the bowl, or nothing for an empty bowl.
@export var food: Food:
	set(value):
		food = value
		_rebuild()

# Everything this script made (an internal child, not saved in scenes).
var _pieces: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _pieces != null:
		_pieces.free()
	_pieces = Node3D.new()
	add_child(_pieces, false, Node.INTERNAL_MODE_FRONT)
	if food != null and not food.in_bowl:
		# A sachet: a little plastic pillow, lying flat.
		_pieces.add_child(Shapes.box(Vector3(0.11, 0.035, 0.17), Vector3(0, 0.018, 0), food.color))
		return
	_pieces.add_child(Shapes.cylinder(RADIUS, RADIUS * 0.62, DEPTH, Vector3(0, DEPTH / 2.0, 0),
			Palette.ColorName.ENAMEL_WHITE))
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.012
	torus.outer_radius = RADIUS + 0.006
	torus.rings = 16
	torus.ring_segments = 6
	rim.mesh = torus
	rim.material_override = Palette.material(Palette.ColorName.ENAMEL_RIM)
	rim.position.y = DEPTH
	_pieces.add_child(rim)
	if food == null:
		return
	_pieces.add_child(Shapes.sphere(RADIUS * 0.85, Vector3(0, DEPTH, 0), food.color, 0.45))
	_pieces.add_child(Shapes.sphere(RADIUS * 0.38, Vector3(0.025, DEPTH + 0.035, 0.015), food.topping, 0.8))
