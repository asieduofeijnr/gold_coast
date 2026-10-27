@tool
class_name HeadPan
extends Node3D
## A kayayo's big aluminium headpan, piled with goods, sitting on a cloth ring
## (the cushion head porters carry it on). Its bottom is at its origin.

const RADIUS := 0.3
const DEPTH := 0.13
const RING := 0.05 # how thick the cloth ring is

## The color of the goods piled in it.
@export var goods_color := Palette.ColorName.LIGHT_SOUP:
	set(value):
		goods_color = value
		_rebuild()
## Whether it sits on a cloth ring, as it does on her head.
@export var cloth_ring := true:
	set(value):
		cloth_ring = value
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

	var bottom := 0.0
	if cloth_ring:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.06
		torus.outer_radius = 0.12
		torus.rings = 12
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = Palette.material(Palette.ColorName.CLOTH_OCHRE)
		ring.position.y = RING / 2.0
		_pieces.add_child(ring)
		bottom = RING
	_pieces.add_child(Shapes.cylinder(RADIUS, RADIUS * 0.55, DEPTH, Vector3(0, bottom + DEPTH / 2.0, 0),
			Palette.ColorName.ALUMINIUM))
	var top := bottom + DEPTH
	_pieces.add_child(Shapes.sphere(RADIUS * 0.88, Vector3(0, top, 0), goods_color, 0.42))
	# A few round pieces on top (tomatoes, oranges, yams...) so it reads as a pile.
	for i in 6:
		var angle := TAU * i / 6.0
		_pieces.add_child(Shapes.sphere(0.065, Vector3(cos(angle) * 0.13, top + 0.08, sin(angle) * 0.13), goods_color))
	_pieces.add_child(Shapes.sphere(0.07, Vector3(0, top + 0.15, 0), goods_color))
