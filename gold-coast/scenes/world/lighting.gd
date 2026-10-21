@tool
extends Node3D
## The sun and the sky. Their colors come from the palette.

## How high the sun is above the horizon, in degrees (90 = straight overhead).
@export_range(5.0, 90.0) var sun_height_degrees := 45.0:
	set(value):
		sun_height_degrees = value
		if is_node_ready():
			_apply()

## Turns the sun around the map, which changes the way shadows fall.
@export_range(-180.0, 180.0) var sun_direction_degrees := -30.0:
	set(value):
		sun_direction_degrees = value
		if is_node_ready():
			_apply()

@onready var _sun: DirectionalLight3D = $Sun
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_apply()


func _apply() -> void:
	_sun.rotation_degrees = Vector3(-sun_height_degrees, sun_direction_degrees, 0.0)
	_sun.light_color = Palette.color(Palette.ColorName.SUN_AFTERNOON)

	var sky := _world_environment.environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = Palette.color(Palette.ColorName.SKY_TOP)
	sky.sky_horizon_color = Palette.color(Palette.ColorName.SKY_HORIZON)
	sky.ground_horizon_color = Palette.color(Palette.ColorName.GROUND_HORIZON)
	sky.ground_bottom_color = Palette.color(Palette.ColorName.GROUND_BOTTOM)
