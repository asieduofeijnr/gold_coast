@tool
class_name Blackboard
extends StaticBody3D
## A school blackboard on a wooden stand, with the day's lesson chalked on it.
## Its writing faces +Z. It's solid, so people walk round it.

## What's chalked on the board.
@export_multiline var lesson := "2 + 3 = 5\nA  B  C  D":
	set(value):
		lesson = value
		_rebuild()

const BOARD := Vector2(1.5, 0.95)
## How high the bottom of the board is, in metres.
const BOTTOM := 0.75

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
	var middle := Vector3(0.0, BOTTOM + BOARD.y / 2.0, 0.0)
	_add(Shapes.box(Vector3(BOARD.x + 0.1, BOARD.y + 0.1, 0.05), middle + Vector3(0, 0, -0.01), Palette.ColorName.WOOD_DARK))
	_add(Shapes.box(Vector3(BOARD.x, BOARD.y, 0.05), middle, Palette.ColorName.SHITO_BLACK))
	_add(Shapes.box(Vector3(BOARD.x, 0.04, 0.09), Vector3(0.0, BOTTOM - 0.03, 0.03), Palette.ColorName.WOOD_LIGHT)) # chalk ledge
	var top := BOTTOM + BOARD.y + 0.08
	for x in [-0.62, 0.62]:
		_add(Shapes.box(Vector3(0.07, top, 0.07), Vector3(x, top / 2.0, -0.07), Palette.ColorName.WOOD_DARK))
		_add(Shapes.box(Vector3(0.08, 0.06, 0.55), Vector3(x, 0.03, -0.07), Palette.ColorName.WOOD_DARK)) # feet
	var chalk := Label3D.new()
	chalk.text = lesson
	chalk.font_size = 48
	chalk.pixel_size = 0.0042
	chalk.outline_size = 0
	chalk.modulate = Palette.color(Palette.ColorName.PAPER) * Color(1, 1, 1, 0.92)
	chalk.position = middle + Vector3(0, 0, 0.03)
	_add(chalk)
	_add(Shapes.solid_box(Vector3(BOARD.x + 0.1, 1.2, 0.55), Vector3(0, 0.6, -0.07)))


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
