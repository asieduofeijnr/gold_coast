class_name Player
extends CharacterBody3D
## The character you control.
## - WASD (or the arrow keys) moves you relative to the camera: W always walks
##   up the screen, whatever the camera angle.
## - Clicking the ground walks you there, finding a way around buildings.
##   Pressing a movement key takes over from a click straight away.
## - E uses the nearest thing she can use (an Interactable) when she's close
##   enough. Clicking one (like the Chop Bar) walks her over to use it, and the
##   pointer turns into a hand when it's over one. With a load on her head, she
##   can only use the things that work with one (like where it's going).
## - She walks a little slower with a load on her head.
## - Z makes her sleep when she's tired. A movement key wakes her up again.
## - When she's sleepy (low energy) she walks more slowly.

## Announced when you click somewhere to walk to (used to show a marker there).
signal destination_chosen(point: Vector3)

## The physics layers a click can land on to use something: walls (1) and roof
## copies (2), so clicking anywhere on a building counts.
const CLICK_LAYERS := 0b11
## How long sitting down or getting up takes, in seconds.
const SETTLE_TIME := 0.35

# Doing something at a spot, like eating at a table (see act_at()): walking
# there, staying put there, or getting up afterwards.
enum Act { NONE, GOING, IN_PLACE, GETTING_UP }

## Top walking speed, in metres per second (a brisk walk, matching her
## walk animation).
@export var walk_speed := 1.8
## How quickly you speed up to walking speed (metres per second, per second).
@export var acceleration := 30.0
## How quickly you slow down after letting go of the keys.
@export var deceleration := 40.0
## How quickly you turn to face the way you're walking. Higher = snappier.
@export var turn_speed := 12.0
## How much slower she walks when she's sleepy (0.7 = 70% of her normal speed).
@export var sleepy_speed := 0.7
## How much slower she walks with a load on her head (0.85 = 85% of her normal speed).
@export var carry_speed := 0.85

## True while walking to a clicked spot.
var has_destination := false
## What E would use right now: the nearest Interactable in reach, or null.
var focus: Interactable
## What the mouse is pointing at, if it's something she can use.
var hovered: Interactable
## Whether she's gone inside a building for a while (to a class, say), out of
## sight. Whatever took her in sets it, and sets it back when she comes out.
var indoors := false

# The corners of the path to the clicked spot, and which one she's heading for.
var _path := PackedVector3Array()
var _next_corner := 0
# Something you clicked: she uses it when she gets there.
var _use_on_arrival: Interactable
# What she's doing at a spot (see act_at()), and where she stood before.
var _act := Act.NONE
var _act_spot: Node3D
var _act_pose := &""
var _act_then := Callable()
var _stand_position := Vector3.ZERO
var _mouse_in_window := false

# The 3D character, if the Model is one (the old capsule placeholder isn't).
@onready var _model := get_node_or_null("Model") as PlayerModel


func _ready() -> void:
	get_window().mouse_entered.connect(_on_mouse_entered_window)
	get_window().mouse_exited.connect(_on_mouse_exited_window)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sleep"):
		if GameState.sleeping:
			GameState.wake_up()
		elif is_free():
			has_destination = false
			_use_on_arrival = null
			GameState.sleep()
	elif not is_free():
		return # asleep or busy: she can't walk or use things
	elif event.is_action_pressed("interact"):
		if focus != null:
			get_viewport().set_input_as_handled()
			_use(focus)
	elif event.is_action_pressed("move_to_click") and event is InputEventMouseButton:
		var screen_position := (event as InputEventMouseButton).position
		var target := interactable_at(screen_position)
		if target != null:
			go_use(target)
		else:
			var point: Variant = _ground_point(screen_position)
			if point != null:
				_use_on_arrival = null
				walk_to(point)


## Whether she's free to walk around and use things: awake, not busy, and not
## sitting or standing somewhere for an activity.
func is_free() -> bool:
	return _act == Act.NONE and not GameState.sleeping and GameState.activity == ""


## Whether she can use `thing` right now: it has to be switched on, and while
## she carries a load, it has to work with a load on her head.
func can_use(thing: Interactable) -> bool:
	return thing.enabled and (GameState.delivery == null or thing.works_while_carrying)


