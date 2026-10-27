@tool
class_name Desk
extends StaticBody3D
## A wooden office desk with books, papers, and an open register on it, like
## the one the training college's registrar works at. Whoever works at it
## stands behind it (-Z); visitors stand in front (+Z). It's solid.

const SIZE := Vector3(1.3, 0.76, 0.6)

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
	var top := SIZE.y
	_add(Shapes.box(Vector3(SIZE.x, 0.05, SIZE.z), Vector3(0.0, top - 0.025, 0.0), Palette.ColorName.WOOD_LIGHT))
	_add(Shapes.box(Vector3(SIZE.x - 0.08, 0.5, 0.03), Vector3(0.0, top - 0.3, SIZE.z / 2.0 - 0.04), Palette.ColorName.WOOD_DARK))
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_add(Shapes.box(Vector3(0.06, top - 0.05, 0.06), Vector3(x * (SIZE.x / 2.0 - 0.06), (top - 0.05) / 2.0,
					z * (SIZE.z / 2.0 - 0.06)), Palette.ColorName.WOOD_DARK))
	# A stack of books, some papers, and the register open in the middle.
	var books := [Palette.ColorName.TILE_RED, Palette.ColorName.WALL_BLUE, Palette.ColorName.PALM_GREEN]
	for i in books.size():
		var book := Shapes.box(Vector3(0.26, 0.05, 0.2), Vector3(-0.42, top + 0.025 + i * 0.05, -0.05), books[i])
		book.rotation.y = 0.12 * (i - 1)
		_add(book)
	for i in 2:
		var paper := Shapes.box(Vector3(0.22, 0.004, 0.3), Vector3(0.42, top + 0.003 + i * 0.004, 0.0), Palette.ColorName.PAPER)
		paper.rotation.y = 0.2 - 0.35 * i
		_add(paper)
	for side in [-1.0, 1.0]:
		var page := Shapes.box(Vector3(0.18, 0.01, 0.26), Vector3(side * 0.09, top + 0.008, 0.0), Palette.ColorName.PAPER)
		page.rotation.z = -side * 0.08
		_add(page)
	_add(Shapes.box(Vector3(0.015, 0.015, 0.14), Vector3(0.24, top + 0.01, 0.05), Palette.ColorName.SACHET_BLUE)) # a biro
	_add(Shapes.solid_box(Vector3(SIZE.x, 1.0, SIZE.z), Vector3(0.0, 0.5, 0.0)))


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
