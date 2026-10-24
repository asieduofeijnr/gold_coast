class_name PlayerModel
extends Node3D
## The player's 3D character. It plays "idle" when she's standing still and
## "walk" when she's moving, and speeds the walk up or slows it down so her
## feet keep pace with the ground.

## The speed (metres per second) her walk animation was made for. Measured
## from the animation in Blender.
@export var walk_animation_speed := 1.7
## Below this speed she counts as standing still.
@export var walk_threshold := 0.2
## How long the change between standing and walking takes, in seconds.
@export var blend_time := 0.2

## How fast she's moving, in metres per second. The player script sets this.
var move_speed := 0.0

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer")


func _ready() -> void:
	# The animations should repeat forever. The file doesn't store that, so
	# it's set here.
	for animation_name in animation_player.get_animation_list():
		animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	animation_player.play("idle")


func _process(_delta: float) -> void:
	if move_speed > walk_threshold:
		_play("walk")
		animation_player.speed_scale = move_speed / walk_animation_speed
	else:
		_play("idle")
		animation_player.speed_scale = 1.0


func _play(animation_name: StringName) -> void:
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name, blend_time)
