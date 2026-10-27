@tool
class_name Signpost
extends StaticBody3D
## A painted sign on a post, like the one at the trotro stop. The writing is on
## both sides, so you can read it from either way. The post is solid.

const BOARD := Vector3(1.5, 0.5, 0.06)
const HEIGHT := 2.3 # where the middle of the board is

## The words on the sign.
@export var text := "TROTRO STOP":
	set(value):
		text = value
		_rebuild()
## The colors of the board and the writing.
@export var board_color := Palette.ColorName.KENTE_GOLD:
	set(value):
		board_color = value
		_rebuild()
@export var text_color := Palette.ColorName.DARK_BROWN:
	set(value):
		text_color = value
		_rebuild()

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

	_add(Shapes.box(Vector3(0.1, HEIGHT, 0.1), Vector3(0, HEIGHT / 2.0, 0), Palette.ColorName.ZINC_DARK))
	_add(Shapes.box(BOARD, Vector3(0, HEIGHT, 0), board_color))
	for side in [1, -1]:
		var words := Label3D.new()
		words.text = text
		words.font_size = 64
		words.pixel_size = 0.0033
		words.outline_size = 0
		words.modulate = Palette.color(text_color)
		words.position = Vector3(0, HEIGHT, side * (BOARD.z / 2.0 + 0.002))
		words.rotation.y = 0.0 if side == 1 else PI
		_add(words)
	_add(Shapes.solid_box(Vector3(0.1, HEIGHT, 0.1), Vector3(0, HEIGHT / 2.0, 0)))


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
