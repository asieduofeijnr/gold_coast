@tool
class_name Signboard
extends Node3D
## A hand-painted sign, like the ones on shops all over Ghana ("GOD IS GREAT
## ENTERPRISE"): words painted on a board, or straight onto a wall. The words
## shrink to fit the board. The front faces +Z.
## A sign can also stand on two posts of its own, like a market's. Then its
## posts are solid, and it fades like a building when it hides the player.

## The words.
@export var text := "GOD IS GREAT ENTERPRISE":
	set(value):
		text = value
		_rebuild()
## A second, smaller line under the words, like opening hours ("" for none).
@export var subtitle := "":
	set(value):
		subtitle = value
		_rebuild()
## How wide and tall the board is, in metres.
@export var board_size := Vector2(3.0, 0.5):
	set(value):
		board_size = value
		_rebuild()
## The board's color and the paint's.
@export var board_color := Palette.ColorName.KENTE_GOLD:
	set(value):
		board_color = value
		_rebuild()
@export var text_color := Palette.ColorName.TILE_RED:
	set(value):
		text_color = value
		_rebuild()
## Painted straight onto the wall, with no board.
@export var on_wall := false:
	set(value):
		on_wall = value
		_rebuild()
## Stands on two wooden posts, with the bottom of the board this high off the
## ground, in metres (0 = no posts, for a sign on a wall). With posts, the
## sign's position is on the ground between them.
@export var post_height := 0.0:
	set(value):
		post_height = value
		_rebuild()

const FONT_SIZE := 64

## How see-through it is, from 0 (solid) to 1 (invisible). SeeThrough raises it
## while a sign on posts stands between the camera and the player.
var fade := 0.0:
	set(value):
		fade = value
		for node in _generated:
			if node is GeometryInstance3D:
				(node as GeometryInstance3D).transparency = value

# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()
	if post_height > 0.0 and not Engine.is_editor_hint():
		add_to_group(SeeThrough.GROUP)


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	# The middle of the board: on top of its posts, if it has them.
	var middle := Vector3(0.0, post_height + board_size.y / 2.0, 0.0) if post_height > 0.0 else Vector3.ZERO
	if not on_wall:
		_add(Shapes.box(Vector3(board_size.x, board_size.y, 0.05), middle, board_color))
		# A painted border, a shade darker.
		_add(Shapes.box(Vector3(board_size.x + 0.06, board_size.y + 0.06, 0.04), middle + Vector3(0, 0, -0.01),
				Palette.ColorName.WOOD_DARK))
	if post_height > 0.0:
		_add_posts(middle)
	# The words fill 90% of the board's width and 65% of its height, or share
	# the board with the second line.
	if subtitle == "":
		_add_words(text, middle, Vector2(0.9, 0.65))
	else:
		_add_words(text, middle + Vector3(0.0, board_size.y * 0.15, 0.0), Vector2(0.9, 0.44))
		_add_words(subtitle, middle + Vector3(0.0, -board_size.y * 0.27, 0.0), Vector2(0.8, 0.22))


# Painted words, shrunk to fit `room` (a share of the board's width and height).
func _add_words(words_text: String, at: Vector3, room: Vector2) -> void:
	var words := Label3D.new()
	words.text = words_text
	words.font_size = FONT_SIZE
	words.outline_size = 0
	words.modulate = Palette.color(text_color)
	var words_width := ThemeDB.fallback_font.get_string_size(words_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	words.pixel_size = minf(board_size.x * room.x / maxf(words_width, 1.0), board_size.y * room.y / FONT_SIZE)
	words.position = at + Vector3(0, 0, 0.03)
	_add(words)


# Two wooden posts behind the board, solid so people walk round them, and an
# invisible copy of the board for seeing only (like a building's roof copy), so
# SeeThrough can tell when it's in the way.
func _add_posts(middle: Vector3) -> void:
	var top := post_height + board_size.y
	var solid := StaticBody3D.new()
	for side in [-1, 1]:
		var x: float = side * (board_size.x / 2.0 - 0.3)
		_add(Shapes.box(Vector3(0.1, top, 0.1), Vector3(x, top / 2.0, -0.07), Palette.ColorName.WOOD_DARK))
		solid.add_child(Shapes.solid_box(Vector3(0.2, 1.2, 0.2), Vector3(x, 0.6, -0.07)))
	_add(solid)
	var view := StaticBody3D.new()
	view.collision_layer = Building.VIEW_ONLY_LAYER
	view.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_size.x, board_size.y, 0.1)
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.position = middle
	view.add_child(holder)
	_add(view)


func _add(node: Node3D) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
