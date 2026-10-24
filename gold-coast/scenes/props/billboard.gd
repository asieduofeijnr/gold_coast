@tool
class_name Billboard
extends StaticBody3D
## A roadside billboard on two steel posts, painted in Ghana's flag colors:
## red, gold, and green, with black stars. The posts are solid, but you can
## walk under the board between them. The front faces +Z.

const POST_WIDTH := 0.22
const BORDER := 0.12

## The big words in the middle of the board.
@export var headline := "AKWAABA!":
	set(value):
		headline = value
		_rebuild()
## The smaller words along the bottom.
@export var tagline := "Welcome to Gold Coast":
	set(value):
		tagline = value
		_rebuild()
## Width and height of the board, in metres.
@export var board_size := Vector2(4.4, 2.4):
	set(value):
		board_size = value
		_rebuild()
## How high the bottom of the board is, in metres. Tall enough to walk under.
@export var clearance := 3.0:
	set(value):
		clearance = value
		_rebuild()

## The two solid posts, made by this script.
var posts: Array[CollisionShape3D] = []

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
	posts.clear()

	var middle := clearance + board_size.y / 2.0
	var top := clearance + board_size.y + BORDER

	# Two steel posts behind the board. They're the only solid parts.
	var post_size := Vector3(POST_WIDTH, clearance + board_size.y * 0.75, POST_WIDTH)
	for side in [-1.0, 1.0]:
		var at := Vector3(side * (board_size.x / 2.0 - 0.7), post_size.y / 2.0, -0.2)
		_add(Shapes.box(post_size, at, Palette.ColorName.ASPHALT))
		posts.append(_add(Shapes.solid_box(post_size, at)) as CollisionShape3D)

	# The board: a dark border with red, gold, and green bands on the front.
	var border_size := Vector3(board_size.x + BORDER * 2.0, board_size.y + BORDER * 2.0, 0.15)
	_add(Shapes.box(border_size, Vector3(0.0, middle, -0.05), Palette.ColorName.DARK_BROWN))
	var band_height := board_size.y / 3.0
	var bands := [Palette.ColorName.CLOTH_RED, Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN]
	for i in bands.size():
		var at := Vector3(0.0, clearance + board_size.y - band_height * (i + 0.5), 0.035)
		_add(Shapes.box(Vector3(board_size.x, band_height, 0.02), at, bands[i]))

	# A black star at each end of the gold band, like the star on the flag.
	for side in [-1.0, 1.0]:
		var star := MeshInstance3D.new()
		star.mesh = _star_mesh(band_height * 0.36, band_height * 0.15)
		star.material_override = Palette.material(Palette.ColorName.DARK_BROWN)
		star.position = Vector3(side * (board_size.x / 2.0 - 0.4), middle, 0.05)
		_add(star)

	_add(_words(headline, 96, 8, Palette.ColorName.DARK_BROWN, middle))
	_add(_words(tagline, 48, 0, Palette.ColorName.ROAD_MARKING, clearance + band_height * 0.5))

	# Two spotlights on short arms, pointing back at the board.
	for side in [-1.0, 1.0]:
		var x: float = side * board_size.x * 0.3
		_add(Shapes.box(Vector3(0.06, 0.06, 0.55), Vector3(x, top + 0.08, 0.2), Palette.ColorName.ASPHALT))
		_add(Shapes.box(Vector3(0.32, 0.12, 0.2), Vector3(x, top + 0.06, 0.5), Palette.ColorName.ASPHALT))


## Flat words painted on the front of the board. `thickness` makes them bolder.
func _words(text: String, font_size: int, thickness: int, color_name: Palette.ColorName, y: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.006
	label.modulate = Palette.color(color_name)
	label.outline_size = thickness
	label.outline_modulate = Palette.color(color_name)
	label.double_sided = false
	label.position = Vector3(0.0, y, 0.06)
	return label


## A flat five-pointed star facing +Z.
func _star_mesh(outer_radius: float, inner_radius: float) -> ArrayMesh:
	var points: Array[Vector3] = []
	for i in 10:
		var angle := PI / 2.0 + TAU * i / 10.0
		var radius := outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector3(cos(angle), sin(angle), 0.0) * radius)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		for point in [Vector3.ZERO, points[(i + 1) % 10], points[i]]:
			surface.set_normal(Vector3.BACK)
			surface.add_vertex(point)
	return surface.commit()


func _add(node: Node3D) -> Node3D:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
	return node
