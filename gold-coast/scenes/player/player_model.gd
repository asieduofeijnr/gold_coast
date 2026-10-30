class_name PlayerModel
extends Node3D
## The player's 3D character. It plays "idle" when she's standing still and
## "walk" when she's moving, and speeds the walk up or slows it down so her
## feet keep pace with the ground. It can also hold a pose, like "eat" while
## she sits and eats. When she sleeps, she lies down and "Z z z" floats above
## her; when she goes indoors, she fades away. While she's busy, a bar over her
## head shows what she's doing. With a load to carry, a headpan sits on her head
## and she walks and stands with one hand steadying it ("carry", "carry_idle").
## A gold pin with a black star floats over her head, so you can always tell
## her from the townspeople.

## The speed (metres per second) her walk animation was made for. Measured
## from the animation in Blender.
@export var walk_animation_speed := 1.7
## Below this speed she counts as standing still.
@export var walk_threshold := 0.2
## How long the change between standing and walking takes, in seconds.
@export var blend_time := 0.2
## How long changing into or out of a pose (like sitting down) takes, in seconds.
@export var pose_blend_time := 0.35
## How long lying down or getting up takes, in seconds.
@export var lie_down_time := 0.6
## How high above her head bone the headpan sits, in metres: on top of her duku.
@export var head_pan_height := 0.34
## How high over her feet the pin floats, in metres, and how high with a load on her head.
@export var marker_height := 2.1
@export var marker_height_carrying := 2.45

## How fast she's moving, in metres per second. The player script sets this.
var move_speed := 0.0
## Whether she's asleep. The player script sets this.
var sleeping := false:
	set(value):
		if value != sleeping:
			sleeping = value
			_lie_down(value)
## An animation to hold instead of standing or walking, like "eat". Empty for
## none. The player script sets this.
var pose := &""
## Whether she's indoors (asleep in her bed at home, or at a class), out of
## sight. The player script sets this.
var inside := false:
	set(value):
		if value != inside:
			inside = value
			_go_inside(value)
## What she's busy doing, like "Eating waakye", or "" for nothing. It shows over
## her head. The player script sets this.
var activity := "":
	set(value):
		if value != activity:
			activity = value
			_show_activity()
## How much of her activity is done, from 0 to 1. The player script sets this.
var activity_progress := 0.0:
	set(value):
		activity_progress = value
		if _activity_bar != null:
			_activity_bar.progress = value
## The load she's carrying on her head (a Delivery), or null. Its goods show in
## the headpan. The player script sets this.
var headload: Delivery:
	set(value):
		if value != headload:
			headload = value
			_show_headload()

var _lie_tween: Tween
var _fade_tween: Tween
var _lying := 0.0
var _zzz: Label3D
var _activity_bar: ActivityBar
var _marker: PlayerMarker
var _head_pan: HeadPan
var _meshes: Array[Node] = []

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer")
@onready var _character: Node3D = $Character
# How the character stands normally (turned to face the way she walks).
@onready var _standing: Transform3D = _character.transform


func _ready() -> void:
	# The animations should repeat forever. The file doesn't store that, so
	# it's set here.
	for animation_name in animation_player.get_animation_list():
		animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	animation_player.play("idle")
	_meshes = _character.find_children("*", "MeshInstance3D")
	for body: MeshInstance3D in _meshes:
		CharacterParts.merge(body) # one part instead of one per color: much quicker to draw
	_zzz = Shapes.name_label("Z z z")
	_zzz.position = Vector3(0.0, 0.9, 0.9)
	_zzz.visible = false
	add_child(_zzz)
	var layer := CanvasLayer.new()
	add_child(layer)
	_activity_bar = ActivityBar.new()
	_activity_bar.anchor = self
	_activity_bar.height = 2.25
	_activity_bar.visible = false
	layer.add_child(_activity_bar)
	_marker = PlayerMarker.new()
	_marker.anchor = self
	_marker.height = marker_height
	_marker.visible = false
	layer.add_child(_marker)
	# The headpan rides on her head bone, so it moves with her head as she walks.
	var on_head := BoneAttachment3D.new()
	on_head.bone_name = "Head"
	(_character.find_child("Skeleton3D") as Skeleton3D).add_child(on_head)
	_head_pan = HeadPan.new()
	_head_pan.position.y = head_pan_height # the head bone points straight up
	_head_pan.visible = false
	on_head.add_child(_head_pan)


