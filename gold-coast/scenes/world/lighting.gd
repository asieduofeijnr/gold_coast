@tool
class_name Lighting
extends Node3D
## The sun, the moon, and the sky, following the game clock. The sun rises in
## the east (+X) around 06:00, is highest around midday (in the south, +Z), and
## sets in the west around 18:30, glowing warm at both ends of the day. At night
## a dim blue moon takes over. All the colors come from the palette.
##
## In the editor, drag "Time Of Day" to preview any time. In the game, the
## lighting follows GameState's clock.
##
## Web browsers draw the game with Godot's Compatibility renderer, which has no
## ambient occlusion and handles bright light differently: with the same
## settings, daylight looks washed out. So with that renderer, the light is
## mapped to the screen a little differently (COMPATIBILITY_LOOK).

const SUNRISE := 6.0 * 60.0
const SUNSET := 18.5 * 60.0
## How high the sun gets at midday, in degrees above the horizon.
const HIGHEST_SUN := 65.0
const MOON_STRENGTH := 0.45
const MOON_ROTATION := Vector3(-55.0, 150.0, 0.0)
## With the Compatibility renderer (the web's), these environment settings make
## it look like the desktop game. They were picked by comparing pictures of the
## same five views (day, evening, and night) with both renderers.
const COMPATIBILITY_LOOK := {
	"tonemap_mode": Environment.TONE_MAPPER_LINEAR,
	"tonemap_exposure": 0.94,
	"adjustment_enabled": true,
	"adjustment_contrast": 0.86,
	"adjustment_saturation": 1.15,
}

# How the light looks through the day. Each moment is [time in minutes, sun
# color, sun strength, sky overhead, sky at the horizon, ground past the map's
# edge]. Times in between blend smoothly from one moment to the next.
const MOMENTS := [
	[0.0, Palette.ColorName.SUN_DUSK, 0.0, Palette.ColorName.SKY_TOP_NIGHT, Palette.ColorName.SKY_HORIZON_NIGHT, Palette.ColorName.GROUND_NIGHT],
	[330.0, Palette.ColorName.SUN_DAWN, 0.0, Palette.ColorName.SKY_TOP_NIGHT, Palette.ColorName.SKY_HORIZON_DAWN, Palette.ColorName.GROUND_NIGHT],
	[360.0, Palette.ColorName.SUN_DAWN, 0.35, Palette.ColorName.SKY_TOP, Palette.ColorName.SKY_HORIZON_DAWN, Palette.ColorName.GROUND_BOTTOM],
	[450.0, Palette.ColorName.SUN_AFTERNOON, 1.0, Palette.ColorName.SKY_TOP, Palette.ColorName.SKY_HORIZON, Palette.ColorName.GROUND_BOTTOM],
	[735.0, Palette.ColorName.SUN_NOON, 0.95, Palette.ColorName.SKY_TOP, Palette.ColorName.SKY_HORIZON, Palette.ColorName.GROUND_BOTTOM],
	[990.0, Palette.ColorName.SUN_AFTERNOON, 1.0, Palette.ColorName.SKY_TOP, Palette.ColorName.SKY_HORIZON, Palette.ColorName.GROUND_BOTTOM],
	[1110.0, Palette.ColorName.SUN_DUSK, 0.35, Palette.ColorName.SKY_TOP, Palette.ColorName.SKY_HORIZON_DAWN, Palette.ColorName.GROUND_BOTTOM],
	[1155.0, Palette.ColorName.SUN_DUSK, 0.0, Palette.ColorName.SKY_TOP_NIGHT, Palette.ColorName.SKY_HORIZON_NIGHT, Palette.ColorName.GROUND_NIGHT],
	[1440.0, Palette.ColorName.SUN_DUSK, 0.0, Palette.ColorName.SKY_TOP_NIGHT, Palette.ColorName.SKY_HORIZON_NIGHT, Palette.ColorName.GROUND_NIGHT],
]

## The time of day the lighting shows, in minutes since midnight (420 = 07:00).
@export_range(0.0, 1440.0, 1.0) var time_of_day := 420.0:
	set(value):
		time_of_day = value
		if is_node_ready():
			_apply()

