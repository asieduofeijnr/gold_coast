@tool
class_name Car
extends Vehicle
## A car that comes along the road every so often, drives through town, and
## leaves at the far end. The town's one is an Uber: a silver Toyota Yaris
## hatchback (the model is from blender/scripts/build_vehicles.py), with an
## Uber sticker in its windscreen and its back window. (Driving, turning its
## wheels, and honking at anyone in its way are Vehicle's.)

const SIZE := Vector3(1.7, 1.56, 3.9)
const WHEEL_RADIUS := 0.3
const MODEL := preload("res://art/models/vehicles/uber_car.glb")

## What its window stickers say.
@export var sticker := "Uber":
	set(value):
		sticker = value
		_rebuild()


func get_size() -> Vector3:
	return SIZE


func get_wheel_radius() -> float:
	return WHEEL_RADIUS


func _first_wait() -> float:
	return randf_range(6.0, 14.0)


# A small car's horn is higher than a trotro's.
func _horn_notes() -> Vector2:
	return Vector2(587.0, 740.0)


func _model() -> PackedScene:
	return MODEL


func _dress() -> void:
	for marker in ["StickerFront", "StickerBack"]:
		_write(marker, sticker, Palette.ColorName.PAPER, 0.0016, 0.22, Palette.ColorName.CAR_TRIM)