## Walks to `point` on the ground, going around anything in the way. The path
## comes from the walkable area (see scenes/world/walkable_area.gd). If the spot
## can't be reached, she walks as close as she can get.
func walk_to(point: Vector3) -> void:
	_path = NavigationServer3D.map_get_path(get_world_3d().navigation_map, global_position, point, true)
	_next_corner = 0
	has_destination = not _path.is_empty()
	destination_chosen.emit(point)


## Walks her over to `target` and uses it when she gets there (straight away if
## she's already close enough).
func go_use(target: Interactable) -> void:
	if _in_reach(target):
		_use(target)
		return
	walk_to(target.global_position)
	_use_on_arrival = target


## Walks her to `spot`, turns her the way it faces, and holds `pose` there (an
## animation like "eat", or "" to just stand). Then it calls `then`, which
## starts what she's there for (like a meal). She stays put until she's awake
## and not busy any more, then gets up. Movement keys don't stop her on the way.
func act_at(spot: Node3D, pose: StringName, then: Callable) -> void:
	_act = Act.GOING
	_act_spot = spot
	_act_pose = pose
	_act_then = then
	_use_on_arrival = null
	walk_to(spot.global_position)


## The Interactable whose click target shows at `screen_position`, if any.
func interactable_at(screen_position: Vector2) -> Interactable:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var from := camera.project_ray_origin(screen_position)
	var to := from + camera.project_ray_normal(screen_position) * camera.far
	var skip: Array[RID] = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(from, to, CLICK_LAYERS, skip))
	if hit.is_empty():
		return null
	for node in get_tree().get_nodes_in_group(Interactable.GROUP):
		var thing := node as Interactable
		if can_use(thing) and thing.is_clicked(hit.collider):
			return thing
	return null


func _physics_process(delta: float) -> void:
	if _act == Act.IN_PLACE or _act == Act.GETTING_UP:
		_hold_still()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3.ZERO
	if GameState.sleeping:
		# A movement key wakes her (unless she passed out and needs more rest).
		if input != Vector2.ZERO:
			GameState.wake_up()
		has_destination = false
		_use_on_arrival = null
	elif GameState.activity == "":
		if _act == Act.NONE:
			direction = _camera_relative(input)
		if not direction.is_zero_approx():
			has_destination = false # the keys take over from a click
			_use_on_arrival = null
		elif has_destination:
			direction = _direction_to_destination()

	# Speed up toward walking speed, or slow down to a stop.
	var speed := walk_speed * (sleepy_speed if GameState.energy < GameState.LOW else 1.0)
	if GameState.delivery != null:
		speed *= carry_speed
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if direction.is_zero_approx():
		horizontal = horizontal.move_toward(Vector3.ZERO, deceleration * delta)
	else:
		horizontal = horizontal.move_toward(direction * speed, acceleration * delta)
		_turn_toward(direction, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

	var moving_speed := Vector2(velocity.x, velocity.z).length()
	GameState.is_walking = moving_speed > 0.2 # walking tires her faster
	_update_model(moving_speed)

	if _act == Act.GOING and not has_destination:
		_settle_in()
	elif _use_on_arrival != null and not has_destination:
		var target := _use_on_arrival
		_use_on_arrival = null
		if _in_reach(target):
			_use(target)
	_update_focus()
	_update_hover()


# Sitting, working, in bed, or getting up: she stays exactly where she's put.
func _hold_still() -> void:
	velocity = Vector3.ZERO
	GameState.is_walking = false
	if _act == Act.IN_PLACE and not GameState.sleeping and GameState.activity == "":
		_get_up()
	_update_model(0.0)
	_update_focus()
	_update_hover()


# She's reached the spot: she moves onto it (onto the bench, say), takes up
# her pose, and starts what she came for.
func _settle_in() -> void:
	_act = Act.IN_PLACE
	_stand_position = global_position
	var spot := _act_spot.global_transform
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_parallel()
	tween.tween_property(self, "global_position", Vector3(spot.origin.x, global_position.y, spot.origin.z), SETTLE_TIME)
	tween.tween_property(self, "rotation:y", _nearest_angle(spot.basis.get_euler().y), SETTLE_TIME)
	if _model != null:
		_model.pose = _act_pose
	if _act_then.is_valid():
		_act_then.call()


# She's done: she gets up and steps back to where she stood before.
func _get_up() -> void:
	_act = Act.GETTING_UP
	_act_spot = null
	_act_then = Callable()
	if _model != null:
		_model.pose = &""
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "global_position", _stand_position, SETTLE_TIME)
	tween.tween_callback(func() -> void: _act = Act.NONE)


