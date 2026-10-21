class_name Player
extends CharacterBody3D
## The character you control. WASD (or the arrow keys) moves you relative
## to the camera: W always walks up the screen, whatever the camera angle.

## Top walking speed, in metres per second.
@export var walk_speed := 4.5
## How quickly you speed up to walking speed (metres per second, per second).
@export var acceleration := 30.0
## How quickly you slow down after letting go of the keys.
@export var deceleration := 40.0
## How quickly you turn to face the way you're walking. Higher = snappier.
@export var turn_speed := 12.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := _camera_relative(input)

	# Speed up toward walking speed, or slow down to a stop.
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if direction.is_zero_approx():
		horizontal = horizontal.move_toward(Vector3.ZERO, deceleration * delta)
	else:
		horizontal = horizontal.move_toward(direction * walk_speed, acceleration * delta)
		_turn_toward(direction, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()


## Turns the key input into a direction on the ground, based on which way
## the camera is looking.
func _camera_relative(input: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input.x, 0.0, input.y)
	# The camera's forward and right directions, flattened onto the ground.
	var forward := -camera.global_basis.z
	forward.y = 0.0
	var right := camera.global_basis.x
	right.y = 0.0
	# input.y is -1 for W (forward) and +1 for S (back).
	return right.normalized() * input.x - forward.normalized() * input.y


func _turn_toward(direction: Vector3, delta: float) -> void:
	# Models face -Z, so this is the angle that points -Z along `direction`.
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))