# The sky is costly to redraw, so it's only updated once a game minute has passed.
var _sky_time := -INF

@onready var _sun: DirectionalLight3D = $Sun
@onready var _moon: DirectionalLight3D = $Moon
@onready var _world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_moon.rotation_degrees = MOON_ROTATION
	_moon.light_color = Palette.color(Palette.ColorName.MOON_LIGHT)
	if not Engine.is_editor_hint() and RenderingServer.get_current_rendering_method() == "gl_compatibility":
		_world_environment.environment = compatibility_environment(_world_environment.environment)
	_apply()


## A copy of `environment` with COMPATIBILITY_LOOK's settings, for the
## Compatibility renderer. (The original stays as it is.)
static func compatibility_environment(environment: Environment) -> Environment:
	var adjusted := environment.duplicate() as Environment
	for setting: String in COMPATIBILITY_LOOK:
		adjusted.set(setting, COMPATIBILITY_LOOK[setting])
	return adjusted


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		time_of_day = GameState.minutes


## How high the sun is at a time of day, in degrees above the horizon. It's 0 at
## sunrise and sunset, highest in between, and below 0 at night.
static func sun_elevation(minutes: float) -> float:
	return HIGHEST_SUN * sin(PI * (minutes - SUNRISE) / (SUNSET - SUNRISE))


## Where the sun is around the sky at a time of day, in degrees: 0 is east (+X)
## at sunrise, 90 is south (+Z) around midday, and 180 is west (-X) at sunset.
static func sun_compass(minutes: float) -> float:
	return clampf((minutes - SUNRISE) / (SUNSET - SUNRISE), 0.0, 1.0) * 180.0


## The direction from the ground toward the sun.
func toward_sun() -> Vector3:
	# A light shines along its -Z axis, so its +Z axis points back at the sun.
	return _sun.global_basis.z


## How high the sun is right now, in degrees, measured from the light itself.
func sun_height() -> float:
	return rad_to_deg(asin(toward_sun().y))


func is_sun_up() -> bool:
	return _sun.visible


func is_moon_up() -> bool:
	return _moon.visible


func _apply() -> void:
	var height := deg_to_rad(sun_elevation(time_of_day))
	var compass := deg_to_rad(sun_compass(time_of_day))
	var to_sun := Vector3(cos(height) * cos(compass), sin(height), cos(height) * sin(compass))
	_sun.basis = Basis.looking_at(-to_sun, Vector3.UP)

	var moment := _moment_at(time_of_day)
	_sun.light_color = moment[0]
	_sun.light_energy = moment[1]
	_sun.visible = moment[1] > 0.01
	# The moon fades in as the sun fades out.
	_moon.light_energy = MOON_STRENGTH * (1.0 - clampf(moment[1] / 0.35, 0.0, 1.0))
	_moon.visible = _moon.light_energy > 0.01

	if Engine.is_editor_hint() or absf(time_of_day - _sky_time) >= 1.0:
		_sky_time = time_of_day
		var sky := _world_environment.environment.sky.sky_material as ProceduralSkyMaterial
		sky.sky_top_color = moment[2]
		sky.sky_horizon_color = moment[3]
		sky.ground_horizon_color = moment[4]
		sky.ground_bottom_color = moment[4]


## The light at a time of day, blended between the two nearest moments:
## [sun color, sun strength, sky overhead, sky at the horizon, ground].
func _moment_at(minutes: float) -> Array:
	var i := 0
	while i < MOMENTS.size() - 2 and minutes >= MOMENTS[i + 1][0]:
		i += 1
	var before: Array = MOMENTS[i]
	var after: Array = MOMENTS[i + 1]
	var blend := clampf((minutes - before[0]) / (after[0] - before[0]), 0.0, 1.0)
	return [
		Palette.color(before[1]).lerp(Palette.color(after[1]), blend),
		lerpf(before[2], after[2], blend),
		Palette.color(before[3]).lerp(Palette.color(after[3]), blend),
		Palette.color(before[4]).lerp(Palette.color(after[4]), blend),
		Palette.color(before[5]).lerp(Palette.color(after[5]), blend),
	]
