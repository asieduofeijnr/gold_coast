class_name Townsperson
extends Node3D
## One of the people of Gold Coast going about their day: walking about,
## waiting for the trotro, buying food, carrying loads, playing. They're only
## for show: nothing bumps into them, and they follow the walkable area's paths
## so they never walk through buildings.
##
## TownLife tells them what to do, one step at a time:
##     await person.walk_to(point)   # waits until they get there
##     person.hold(&"sit")           # holds an animation
##     person.say("Circle! Circle!")
## Children use the grown-up bodies, smaller. Like the player, they face -Z.

## Sent when they reach the place they were walking to.
signal arrived
## Sent when they've got on the trotro (see board()).
signal boarded
## Sent when the trotro has let them off (TrotroStation sends it).
signal got_off

## The group every townsperson joins (the trotro looks out for them).
const GROUP := &"townspeople"

enum Body { WOMAN, MAN, GIRL, BOY }

const WOMAN_MODEL := preload("res://art/models/characters/player_character.glb")
const MAN_MODEL := preload("res://art/models/characters/townsman.glb")
const BOY_MODEL := preload("res://art/models/characters/schoolboy.glb")
## Children are the grown-up bodies at this size.
const CHILD_SCALE := 0.62
## The speeds (metres per second) the walk and run animations were made for, at full size.
const WALK_ANIMATION_SPEED := 1.7
const RUN_ANIMATION_SPEED := 3.8
const TURN_SPEED := 8.0

## Which body they have.
@export var body := Body.WOMAN
## Their name, shown on their speech bubble.
@export var person_name := ""
## Their clothes: top (kaba or shirt), bottom (slit, trousers, or shorts), trim
## (or belt), and headwrap.
@export var top_color := Palette.ColorName.CLOTH_CREAM
@export var bottom_color := Palette.ColorName.CLOTH_MAROON
@export var trim_color := Palette.ColorName.CLOTH_OCHRE
@export var headwrap_color := Palette.ColorName.CLOTH_RED
## How fast they walk, in metres per second.
@export var walk_speed := 1.3
## How fast they run, in metres per second.
@export var run_speed := 3.0

## Whether they're on their way somewhere.
var walking := false

var _model: Node3D
var _animation_player: AnimationPlayer
var _meshes: Array[Node] = []
var _path := PackedVector3Array()
var _next_corner := 0
var _running := false
var _pose := &""
var _bubble: SpeechBubble
var _head_pan: HeadPan
var _fade_tween: Tween


func _ready() -> void:
	add_to_group(GROUP)
	var child := body == Body.GIRL or body == Body.BOY
	var model_scene: PackedScene = MAN_MODEL if body == Body.MAN else (BOY_MODEL if body == Body.BOY else WOMAN_MODEL)
	_model = model_scene.instantiate() as Node3D
	_model.rotation.y = PI # the models face +Z; turn them to face -Z, like everything else
	if child:
		_model.scale = Vector3.ONE * CHILD_SCALE
	add_child(_model, false, Node.INTERNAL_MODE_FRONT)
	_animation_player = _model.find_child("AnimationPlayer") as AnimationPlayer
	for animation_name in _animation_player.get_animation_list():
		_animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_animation_player.play("idle")
	_animation_player.seek(randf() * _animation_player.current_animation_length) # nobody breathes in step
	_animate_only_on_screen(self, _animation_player)
	_meshes = _model.find_children("*", "MeshInstance3D")
	_dress()
	for body: MeshInstance3D in _meshes:
		CharacterParts.merge(body) # one part instead of one per color: much quicker to draw
	var on_head := BoneAttachment3D.new()
	on_head.bone_name = "Head"
	(_model.find_child("Skeleton3D") as Skeleton3D).add_child(on_head)
	_head_pan = HeadPan.new()
	_head_pan.position.y = 0.34 if body == Body.WOMAN or body == Body.GIRL else 0.26
	_head_pan.visible = false
	on_head.add_child(_head_pan)
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	_bubble = SpeechBubble.new()
	_bubble.anchor = self
	_bubble.height = 2.2 * (CHILD_SCALE if child else 1.0) + 0.3
	_bubble.speaker = person_name
	_bubble.visible = false
	layer.add_child(_bubble)


## Walks (or runs) to `point` along the walkable area's paths. Returns the
## `arrived` signal, so you can wait for them: `await person.walk_to(point)`.
func walk_to(point: Vector3, run := false) -> Signal:
	_running = run
	_pose = &""
	_path = NavigationServer3D.map_get_path(get_world_3d().navigation_map, global_position, point, true)
	_next_corner = 0
	walking = not _path.is_empty()
	if not walking:
		arrived.emit.call_deferred() # already there (or no way there): don't keep anyone waiting
	return arrived


## Stops walking where they are.
func stop() -> void:
	walking = false


## Holds an animation, like "sit", "eat", "wash", or "ampe" ("" to just stand).
func hold(pose: StringName) -> void:
	_pose = pose


## Moves them onto `spot` (a marker), facing the way it faces, like onto a bench.
func place_at(spot: Node3D) -> void:
	walking = false
	global_position = spot.global_position
	rotation.y = spot.global_rotation.y
	reset_physics_interpolation()


