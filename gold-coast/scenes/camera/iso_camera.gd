@tool
class_name IsoCamera
extends Camera3D
## A fixed-angle isometric camera that smoothly follows a target (the player).
## You can also look around:
## - push the mouse against the edge of the window to slide the view that way
## - zoom with the mouse wheel, a trackpad pinch or two-finger scroll, or = and -
## - press Space, or walk with WASD, to come back to the player

## What the camera follows (usually the player).
@export var target: Node3D
## The sun, so its shadows can reach as far as the camera sees when you zoom out.
@export var sun: DirectionalLight3D

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

## The point on the target to keep centered (the player's middle, not their feet).
@export var target_offset := Vector3(0.0, 1.0, 0.0)

## How quickly the camera catches up with the target. Higher = snappier.
@export var follow_speed := 6.0

@export_group("Looking around")
## How close to the window's edge (in pixels) the mouse must be to slide the view.
@export var edge_margin := 24.0
## How fast the view slides, in screen-heights per second.
@export var pan_speed := 0.9
## How far from the middle of the map the view can slide, in metres.
@export var pan_limit := 38.0
## The closest zoom: how many metres of the world fit the screen's height.
@export var min_size := 8.0
## The furthest zoom.
@export var max_size := 50.0
## How much one click of the mouse wheel zooms.
@export var zoom_step := 1.15
## How quickly the zoom eases to where you asked. Higher = snappier.
@export var zoom_speed := 8.0

## True while the camera follows the target; false after you slide the view away.
var following := true
## The point on the map the camera is looking at.
var focus := Vector3.ZERO
## The zoom the camera is easing toward (the orthographic size).
var target_size := 20.0

var _mouse_in_window := false


func _ready() -> void:
	_apply_angle()
	target_size = size
	if Engine.is_editor_hint():
		return
	get_window().mouse_entered.connect(_on_mouse_entered_window)
	get_window().mouse_exited.connect(_on_mouse_exited_window)
	if target != null:
		# Start in place, so the camera doesn't swoop in when the game starts.
		focus = _target_point()
	_place()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _mouse_in_window:
		var view := get_viewport()
		var push := edge_direction(view.get_mouse_position(), view.get_visible_rect().size, edge_margin)
		if push != Vector2.ZERO:
			pan(push, delta)
	# Walking with the keys brings the camera back to the player.
	if not following and Input.get_vector("move_left", "move_right", "move_forward", "move_back") != Vector2.ZERO:
		following = true
	if following and target != null:
		# Close the same share of the gap every second, whatever the frame rate.
		focus = focus.lerp(_target_point(), 1.0 - exp(-follow_speed * delta))
	size = lerpf(size, target_size, 1.0 - exp(-zoom_speed * delta))
	_place()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("zoom_in"):
		zoom(-1.0)
	elif event.is_action_pressed("zoom_out"):
		zoom(1.0)
	elif event.is_action_pressed("recenter_camera"):
		following = true
	elif event is InputEventMagnifyGesture: # pinching on a trackpad
		target_size = clampf(target_size / (event as InputEventMagnifyGesture).factor, min_size, max_size)
	elif event is InputEventPanGesture: # two-finger scrolling on a trackpad
		zoom((event as InputEventPanGesture).delta.y * 0.2)


## Slides the view. `direction` is in screen terms (x to the right, y down),
## and `delta` is how many seconds of sliding. The camera stops following.
func pan(direction: Vector2, delta: float) -> void:
	following = false
	var right := Vector3(global_basis.x.x, 0.0, global_basis.x.z).normalized()
	var up_screen := Vector3(-global_basis.z.x, 0.0, -global_basis.z.z).normalized()
	focus += (right * direction.x - up_screen * direction.y) * pan_speed * size * delta
	focus.x = clampf(focus.x, -pan_limit, pan_limit)
	focus.z = clampf(focus.z, -pan_limit, pan_limit)


## Zooms in (negative steps) or out (positive steps), within the limits.
func zoom(steps: float) -> void:
	target_size = clampf(target_size * pow(zoom_step, steps), min_size, max_size)


## Which way to slide when the mouse is at `mouse` in a window of `view_size`:
## left at the left edge, up and right in the top-right corner, nowhere in the middle.
static func edge_direction(mouse: Vector2, view_size: Vector2, margin: float) -> Vector2:
	var push := Vector2.ZERO
	if mouse.x <= margin:
		push.x = -1.0
	elif mouse.x >= view_size.x - margin:
		push.x = 1.0
	if mouse.y <= margin:
		push.y = -1.0
	elif mouse.y >= view_size.y - margin:
		push.y = 1.0
	return push.normalized()


func _target_point() -> Vector3:
	# The interpolated position is where the target is drawn this frame,
	# which keeps movement smooth on high refresh rate screens.
	return target.get_global_transform_interpolated().origin + target_offset


# The view only slides while the mouse is inside the window.
func _on_mouse_entered_window() -> void:
	_mouse_in_window = true


func _on_mouse_exited_window() -> void:
	_mouse_in_window = false


# Puts the camera behind the focus point. Zoomed out, the camera backs off so the
# bottom of the view isn't cut off, and the sun's shadows reach the top of the view.
func _place() -> void:
	var back := maxf(40.0, 0.87 * size + 10.0)
	global_position = focus + global_basis.z * back
	if sun != null:
		sun.directional_shadow_max_distance = back + 0.87 * size + 10.0


func _apply_angle() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
