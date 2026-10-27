@tool
extends Node3D
## A straight road with a dashed center line, a sidewalk on each side, and an
## open gutter (drain) along the outside of each sidewalk, as on most Ghanaian
## roads. It runs along the X axis, centered on this node. It's visual only: you
## walk on the ground underneath, so it stays perfectly flat.

# Each layer sits a few millimetres above the one below so they don't flicker.
const ROAD_HEIGHT := 0.01
const TOP_LAYER_HEIGHT := 0.02
const GUTTER_WIDTH := 0.35

@export var length := 80.0:
	set(value):
		length = value
		_rebuild()
@export var road_width := 8.0:
	set(value):
		road_width = value
		_rebuild()
@export var sidewalk_width := 2.0:
	set(value):
		sidewalk_width = value
		_rebuild()
@export var dash_length := 2.5:
	set(value):
		dash_length = value
		_rebuild()
@export var dash_gap := 2.5:
	set(value):
		dash_gap = value
		_rebuild()
@export var line_width := 0.15:
	set(value):
		line_width = value
		_rebuild()

# Holds the generated pieces. It's an "internal" child: built in code, never
# saved into the scene file, and rebuilt whenever a setting changes.
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

	_add_strip(0.0, 0.0, length, road_width, ROAD_HEIGHT, Palette.ColorName.ASPHALT)

	var sidewalk_z := (road_width + sidewalk_width) / 2.0
	_add_strip(0.0, -sidewalk_z, length, sidewalk_width, TOP_LAYER_HEIGHT, Palette.ColorName.CONCRETE)
	_add_strip(0.0, sidewalk_z, length, sidewalk_width, TOP_LAYER_HEIGHT, Palette.ColorName.CONCRETE)
	var gutter_z := road_width / 2.0 + sidewalk_width + GUTTER_WIDTH / 2.0
	for side in [-1.0, 1.0]:
		_add_strip(0.0, side * gutter_z, length, GUTTER_WIDTH, TOP_LAYER_HEIGHT, Palette.ColorName.GUTTER)
		_add_strip(0.0, side * (gutter_z + GUTTER_WIDTH / 2.0 + 0.04), length, 0.08, TOP_LAYER_HEIGHT,
				Palette.ColorName.CONCRETE) # the gutter's concrete lip

	# Center the row of dashes along the road.
	var step := dash_length + dash_gap
	var count := floori((length + dash_gap) / step)
	var first_x := -(count * step - dash_gap) / 2.0 + dash_length / 2.0
	for i in count:
		_add_strip(first_x + i * step, 0.0, dash_length, line_width, TOP_LAYER_HEIGHT,
				Palette.ColorName.ROAD_MARKING)


func _add_strip(x: float, z: float, strip_length: float, strip_width: float, height: float,
		color_name: Palette.ColorName) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(strip_length, strip_width)
	var strip := MeshInstance3D.new()
	strip.mesh = plane
	strip.material_override = Palette.material(color_name)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	strip.position = Vector3(x, height, z)
	_pieces.add_child(strip)