## Turns them to face `point`.
func face(point: Vector3) -> void:
	var toward := point - global_position
	if Vector2(toward.x, toward.z).length() > 0.01:
		rotation.y = atan2(-toward.x, -toward.z)


## Says `line` in a (small) speech bubble over their head.
func say(line: String) -> void:
	_bubble.say(line, true)


## What they're saying right now ("" if nothing).
func saying() -> String:
	return _bubble.text if _bubble.is_showing() else ""


## Their speech bubble (for tests).
func get_bubble() -> SpeechBubble:
	return _bubble


## Puts a headpan of goods (in `goods_color`) on their head, kayayo style.
func carry(goods_color: Palette.ColorName) -> void:
	_head_pan.goods_color = goods_color
	_head_pan.visible = true


## Takes the headpan off.
func put_down() -> void:
	_head_pan.visible = false


## Whether they're carrying a headpan.
func is_carrying() -> bool:
	return _head_pan.visible


## Appears at `point` (stepping out of a door, or off the trotro), fading in.
func appear_at(point: Vector3) -> void:
	walking = false
	_pose = &""
	global_position = Vector3(point.x, 0.0, point.z)
	reset_physics_interpolation()
	visible = true
	_fade(0.0)


## Fades away (going indoors, or onto the trotro). Returns a signal for when
## they've gone.
func vanish() -> Signal:
	walking = false
	_fade(1.0)
	_fade_tween.tween_callback(hide)
	return _fade_tween.finished


## Walks to the trotro's door, gets on (vanishes), and sends `boarded`.
func board(door: Vector3) -> void:
	await walk_to(door)
	await vanish()
	boarded.emit()


## The animation they're playing (for tests).
func current_animation() -> StringName:
	return _animation_player.current_animation


func _physics_process(delta: float) -> void:
	var speed := 0.0
	if walking:
		var direction := _direction_to_next_corner()
		if direction != Vector3.ZERO:
			speed = (run_speed if _running else walk_speed) * (0.85 if is_carrying() else 1.0)
			global_position += direction * speed * delta
			global_position.y = 0.0
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-TURN_SPEED * delta))
		else:
			walking = false
			arrived.emit()
	_animate(speed)


func _animate(speed: float) -> void:
	var size := _model.scale.x
	if speed > 0.05:
		var animation := &"run" if _running else (&"carry" if is_carrying() else &"walk")
		_play(animation)
		var made_for := RUN_ANIMATION_SPEED if _running else WALK_ANIMATION_SPEED
		_animation_player.speed_scale = speed / (made_for * size)
	else:
		var pose := _pose if _pose != &"" else (&"carry_idle" if is_carrying() else &"idle")
		_play(pose)
		_animation_player.speed_scale = 1.0


## Makes `player` (a character's animations) only move while `character` is on
## the screen. With fifty people in town, animating them all every frame was
## the game's biggest cost, so people off the screen (or hidden) hold still
## until the camera can see them again. They keep walking their routes.
static func _animate_only_on_screen(character: Node3D, player: AnimationPlayer) -> void:
	var on_screen := VisibleOnScreenNotifier3D.new()
	on_screen.aabb = AABB(Vector3(-0.6, 0.0, -0.6), Vector3(1.2, 2.3, 1.2))
	on_screen.screen_entered.connect(func() -> void: player.active = true)
	on_screen.screen_exited.connect(func() -> void: player.active = false)
	character.add_child(on_screen, false, Node.INTERNAL_MODE_FRONT)
	player.active = false # until the camera first sees them


func _play(animation: StringName) -> void:
	if _animation_player.current_animation != animation and _animation_player.has_animation(animation):
		_animation_player.play(animation, 0.25)
		if animation in [&"idle", &"sit", &"ampe", &"carry_idle"]:
			# Start somewhere in the loop, so people doing the same thing aren't in step.
			_animation_player.seek(randf() * _animation_player.current_animation_length)


# The way to the next corner of their path, measured flat (the path floats a
# little above the ground), or nothing once they're there.
func _direction_to_next_corner() -> Vector3:
	while _next_corner < _path.size():
		var to_corner := _path[_next_corner] - global_position
		to_corner.y = 0.0
		if to_corner.length() > (0.1 if _next_corner == _path.size() - 1 else 0.35):
			return to_corner.normalized()
		_next_corner += 1
	return Vector3.ZERO


func _fade(to: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	var from: float = (_meshes[0] as GeometryInstance3D).transparency if not _meshes.is_empty() else 0.0
	_fade_tween.tween_method(_set_see_through, from, to, 0.35)


func _set_see_through(amount: float) -> void:
	for mesh: GeometryInstance3D in _meshes:
		mesh.transparency = amount


# Their own clothes: swaps the model's cloth colors for theirs.
func _dress() -> void:
	var colors := {
		"cloth_cream": top_color, "cloth_maroon": bottom_color, "cloth_ochre": trim_color, "cloth_red": headwrap_color,
	}
	for mesh: MeshInstance3D in _meshes:
		for i in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(i)
			if original != null and colors.has(original.resource_name):
				mesh.set_surface_override_material(i, Palette.material(colors[original.resource_name]))