func _process(delta: float) -> void:
	var carrying := headload != null and animation_player.has_animation(&"carry")
	if pose != &"" and not sleeping and animation_player.has_animation(pose):
		_play(pose, pose_blend_time)
		animation_player.speed_scale = 1.0
	elif move_speed > walk_threshold and not sleeping:
		_play(&"carry" if carrying else &"walk", blend_time)
		animation_player.speed_scale = move_speed / walk_animation_speed
	else:
		var walking := animation_player.current_animation in ["walk", "carry"]
		_play(&"carry_idle" if carrying else &"idle", blend_time if walking else pose_blend_time)
		animation_player.speed_scale = 0.5 if sleeping else 1.0 # slow breathing while asleep
	if _zzz.visible:
		_zzz.position.y = 0.9 + 0.08 * sin(Time.get_ticks_msec() / 400.0) # bob gently
	_update_marker()


## How far she's lying down: 0 is standing, 1 is flat on her back.
func lying() -> float:
	return _lying


## How see-through she is: 0 is solid, 1 is gone (indoors).
func faded() -> float:
	return (_meshes[0] as GeometryInstance3D).transparency if not _meshes.is_empty() else 0.0


## Whether the headpan is on her head.
func is_carrying() -> bool:
	return _head_pan.visible


## Whether the pin over her head is showing.
func is_marked() -> bool:
	return _marker.is_showing()


## The pin over her head (for tests).
func get_marker() -> PlayerMarker:
	return _marker


# The pin shows whenever she's out and about: not while she's indoors, asleep
# (the "Z z z" shows where she is), or busy (her activity bar is over her head).
func _update_marker() -> void:
	var wanted := not inside and not sleeping and activity == "" and faded() < 0.5
	if wanted != _marker.is_showing():
		if wanted:
			_marker.appear()
		else:
			_marker.disappear()
	_marker.height = marker_height_carrying if headload != null else marker_height


## The text over her head while she's busy (for tests): "" when it's hidden.
func shown_activity() -> String:
	return _activity_bar.text if _activity_bar.is_showing() else ""


func _play(animation_name: StringName, blend: float) -> void:
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name, blend)


# Tips her backwards onto her back (or stands her up again), and shows the Zs.
func _lie_down(down: bool) -> void:
	if _lie_tween != null:
		_lie_tween.kill()
	_lie_tween = create_tween()
	_lie_tween.tween_method(_set_lying, lying(), 1.0 if down else 0.0, lie_down_time)
	_zzz.visible = down


func _set_lying(amount: float) -> void:
	_lying = amount
	# Turn backwards around the left-right axis, and lift her a little so she
	# lies on the ground rather than in it.
	var tip := Basis(Vector3.RIGHT, amount * PI / 2.0)
	_character.transform = Transform3D(tip * _standing.basis, Vector3(0.0, 0.14 * amount, 0.0))


# Fades her out as she goes indoors, or back in as she comes out.
func _go_inside(indoors: bool) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_character.visible = true
	_fade_tween.tween_method(_set_see_through, faded(), 1.0 if indoors else 0.0, 0.4)
	if indoors:
		_fade_tween.tween_callback(_character.hide)


func _set_see_through(amount: float) -> void:
	for mesh: GeometryInstance3D in _meshes:
		mesh.transparency = amount


# Puts the headpan, piled with her load's goods, on her head with a little pop
# (or takes it away).
func _show_headload() -> void:
	if _head_pan == null:
		return
	_head_pan.visible = headload != null
	if headload != null:
		_head_pan.goods_color = headload.color
		_head_pan.scale = Vector3.ONE * 0.3
		create_tween().tween_property(_head_pan, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK) \
				.set_ease(Tween.EASE_OUT)


func _show_activity() -> void:
	if _activity_bar == null:
		return
	if activity != "":
		_activity_bar.text = activity
		_activity_bar.appear()
	else:
		_activity_bar.disappear()
