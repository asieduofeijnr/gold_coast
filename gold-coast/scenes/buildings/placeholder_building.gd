@tool
class_name PlaceholderBuilding
extends StaticBody3D
## A simple stand-in building: walls with a door and windows, a roof, and a
## name sign. It's solid, so the player can't walk through it. A real model
## from Blender replaces it later.
##
## This one scene makes every building: change the settings below in the
## Inspector. The front (with the door) faces +Z.

enum RoofStyle { FLAT, GABLE }

const FLOOR_HEIGHT := 3.0
const ROOF_OVERHANG := 0.3
const FLAT_ROOF_THICKNESS := 0.25
const WINDOW_SPACING := 2.4
const POLYTANK_RADIUS := 0.6
const POLYTANK_HEIGHT := 1.3
const SIGN_GAP := 0.8

## The name on the sign above the building.
@export var building_name := "Building":
	set(value):
		building_name = value
		_rebuild()
## Width (x), wall height (y), and depth (z), in metres.
@export var size := Vector3(6.0, 3.0, 5.0):
	set(value):
		size = value
		_rebuild()
## The wall color, from the palette.
@export var wall_color := Palette.ColorName.WALL_CREAM:
	set(value):
		wall_color = value
		_rebuild()
## FLAT gives a concrete slab (with a water tank on bigger buildings). GABLE
## gives a pointed zinc roof.
@export var roof_style := RoofStyle.FLAT:
	set(value):
		roof_style = value
		_rebuild()

## The walls and the collision shape. This script makes both from `size`, so
## what you see is always what you bump into.
var walls: MeshInstance3D
var collision: CollisionShape3D

# Everything this script made, so it can be cleared and rebuilt. These are
# "internal" children: they don't show in the scene tree and aren't saved.
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()

	walls = _add(Shapes.box(size, Vector3(0.0, size.y / 2.0, 0.0), wall_color)) as MeshInstance3D
	collision = _add(Shapes.solid_box(size, Vector3(0.0, size.y / 2.0, 0.0))) as CollisionShape3D
	_build_front()
	_build_sign(_build_roof())


## A door (or a serving hatch on small kiosks) and rows of windows on the front.
func _build_front() -> void:
	var front := size.z / 2.0
	if size.x < 4.0:
		_add(Shapes.box(Vector3(size.x * 0.6, 0.7, 0.08), Vector3(0.0, 1.3, front), Palette.ColorName.DARK_BROWN))
		return
	_add(Shapes.box(Vector3(1.0, 2.1, 0.08), Vector3(0.0, 1.05, front), Palette.ColorName.DARK_BROWN))

	# Windows come in pairs either side of the middle, plus one in the middle
	# on upper floors, where there's no door.
	var pair_offsets: Array[float] = []
	var offset := 1.6
	while offset + 0.5 <= size.x / 2.0 - 0.4:
		pair_offsets.append(offset)
		offset += WINDOW_SPACING
	for floor_index in maxi(1, floori(size.y / FLOOR_HEIGHT)):
		var xs: Array[float] = []
		for x in pair_offsets:
			xs.append_array([-x, x])
		if floor_index > 0:
			xs.append(0.0)
		for x in xs:
			var at := Vector3(x, floor_index * FLOOR_HEIGHT + 1.7, front)
			_add(Shapes.box(Vector3(1.0, 1.0, 0.06), at, Palette.ColorName.ASPHALT))


## Builds the roof and returns the height of its highest point.
func _build_roof() -> float:
	var width := size.x + ROOF_OVERHANG * 2.0
	var depth := size.z + ROOF_OVERHANG * 2.0
	if roof_style == RoofStyle.GABLE:
		# A triangular prism (a tent shape) with its ridge along the width.
		var height := minf(depth * 0.3, 2.0)
		var prism := PrismMesh.new()
		prism.size = Vector3(depth, height, width)
		var roof := MeshInstance3D.new()
		roof.mesh = prism
		roof.material_override = Palette.material(Palette.ColorName.RUST_ROOF)
		roof.rotation.y = PI / 2.0
		roof.position.y = size.y + height / 2.0
		_add(roof)
		return size.y + height

	var slab := Vector3(width, FLAT_ROOF_THICKNESS, depth)
	_add(Shapes.box(slab, Vector3(0.0, size.y + FLAT_ROOF_THICKNESS / 2.0, 0.0), Palette.ColorName.CONCRETE))
	var top := size.y + FLAT_ROOF_THICKNESS
	if size.x < 6.0:
		return top
	# A black polytank (water tank) near the back corner, like on many Ghanaian roofs.
	var tank_mesh := CylinderMesh.new()
	tank_mesh.top_radius = POLYTANK_RADIUS
	tank_mesh.bottom_radius = POLYTANK_RADIUS
	tank_mesh.height = POLYTANK_HEIGHT
	var tank := MeshInstance3D.new()
	tank.mesh = tank_mesh
	tank.material_override = Palette.material(Palette.ColorName.DARK_BROWN)
	tank.position = Vector3(size.x / 2.0 - 1.2, top + POLYTANK_HEIGHT / 2.0, -size.z / 2.0 + 1.2)
	_add(tank)
	return top + POLYTANK_HEIGHT


## A name label floating above the roof that always turns to face the camera.
func _build_sign(roof_top: float) -> void:
	var label := Shapes.name_label(building_name)
	label.position.y = roof_top + SIGN_GAP
	_add(label)


func _add(node: Node3D) -> Node3D:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
	return node
