extends Node3D
## A gold ring that pops up on the ground where you click, then fades away.

const FADE_TIME := 0.7

var _tween: Tween

@onready var _ring: MeshInstance3D = $Ring


func _ready() -> void:
	_ring.material_override = Palette.material(Palette.ColorName.KENTE_GOLD)
	visible = false


## Shows the ring at `point` on the ground.
func show_at(point: Vector3) -> void:
	global_position = point + Vector3.UP * 0.04
	visible = true
	_ring.transparency = 0.0
	scale = Vector3.ONE * 1.6
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE, 0.2)
	_tween.tween_property(_ring, "transparency", 1.0, FADE_TIME)
	_tween.tween_callback(hide)
