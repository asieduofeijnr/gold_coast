@tool
extends StaticBody3D
## Flat ground you can walk on, with its top surface at height 0.
## Invisible walls around the edge stop you walking off the world.

const THICKNESS := 1.0
const EDGE_WALL_HEIGHT := 4.0

## Width (x) and depth (z) of the ground, in metres.
@export var size := Vector2(80.0, 80.0):
	set(value):
		size = value
		if is_node_ready():
			_update_size()

var _edge_walls: Array[CollisionShape3D] = []

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision: CollisionShape3D = $Collision


func _ready() -> void:
	# The edge walls are made here in code ("internal" children), so they
	# don't clutter the scene tree and always match the ground's size.
	for i in 4:
		var wall := CollisionShape3D.new()
		wall.shape = BoxShape3D.new()
		add_child(wall, false, Node.INTERNAL_MODE_FRONT)
		_edge_walls.append(wall)
	_update_size()


func _update_size() -> void:
	# The mesh (what you see) and the collision (what you bump into) are
	# always kept the same size. Both are sunk so the top sits at height 0.
	var box := Vector3(size.x, THICKNESS, size.y)
	(_mesh.mesh as BoxMesh).size = box
	(_collision.shape as BoxShape3D).size = box
	_mesh.position.y = -THICKNESS / 2.0
	_collision.position.y = -THICKNESS / 2.0

	var half := size / 2.0
	var y := EDGE_WALL_HEIGHT / 2.0
	_place_wall(_edge_walls[0], Vector3(0.0, y, -half.y), Vector3(size.x, EDGE_WALL_HEIGHT, 1.0))
	_place_wall(_edge_walls[1], Vector3(0.0, y, half.y), Vector3(size.x, EDGE_WALL_HEIGHT, 1.0))
	_place_wall(_edge_walls[2], Vector3(-half.x, y, 0.0), Vector3(1.0, EDGE_WALL_HEIGHT, size.y))
	_place_wall(_edge_walls[3], Vector3(half.x, y, 0.0), Vector3(1.0, EDGE_WALL_HEIGHT, size.y))


func _place_wall(wall: CollisionShape3D, at: Vector3, wall_size: Vector3) -> void:
	wall.position = at
	(wall.shape as BoxShape3D).size = wall_size
