@tool
class_name Chicken
extends Node3D
## A chicken pecking about in the yard: it struts a few steps, pecks at the
## ground in quick little bobs, and now and then clucks. It's built from simple
## shapes, with its head at -Z, and keeps to its patch of yard.

## How far it wanders from where it starts, along X and Z, in metres.
@export var area := Vector2(3.0, 3.0)
## Its feathers.
@export var feathers := Palette.ColorName.PAPER:
	set(value):
		feathers = value
		_rebuild()

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _walking := false
var _pecking := false
var _head: Node3D
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
	_bubble.height = 0.6
	_bubble.visible = false
	layer.add_child(_bubble)
	if GameState.town_life:
		_scratch_about()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _walking:
		var gap := _target - global_position
		gap.y = 0.0
		if gap.length() < 0.05:
			_walking = false
		else:
			global_position += gap.normalized() * 0.7 * delta
			rotation.y = atan2(-gap.x, -gap.z)
			_pieces.position.y = absf(sin(Time.get_ticks_msec() / 70.0)) * 0.02 # a bobbing strut
	# Quick pecks at the ground.
	var peck := maxf(0.0, sin(Time.get_ticks_msec() / 90.0)) if _pecking else 0.0
	_head.rotation.x = -1.1 * peck


## Clucks, in a small speech bubble.
func cluck() -> void:
	_bubble.say(["Kok kok!", "Kok-ko-kooo!"].pick_random(), true)


## Its speech bubble (for tests).
func get_bubble() -> SpeechBubble:
	return _bubble


func _scratch_about() -> void:
	while is_inside_tree():
		_target = _home + Vector3(randf_range(-area.x, area.x) / 2.0, 0.0, randf_range(-area.y, area.y) / 2.0)
		_pecking = false
		_walking = true
		while _walking:
			await get_tree().process_frame
		_pecking = true
		if randf() < 0.15:
			cluck()
		await get_tree().create_timer(randf_range(1.5, 4.0), false).timeout


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _pieces != null:
		_pieces.free()
	_pieces = Node3D.new()
	add_child(_pieces, false, Node.INTERNAL_MODE_FRONT)
	_pieces.add_child(Shapes.sphere(0.13, Vector3(0, 0.2, 0.02), feathers, 0.9))
	var tail := Shapes.box(Vector3(0.05, 0.12, 0.1), Vector3(0, 0.29, 0.13), feathers)
	tail.rotation.x = -0.5
	_pieces.add_child(tail)
	for x in [-0.04, 0.04]:
		_pieces.add_child(Shapes.box(Vector3(0.015, 0.1, 0.015), Vector3(x, 0.05, 0), Palette.ColorName.KENTE_GOLD))
	_head = Node3D.new()
	_head.position = Vector3(0, 0.27, -0.09)
	_pieces.add_child(_head)
	_head.add_child(Shapes.sphere(0.055, Vector3(0, 0.03, -0.03), feathers))
	_head.add_child(Shapes.box(Vector3(0.02, 0.04, 0.05), Vector3(0, 0.08, -0.03), Palette.ColorName.TILE_RED)) # comb
	_head.add_child(Shapes.box(Vector3(0.025, 0.02, 0.04), Vector3(0, 0.03, -0.09), Palette.ColorName.KENTE_GOLD)) # beak
