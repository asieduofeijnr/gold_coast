class_name WorldLabel
extends Control
## A bit of 2D drawing that floats over a spot in the 3D world, like a speech
## bubble over someone's head. Every frame it works out where that spot shows on
## the screen and moves there. Put it inside a CanvasLayer.
##
## The spot is at (0, 0) in its own drawing, so the scripts that extend this
## one draw their shape above (0, 0), with a tail or pointer reaching down to it.

## The 3D node it floats over.
var anchor: Node3D
## How high above the anchor it floats, in metres.
var height := 2.0
## How many pixels it bobs up and down (0 = it stays still).
var bob := 0.0

var _tween: Tween
var _showing := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Move after the camera has moved this frame, so it never lags behind.
	process_priority = 100


func _process(_delta: float) -> void:
	follow()


## Moves it to where the anchor shows on the screen right now.
func follow() -> void:
	var camera := get_viewport().get_camera_3d()
	if anchor == null or camera == null or not anchor.is_inside_tree():
		return
	# Where the anchor is drawn this frame, which keeps it smooth on fast screens.
	var spot := anchor.get_global_transform_interpolated().origin + Vector3.UP * height
	position = camera.unproject_position(spot)
	if bob > 0.0:
		position.y += bob * sin(Time.get_ticks_msec() / 250.0)


## Shows it with a little pop.
func appear() -> void:
	_showing = true
	if _tween != null:
		_tween.kill()
	if not visible:
		scale = Vector2.ONE * 0.6
		modulate.a = 0.0
		visible = true
	follow()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.12)


## Hides it with a quick fade.
func disappear() -> void:
	_showing = false
	if not visible:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(hide)


## Whether it's showing (or popping up), rather than hidden or fading away.
func is_showing() -> bool:
	return _showing
