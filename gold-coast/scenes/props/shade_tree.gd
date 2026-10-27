@tool
class_name ShadeTree
extends StaticBody3D
## A big mango tree, the kind that shades a schoolyard: a thick trunk, a couple
## of branches, and a wide, round canopy of dark leaves. The trunk is solid.
## When the canopy hides the player, it fades (see SeeThrough).

## How far the canopy spreads from the trunk, in metres.
@export var canopy_radius := 2.4:
	set(value):
		canopy_radius = value
		_rebuild()
## How tall the trunk is before the canopy starts, in metres.
@export var trunk_height := 2.4:
	set(value):
		trunk_height = value
		_rebuild()

## How see-through the canopy is, from 0 (solid) to 1 (invisible). SeeThrough
## raises it while the canopy stands between the camera and the player.
var fade := 0.0:
	set(value):
		fade = value
		for mesh in _canopy:
			mesh.transparency = value

var _canopy: Array[MeshInstance3D] = []
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(SeeThrough.GROUP)
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	_canopy.clear()
	_add(Shapes.cylinder(0.2, 0.3, trunk_height + 0.6, Vector3(0.0, (trunk_height + 0.6) / 2.0, 0.0), Palette.ColorName.WOOD_DARK))
	for side in [-1.0, 1.0]:
		var branch := Shapes.cylinder(0.07, 0.12, 1.4, Vector3(side * 0.45, trunk_height + 0.35, 0.1), Palette.ColorName.WOOD_DARK)
		branch.rotation.z = -side * 0.75
		_add(branch)
	# The canopy: one big mound of leaves with smaller clumps around it.
	var top := trunk_height + canopy_radius * 0.45
	var clumps := [
		[Vector3.ZERO, 0.8, Palette.ColorName.PALM_GREEN],
		[Vector3(0.62, -0.12, 0.3), 0.5, Palette.ColorName.BAR_GREEN],
		[Vector3(-0.6, -0.1, -0.25), 0.52, Palette.ColorName.BAR_GREEN],
		[Vector3(-0.2, -0.15, 0.62), 0.48, Palette.ColorName.PALM_GREEN],
		[Vector3(0.25, 0.05, -0.62), 0.46, Palette.ColorName.PALM_GREEN],
		[Vector3(0.1, 0.32, 0.05), 0.5, Palette.ColorName.BAR_GREEN],
	]
	for clump: Array in clumps:
		var leaves := Shapes.sphere(canopy_radius * clump[1], Vector3(0.0, top, 0.0) + clump[0] * canopy_radius, clump[2], 0.75)
		_add(leaves)
		_canopy.append(leaves)
	# An invisible copy of the canopy, for seeing only (like a building's roof
	# copy), so SeeThrough can tell when it's in the way.
	var view := StaticBody3D.new()
	view.collision_layer = Building.VIEW_ONLY_LAYER
	view.collision_mask = 0
	var shape := CylinderShape3D.new()
	shape.radius = canopy_radius * 0.95
	shape.height = canopy_radius * 1.1
	var holder := CollisionShape3D.new()
	holder.shape = shape
	holder.position = Vector3(0.0, top, 0.0)
	view.add_child(holder)
	_add(view)
	_add(Shapes.solid_box(Vector3(0.65, 1.2, 0.65), Vector3(0.0, 0.6, 0.0)))


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
