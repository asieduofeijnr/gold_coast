@tool
class_name Flagpole
extends StaticBody3D
## A white flagpole with Ghana's flag flying from the top: red, gold, and green,
## with the black star in the middle of the gold. The flag waves gently in the
## breeze. The pole stands on a little concrete base, and it's solid.

const HEIGHT := 5.5
const FLAG := Vector2(1.5, 1.0)
## The flag is cut into upright strips, so it can ripple.
const STRIPS := 6
const STAR_RADIUS := 0.16

var _strips: Array[Node3D] = []
var _star: MeshInstance3D
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()


func _process(_delta: float) -> void:
	if _strips.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	for i in _strips.size():
		var reach := float(i + 1) / _strips.size() # the free end waves the most
		_strips[i].position.z = sin(t * 2.6 - i * 0.9) * 0.08 * reach
		_strips[i].rotation.y = cos(t * 2.6 - i * 0.9) * 0.3 * reach
	@warning_ignore("integer_division")
	var middle := _strips.size() / 2 # the star sits between the two middle strips
	_star.position.z = (_strips[middle - 1].position.z + _strips[middle].position.z) / 2.0


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	_strips.clear()
	_add(Shapes.box(Vector3(0.5, 0.25, 0.5), Vector3(0.0, 0.125, 0.0), Palette.ColorName.CONCRETE))
	_add(Shapes.cylinder(0.035, 0.055, HEIGHT, Vector3(0.0, HEIGHT / 2.0, 0.0), Palette.ColorName.PAPER))
	_add(Shapes.sphere(0.07, Vector3(0.0, HEIGHT + 0.05, 0.0), Palette.ColorName.KENTE_GOLD))
	var flag_middle := HEIGHT - 0.1 - FLAG.y / 2.0
	var strip_width := FLAG.x / STRIPS
	var colors := [Palette.ColorName.TILE_RED, Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN]
	for i in STRIPS:
		var strip := Node3D.new()
		strip.position = Vector3(0.05 + strip_width * (i + 0.5), flag_middle, 0.0)
		for band in 3:
			strip.add_child(Shapes.box(Vector3(strip_width + 0.006, FLAG.y / 3.0, 0.015),
					Vector3(0.0, FLAG.y / 3.0 * (1 - band), 0.0), colors[band]))
		_add(strip)
		_strips.append(strip)
	_star = MeshInstance3D.new()
	_star.mesh = _star_mesh(STAR_RADIUS)
	_star.material_override = Palette.material(Palette.ColorName.SHITO_BLACK)
	_star.position = Vector3(0.05 + FLAG.x / 2.0, flag_middle, 0.0)
	_add(_star)
	_add(Shapes.solid_box(Vector3(0.5, 1.2, 0.5), Vector3(0.0, 0.6, 0.0)))


# A flat five-pointed star facing both ways (+Z and -Z), just thicker than the flag.
func _star_mesh(radius: float) -> ArrayMesh:
	var points: Array[Vector3] = []
	for i in 10:
		var angle := PI / 2.0 + i * PI / 5.0
		points.append(Vector3(cos(angle), sin(angle), 0.0) * radius * (1.0 if i % 2 == 0 else 0.4))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [1.0, -1.0]:
		var face := Vector3(0.0, 0.0, 0.011 * side)
		for i in 10:
			var a := points[i] + face
			var b := points[(i + 1) % 10] + face
			# Godot draws the side of a triangle whose corners go clockwise.
			for corner in ([face, b, a] if side > 0.0 else [face, a, b]):
				surface.add_vertex(corner)
	surface.generate_normals()
	return surface.commit()


func _add(node: Node) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
