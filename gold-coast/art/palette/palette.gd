@tool
class_name Palette
## The game's color palette. Every color in the game comes from here, so
## changing a color in this file changes it everywhere.
##
## These are provisional colors. The real color bible replaces them in Job 10.

## The color names. Scripts can show these as a dropdown in the Inspector
## (see PaletteMesh).
enum ColorName {
	DANFO_YELLOW,
	LATERITE,
	ASPHALT,
	ROAD_MARKING,
	CONCRETE,
	WALL_CREAM,
	WALL_BLUE,
	WALL_MINT,
	WALL_SALMON,
	RUST_ROOF,
	PALM_GREEN,
	PLAYER_BLUE,
	SUN_AFTERNOON,
	SKY_TOP,
	SKY_HORIZON,
	GROUND_HORIZON,
	GROUND_BOTTOM,
}

const COLORS: Dictionary[ColorName, Color] = {
	ColorName.DANFO_YELLOW: Color("#F2B705"), # buses, accents
	ColorName.LATERITE: Color("#A9532D"), # bare ground, road edges
	ColorName.ASPHALT: Color("#4A4A48"), # roads
	ColorName.ROAD_MARKING: Color("#E8E4D8"), # lane lines
	ColorName.CONCRETE: Color("#B9B2A3"), # sidewalks, plain walls
	ColorName.WALL_CREAM: Color("#E9DCC0"), # buildings
	ColorName.WALL_BLUE: Color("#8DB8D0"), # buildings
	ColorName.WALL_MINT: Color("#A8CFA6"), # buildings
	ColorName.WALL_SALMON: Color("#E3A08C"), # buildings
	ColorName.RUST_ROOF: Color("#8B4A2B"), # roofs
	ColorName.PALM_GREEN: Color("#3F7A3A"), # plants
	ColorName.PLAYER_BLUE: Color("#2B59C3"), # placeholder player
	ColorName.SUN_AFTERNOON: Color("#FFE3BD"), # warm afternoon sunlight
	ColorName.SKY_TOP: Color("#6C9BC7"), # sky overhead
	ColorName.SKY_HORIZON: Color("#D9D0BE"), # hazy sky near the horizon
	ColorName.GROUND_HORIZON: Color("#9A5A3A"), # what you see past the edge of the map
	ColorName.GROUND_BOTTOM: Color("#8A4E30"), # what you see past the edge of the map
}

# One shared material per color, made the first time it's asked for.
static var _materials: Dictionary[ColorName, StandardMaterial3D] = {}


## The color with this name.
static func color(color_name: ColorName) -> Color:
	return COLORS[color_name]


## A material in this color. Meshes of the same color share one material,
## which is faster to draw.
static func material(color_name: ColorName) -> StandardMaterial3D:
	if not _materials.has(color_name):
		var new_material := StandardMaterial3D.new()
		new_material.albedo_color = COLORS[color_name]
		_materials[color_name] = new_material
	return _materials[color_name]
