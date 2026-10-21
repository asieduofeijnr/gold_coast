@tool
extends Camera3D
## A fixed-angle isometric camera that smoothly follows a target.

## What the camera follows (usually the player).
@export var target: Node3D

## How far the camera tilts down, in degrees. -30 gives the classic 2:1
## isometric look.
@export_range(-89.0, -10.0) var pitch_degrees := -30.0:
	set(value):
		pitch_degrees = value
		_apply_angle()

## Which way the camera faces around the map, in degrees.
@export_range(-180.0, 180.0) var yaw_degrees := 45.0:
	set(value):
		yaw_degrees = value
		_apply_angle()

## How far back the camera sits. This doesn't change how big things look
## (the orthographic Size does that). It just needs to be far enough back
## that nothing gets cut off.
@export var distance := 40.0

## The point on the target to keep centered (the player's middle, not their feet).
@export var target_offset := Vector3(0.0, 1.0, 0.0)

## How quickly the camera catches up with the target. Higher = snappier.
@export var follow_speed := 6.0


func _ready() -> void:
	_apply_angle()
	if not Engine.is_editor_hint() and target != null:
		# Start in place, so the camera doesn't swoop in when the game starts.
		global_position = _desired_position()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or target == null:
		return
	# Close the same share of the gap every second, whatever the frame rate.
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_desired_position(), weight)


func _desired_position() -> Vector3:
	# The interpolated position is where the target is drawn this frame,
	# which keeps movement smooth on high refresh rate screens.
	var focus := target.get_global_transform_interpolated().origin + target_offset
	# The camera looks along its -Z axis, so "backwards" is +Z.
	return focus + global_basis.z * distance


func _apply_angle() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
