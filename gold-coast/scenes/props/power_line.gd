@tool
class_name PowerLine
extends StaticBody3D
## Wooden electricity poles along the road, with wires sagging between them (and
## a tangle of old wire at one pole, as on any Ghanaian street) and an orange
## street lamp on each pole that comes on at night. The poles are solid.
## The line runs along +X from this node.

## How many poles, and how far apart they are, in metres.
@export var poles := 7:
	set(value):
		poles = value
		_rebuild()
@export var spacing := 11.0:
	set(value):
		spacing = value
		_rebuild()

const HEIGHT := 6.0
## The lamps glow from dusk until dawn (minutes after midnight).
const LAMPS_ON := 18.25 * 60.0
const LAMPS_OFF := 6.25 * 60.0
const LAMP_ENERGY := 2.6

var _lamps: Array[OmniLight3D] = []
var _bulb_material: StandardMaterial3D
var _lit := -1.0
# Everything this script made (internal children, not saved in scenes).
var _generated: Array[Node] = []


func _ready() -> void:
	_rebuild()
	if not Engine.is_editor_hint():
		GameState.time_changed.connect(_on_time_changed)


## Whether the street lamps are on.
func lamps_on() -> bool:
	return _lit > 0.5


func _on_time_changed(_day: int, minutes: float) -> void:
	var night := minutes >= LAMPS_ON or minutes < LAMPS_OFF
	var lit := 1.0 if night else 0.0
	if lit == _lit:
		return
	_lit = lit
	for lamp in _lamps:
		lamp.light_energy = LAMP_ENERGY * lit
		lamp.visible = night
	_bulb_material.emission_energy_multiplier = 3.0 * lit


func _rebuild() -> void:
	if not is_node_ready():
		return
	for node in _generated:
		node.free()
	_generated.clear()
	_lamps.clear()
	_bulb_material = StandardMaterial3D.new()
	_bulb_material.albedo_color = Palette.color(Palette.ColorName.PAPER)
	_bulb_material.emission_enabled = true
	_bulb_material.emission = Palette.color(Palette.ColorName.KENTE_GOLD)
	_bulb_material.emission_energy_multiplier = 0.0
	var wood := Palette.ColorName.WOOD_DARK
	var wire := Palette.ColorName.PHONE_BEZEL
	for i in poles:
		var x := i * spacing
		_add(Shapes.box(Vector3(0.18, HEIGHT, 0.18), Vector3(x, HEIGHT / 2.0, 0), wood))
		_add(Shapes.box(Vector3(0.12, 0.12, 1.5), Vector3(x, HEIGHT - 0.35, 0), wood)) # crossarm
		for z in [-0.6, 0.0, 0.6]:
			_add(Shapes.box(Vector3(0.06, 0.1, 0.06), Vector3(x, HEIGHT - 0.24, z), Palette.ColorName.PAPER)) # insulators
		# The street lamp, on an arm reaching over the road (-Z).
		_add(Shapes.box(Vector3(0.06, 0.06, 1.1), Vector3(x, HEIGHT - 1.3, -0.55), Palette.ColorName.ZINC_DARK))
		_add(Shapes.box(Vector3(0.3, 0.1, 0.42), Vector3(x, HEIGHT - 1.36, -1.1), Palette.ColorName.ZINC_DARK))
		var bulb := Shapes.box(Vector3(0.22, 0.05, 0.3), Vector3(x, HEIGHT - 1.43, -1.1), Palette.ColorName.PAPER)
		bulb.material_override = _bulb_material
		_add(bulb)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, HEIGHT - 1.7, -1.1)
		lamp.light_color = Palette.color(Palette.ColorName.KELEWELE_ORANGE)
		lamp.omni_range = 11.0
		lamp.omni_attenuation = 1.4
		lamp.light_energy = 0.0
		lamp.visible = false
		_add(lamp)
		_lamps.append(lamp)
		_add(Shapes.solid_box(Vector3(0.24, HEIGHT, 0.24), Vector3(x, HEIGHT / 2.0, 0)))
		# Wires sagging to the next pole.
		if i < poles - 1:
			for z in [-0.6, 0.0, 0.6]:
				_add_wire(Vector3(x, HEIGHT - 0.22, z), Vector3(x + spacing, HEIGHT - 0.22, z), 0.55, wire)
	# A tangle of old wire looped round the third pole.
	var tangle_x := spacing * mini(2, poles - 1)
	for i in 3:
		var loop := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.22 + i * 0.06
		torus.outer_radius = 0.25 + i * 0.06
		loop.mesh = torus
		loop.material_override = Palette.material(wire)
		loop.position = Vector3(tangle_x + 0.15, HEIGHT - 0.9 - i * 0.25, 0.1)
		loop.rotation = Vector3(0.4 * i, 0.0, 1.2 + 0.3 * i)
		_add(loop)
	_lit = -1.0
	if not Engine.is_editor_hint():
		_on_time_changed(GameState.day, GameState.minutes) # the lamps match the time of day


# A wire hanging from `from` to `to`, sagging `sag` metres in the middle (drawn
# as short straight pieces along the curve).
func _add_wire(from: Vector3, to: Vector3, sag: float, color: Palette.ColorName) -> void:
	var pieces := 6
	for i in pieces:
		var a := _wire_point(from, to, sag, float(i) / pieces)
		var b := _wire_point(from, to, sag, float(i + 1) / pieces)
		var piece := Shapes.box(Vector3(0.025, 0.025, a.distance_to(b)), (a + b) / 2.0, color)
		piece.basis = Basis.looking_at(b - a, Vector3.UP)
		_add(piece)


func _wire_point(from: Vector3, to: Vector3, sag: float, t: float) -> Vector3:
	return from.lerp(to, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)


func _add(node: Node3D) -> void:
	add_child(node, false, Node.INTERNAL_MODE_FRONT)
	_generated.append(node)
