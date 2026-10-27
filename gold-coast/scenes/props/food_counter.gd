@tool
class_name FoodCounter
extends StaticBody3D
## The roadside serving table in front of the chop bar: big aluminium pots of
## food with their lids on (one open, full of waakye) and a stack of clean
## bowls. It's solid. The cloth hangs down its front (+Z), where customers stand.

## How big the table is, in metres.
const TABLE_SIZE := Vector3(1.5, 0.78, 0.6)

# Everything this script made (internal children, not saved in scenes).
var _pieces: Node3D
var _solid: CollisionShape3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _pieces != null:
		_pieces.free()
		_solid.free()
	_pieces = Node3D.new()
	add_child(_pieces, false, Node.INTERNAL_MODE_FRONT)
	_solid = Shapes.solid_box(TABLE_SIZE, Vector3(0, TABLE_SIZE.y / 2.0, 0))
	add_child(_solid, false, Node.INTERNAL_MODE_FRONT)

	var half := TABLE_SIZE / 2.0
	var top := TABLE_SIZE.y
	_pieces.add_child(Shapes.box(Vector3(TABLE_SIZE.x, 0.05, TABLE_SIZE.z), Vector3(0, top - 0.025, 0),
			Palette.ColorName.WOOD_LIGHT))
	# A cloth hanging down the front, so you can't see under the table.
	_pieces.add_child(Shapes.box(Vector3(TABLE_SIZE.x, top - 0.05, 0.02), Vector3(0, (top - 0.05) / 2.0, half.z - 0.01),
			Palette.ColorName.TILE_RED))
	for x in [-1, 1]:
		_pieces.add_child(Shapes.box(Vector3(0.06, top - 0.05, 0.06),
				Vector3(x * (half.x - 0.05), (top - 0.05) / 2.0, -half.z + 0.05), Palette.ColorName.WOOD_DARK))

	# Three big pots: two with lids on, one open and full.
	var pots := [[-0.48, 0.2, 0.3, true], [0.0, 0.23, 0.34, false], [0.47, 0.18, 0.26, true]]
	for pot: Array in pots:
		var x: float = pot[0]
		var radius: float = pot[1]
		var height: float = pot[2]
		_pieces.add_child(Shapes.cylinder(radius, radius * 0.92, height, Vector3(x, top + height / 2.0, -0.02),
				Palette.ColorName.ALUMINIUM))
		if pot[3]:
			_pieces.add_child(Shapes.cylinder(radius * 0.96, radius * 1.02, 0.04, Vector3(x, top + height + 0.02, -0.02),
					Palette.ColorName.ALUMINIUM))
			_pieces.add_child(Shapes.sphere(0.035, Vector3(x, top + height + 0.06, -0.02), Palette.ColorName.WOOD_DARK))
		else:
			_pieces.add_child(Shapes.sphere(radius * 0.9, Vector3(x, top + height - 0.02, -0.02),
					Palette.ColorName.WAAKYE_BROWN, 0.3))

	# A stack of clean bowls at the front.
	for i in 4:
		var bowl := FoodBowl.new()
		bowl.position = Vector3(0.3 - i * 0.01, top + i * 0.03, half.z - 0.12)
		_pieces.add_child(bowl)
