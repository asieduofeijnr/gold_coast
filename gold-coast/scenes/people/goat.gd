@tool
class_name Goat
extends Node3D
## A goat wandering about, as goats do in every Ghanaian town: it ambles to a
## spot, nibbles at the ground for a while, wanders on, and now and then bleats.
## It's built from simple shapes, with its head at -Z, and its legs swing as it
## walks. It doesn't bump into anything; it keeps to its patch of open ground.

## How far it wanders from where it starts, along X and Z, in metres.
@export var area := Vector2(8.0, 6.0)
## Its coat and the color of its patches, horns, and hooves.
@export var coat := Palette.ColorName.PAPER:
	set(value):
		coat = value
		_rebuild()
@export var patches := Palette.ColorName.DARK_BROWN:
	set(value):
		patches = value
		_rebuild()
## How fast it ambles, in metres per second.
@export var walk_speed := 0.5

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _walking := false
var _grazing := false
var _legs: Array[Node3D] = []
var _head: Node3D
var _step := 0.0
var _bubble: SpeechBubble
var _pieces: Node3D


func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		return
	_home = global_position
	var layer := CanvasLayer.new()
	add_child(layer, false, Node.INTERNAL_MODE_BACK)
	_bubble = SpeechBubble.new()
	_bubble.anchor = self
	_bubble.height = 1.1
	_bubble.visible = false
	layer.add_child(_bubble)
	if GameState.town_life:
		_wander()


## Bleats, in a small speech bubble.
func bleat() -> void:
	_bubble.say("Meeeh!", true)


## Its speech bubble (for tests).
func get_bubble() -> SpeechBubble:
	return _bubble


## Whether it's on the move right now.
func is_walking() -> bool:
	return _walking


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _walking:
		var gap := _target - global_position
		gap.y = 0.0
		if gap.length() < 0.1:
			_walking = false
		else:
			global_position += gap.normalized() * walk_speed * delta
			rotation.y = lerp_angle(rotation.y, atan2(-gap.x, -gap.z), 1.0 - exp(-4.0 * delta))
			_step += delta * walk_speed * 9.0
	# Legs swing in diagonal pairs while walking, and come to rest when it stops.
	for i in _legs.size():
		var swing := sin(_step + (PI if i in [1, 2] else 0.0)) * 0.45 if _walking else 0.0
		_legs[i].rotation.x = lerpf(_legs[i].rotation.x, swing, 1.0 - exp(-12.0 * delta))
	# Head down to nibble, with a little chewing bob, or up while walking.
	var head_down := 0.9 + 0.08 * sin(Time.get_ticks_msec() / 120.0) if _grazing else 0.0
	_head.rotation.x = lerpf(_head.rotation.x, -head_down, 1.0 - exp(-6.0 * delta))


# Wander to a spot, nibble there a while, now and then bleat, and wander on.
func _wander() -> void:
	while is_inside_tree():
		_target = _home + Vector3(randf_range(-area.x, area.x) / 2.0, 0.0, randf_range(-area.y, area.y) / 2.0)
		_grazing = false
		_walking = true
		while _walking:
			await get_tree().process_frame
		_grazing = true
		if randf() < 0.3:
			bleat()
		await get_tree().create_timer(randf_range(3.0, 9.0), false).timeout


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _pieces != null:
		_pieces.free()
	_legs.clear()
	_pieces = Node3D.new()
	add_child(_pieces, false, Node.INTERNAL_MODE_FRONT)
	_pieces.add_child(Shapes.box(Vector3(0.28, 0.3, 0.68), Vector3(0, 0.55, 0), coat))
	_pieces.add_child(Shapes.box(Vector3(0.29, 0.14, 0.24), Vector3(0, 0.64, 0.12), patches)) # a patch on its back
	_pieces.add_child(Shapes.box(Vector3(0.06, 0.16, 0.05), Vector3(0, 0.74, 0.34), patches)) # tail, held up
	for x in [-0.09, 0.09]:
		for z in [-0.26, 0.26]:
			var hip := Node3D.new()
			hip.position = Vector3(x, 0.42, z)
			_pieces.add_child(hip)
			hip.add_child(Shapes.box(Vector3(0.07, 0.4, 0.07), Vector3(0, -0.2, 0), coat))
			hip.add_child(Shapes.box(Vector3(0.075, 0.06, 0.08), Vector3(0, -0.39, 0), patches)) # hoof
			_legs.append(hip)
	_head = Node3D.new()
	_head.position = Vector3(0, 0.66, -0.32) # the neck
	_pieces.add_child(_head)
	_head.add_child(Shapes.box(Vector3(0.16, 0.18, 0.3), Vector3(0, 0.08, -0.14), coat))
	_head.add_child(Shapes.box(Vector3(0.12, 0.08, 0.06), Vector3(0, 0.02, -0.08 - 0.22), patches)) # nose
	_head.add_child(Shapes.box(Vector3(0.04, 0.09, 0.03), Vector3(0, -0.06, -0.2), coat)) # beard
	for side in [-1, 1]:
		_head.add_child(Shapes.box(Vector3(0.1, 0.035, 0.05), Vector3(side * 0.12, 0.13, -0.08), coat)) # ear
		var horn := Shapes.box(Vector3(0.035, 0.13, 0.035), Vector3(side * 0.05, 0.22, -0.02), patches)
		horn.rotation.x = 0.6
		_head.add_child(horn)
