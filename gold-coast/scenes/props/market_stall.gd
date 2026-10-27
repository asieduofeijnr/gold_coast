@tool
class_name MarketStall
extends StaticBody3D
## A market stall: a wooden table piled with produce, and a big umbrella behind
## it shading the seller, who stands between them. Customers stand at its front
## (+Z). It's solid, so nobody walks through the table or round the back.
## The umbrella stands behind the seller rather than over the table, so it
## never hides her from the camera. When it hides the player (walking behind
## the stall), it fades (see SeeThrough). At night the stall is closed: the
## goods are packed away and the umbrella is folded.

const TABLE := Vector3(1.6, 0.75, 0.75)
## Where the seller stands, behind the table.
const SELLER_SPOT := Vector3(0.0, 0.0, -0.62)

## The color of the produce on the table.
@export var produce := Palette.ColorName.LIGHT_SOUP:
	set(value):
		produce = value
		_rebuild()
## A second kind of produce for the middle pile.
@export var produce_middle := Palette.ColorName.KELEWELE_ORANGE:
	set(value):
		produce_middle = value
		_rebuild()
## The umbrella's main color and the color of its band.
@export var umbrella := Palette.ColorName.TILE_RED:
	set(value):
		umbrella = value
		_rebuild()
@export var umbrella_band := Palette.ColorName.PAPER:
	set(value):
		umbrella_band = value
		_rebuild()
## A cloth seller's stall: folded kente and wax-print cloth in bright colors,
## instead of piles of produce.
@export var cloth := false:
	set(value):
		cloth = value
		_rebuild()
## Whoever sells here (so shoppers can haggle with them).
@export var seller: Node3D

## How see-through the umbrella is, from 0 (solid) to 1 (invisible). SeeThrough
## raises it while the umbrella stands between the camera and the player.
var fade := 0.0:
	set(value):
		fade = value
		for mesh in _umbrella:
			mesh.transparency = value
## Whether it's packed up for the night: nothing on the table, and the umbrella
## folded (the Market closes it when the seller goes home).
var closed := false:
	set(value):
		closed = value
		_show_open_or_closed()

# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []
var _umbrella: Array[MeshInstance3D] = []
# The goods on the table, the open umbrella's canopy (and its copy for seeing
# only), and the umbrella folded up.
var _goods: Array[Node3D] = []
var _canopy: Array[Node3D] = []
var _canopy_view: StaticBody3D
var _folded: MeshInstance3D


func _ready() -> void:
	add_to_group(SeeThrough.GROUP)
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	_umbrella.clear()
	_goods.clear()
	_canopy.clear()

	var half := TABLE / 2.0
	_add(Shapes.box(Vector3(TABLE.x, 0.05, TABLE.z), Vector3(0, TABLE.y - 0.025, 0), Palette.ColorName.WOOD_LIGHT))
	for x in [-1, 1]:
		for z in [-1, 1]:
			_add(Shapes.box(Vector3(0.06, TABLE.y - 0.05, 0.06),
					Vector3(x * (half.x - 0.08), (TABLE.y - 0.05) / 2.0, z * (half.z - 0.08)), Palette.ColorName.WOOD_DARK))
	if cloth:
		_add_cloth()
	# Three neat piles of produce, the way sellers stack them.
	for pile in (0 if cloth else 3):
		var color := produce_middle if pile == 1 else produce
		var center := Vector3(-0.5 + pile * 0.5, TABLE.y + 0.07, 0.05)
		for layer in 3:
			var count: int = [6, 3, 1][layer]
			var spread: float = [0.13, 0.07, 0.0][layer]
			for i in count:
				var angle := TAU * i / count + layer
				_add_goods(Shapes.sphere(0.07, center + Vector3(cos(angle) * spread, layer * 0.1, sin(angle) * spread), color))
	# The umbrella, behind the seller.
	var pole := Vector3(0.0, 0.0, -1.15)
	_umbrella.append(Shapes.box(Vector3(0.05, 2.55, 0.05), pole + Vector3(0, 1.275, 0), Palette.ColorName.ZINC_DARK))
	_canopy.append(Shapes.cylinder(0.03, 1.1, 0.42, pole + Vector3(0, 2.55, 0), umbrella))
	_canopy.append(Shapes.cylinder(0.03, 0.6, 0.23, pole + Vector3(0, 2.67, 0), umbrella_band))
	# Folded up for the night: the cloth gathered round the top of the pole.
	_folded = Shapes.cylinder(0.04, 0.12, 0.95, pole + Vector3(0, 2.15, 0), umbrella)
	for piece in _canopy:
		_umbrella.append(piece as MeshInstance3D)
	_umbrella.append(_folded)
	for piece in _umbrella:
		_add(piece)
	# An invisible copy of the canopy, for seeing only (like a building's roof
	# copy), so SeeThrough can tell when the umbrella is in the way.
	var canopy := StaticBody3D.new()
	canopy.collision_layer = Building.VIEW_ONLY_LAYER
	canopy.collision_mask = 0
	var shape := CylinderShape3D.new()
	shape.radius = 1.1
	shape.height = 0.42
	var solid := CollisionShape3D.new()
	solid.shape = shape
	solid.position = pole + Vector3(0, 2.55, 0)
	canopy.add_child(solid)
	_add(canopy)
	_canopy_view = canopy
	# Solid over the table, the seller's spot, and the pole.
	_add(Shapes.solid_box(Vector3(TABLE.x, 1.0, 1.6), Vector3(0, 0.5, -0.43)))
	_show_open_or_closed()


## Whether its goods are out on the table, and its umbrella is up (for tests).
func goods_out() -> bool:
	return not _goods.is_empty() and _goods[0].visible


func umbrella_up() -> bool:
	return not _canopy.is_empty() and _canopy[0].visible


## Where a customer stands at this stall, in the world.
func front_spot() -> Vector3:
	return to_global(Vector3(0.0, 0.0, TABLE.z / 2.0 + 0.55))


# Stacks of folded cloth: kente golds, greens, and reds, and wax-print blues and oranges.
func _add_cloth() -> void:
	var colors := [Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN, Palette.ColorName.TILE_RED,
			Palette.ColorName.ENAMEL_RIM, Palette.ColorName.KELEWELE_ORANGE, Palette.ColorName.PAPER]
	for stack in 4:
		for layer in 4:
			var color: Palette.ColorName = colors[(stack * 2 + layer) % colors.size()]
			_add_goods(Shapes.box(Vector3(0.3, 0.06, 0.42), Vector3(-0.54 + stack * 0.36, TABLE.y + 0.03 + layer * 0.062, 0.03),
					color))


# Open: the goods are out and the umbrella is up. Closed: the table is bare and
# the umbrella is folded (and no longer in anyone's way).
func _show_open_or_closed() -> void:
	if _folded == null:
		return
	for piece in _goods:
		piece.visible = not closed
	for piece in _canopy:
		piece.visible = not closed
	_folded.visible = closed
	_canopy_view.collision_layer = 0 if closed else Building.VIEW_ONLY_LAYER


func _add_goods(node: Node3D) -> void:
	_add(node)
	_goods.append(node)


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
