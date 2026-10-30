@tool
class_name Signpost
extends StaticBody3D
## A painted sign on a post, like the one at the trotro stop. The writing is on
## both sides, so you can read it from either way. The board is as wide as the
## writing needs (`board_width()`). The post is solid.

const BOARD := Vector3(1.5, 0.5, 0.06) # the smallest board: longer writing makes it wider
const HEIGHT := 2.3 # where the middle of the board is
const FONT_SIZE := 64
const PIXEL_SIZE := 0.0033 # how big the writing is: metres for each pixel of the font
const MARGIN := 0.12 # the board showing at each end of the writing, in metres

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


## How wide the board is: at least BOARD's width, and wide enough for the
## writing with a margin at each end. (Label3D writes in the default font.)
func board_width() -> float:
	var writing := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return maxf(BOARD.x, writing * PIXEL_SIZE + 2.0 * MARGIN)


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()

	_add(Shapes.box(Vector3(0.1, HEIGHT, 0.1), Vector3(0, HEIGHT / 2.0, 0), Palette.ColorName.ZINC_DARK))
	_add(Shapes.box(Vector3(board_width(), BOARD.y, BOARD.z), Vector3(0, HEIGHT, 0), board_color))
	for side in [1, -1]:
		var words := Label3D.new()
		words.text = text
		words.font_size = FONT_SIZE
		words.pixel_size = PIXEL_SIZE
		words.outline_size = 0
		words.modulate = Palette.color(text_color)
		words.position = Vector3(0, HEIGHT, side * (BOARD.z / 2.0 + 0.002))
		words.rotation.y = 0.0 if side == 1 else PI
		_add(words)
	_add(Shapes.solid_box(Vector3(0.1, HEIGHT, 0.1), Vector3(0, HEIGHT / 2.0, 0)))


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