func _update_model(moving_speed: float) -> void:
	if _model == null:
		return
	_model.move_speed = moving_speed
	_model.sleeping = GameState.sleeping and not GameState.in_bed # in bed, she's indoors instead
	_model.inside = GameState.in_bed or indoors
	_model.activity = GameState.activity
	_model.activity_progress = GameState.activity_progress()
	_model.headload = GameState.delivery


# Turns her toward `target` and uses it.
func _use(target: Interactable) -> void:
	if not can_use(target):
		return
	has_destination = false
	_use_on_arrival = null
	# Forget what she was near and pointing at; it's worked out again next step,
	# so the sign comes back when she's done.
	focus = null
	hovered = null
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "rotation:y", _nearest_angle(target.global_basis.get_euler().y), 0.2)
	target.use(self)


# Finds the nearest thing she could use with E, and shows its sign.
func _update_focus() -> void:
	var nearest: Interactable = null
	if is_free():
		var nearest_gap := INF
		for node in get_tree().get_nodes_in_group(Interactable.GROUP):
			var thing := node as Interactable
			if not can_use(thing):
				continue
			var gap := _flat_distance(thing.global_position)
			if gap <= thing.reach and gap < nearest_gap:
				nearest = thing
				nearest_gap = gap
	if nearest == focus:
		return
	if is_instance_valid(focus):
		focus.focused = false
	focus = nearest
	if focus != null:
		focus.focused = true


## Points at whatever shows at `screen_position`, as the mouse does every
## step: if it's something she can use, the pointer turns into a hand and its
## sign shows.
func point_at(screen_position: Vector2) -> void:
	_set_hovered(interactable_at(screen_position) if is_free() else null)


func _update_hover() -> void:
	if _mouse_in_window:
		point_at(get_viewport().get_mouse_position())
	else:
		_set_hovered(null)


func _set_hovered(pointed: Interactable) -> void:
	if pointed == hovered:
		return
	if is_instance_valid(hovered):
		hovered.hovered = false
	hovered = pointed
	if hovered != null:
		hovered.hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered != null else Input.CURSOR_ARROW)


func _in_reach(target: Interactable) -> bool:
	return _flat_distance(target.global_position) <= target.reach


# The distance to `point` measured flat along the ground.
func _flat_distance(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


# The angle closest to her current one that faces the same way as `angle`, so
# she turns the short way round.
func _nearest_angle(angle: float) -> float:
	return rotation.y + wrapf(angle - rotation.y, -PI, PI)


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


## The way to the next corner of the path to the clicked spot, or nothing once
## she's there. Distances are measured flat along the ground, because the
## walkable area's path floats a little above it.
func _direction_to_destination() -> Vector3:
	while _next_corner < _path.size():
		var to_corner := _path[_next_corner] - global_position
		to_corner.y = 0.0
		var close_enough := 0.1 if _next_corner == _path.size() - 1 else 0.3
		if to_corner.length() > close_enough:
			return to_corner.normalized()
		_next_corner += 1
	has_destination = false
	return Vector3.ZERO


## Where a point on the screen lands on the ground (height 0), or null if it doesn't.
func _ground_point(screen_position: Vector2) -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var origin := camera.project_ray_origin(screen_position)
	var ray := camera.project_ray_normal(screen_position)
	if absf(ray.y) < 0.001:
		return null
	var distance := -origin.y / ray.y
	return origin + ray * distance if distance > 0.0 else null


func _turn_toward(direction: Vector3, delta: float) -> void:
	# Models face -Z, so this is the angle that points -Z along `direction`.
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-turn_speed * delta))


# The pointer only counts while it's inside the window.
func _on_mouse_entered_window() -> void:
	_mouse_in_window = true


func _on_mouse_exited_window() -> void:
	_mouse_in_window = false
