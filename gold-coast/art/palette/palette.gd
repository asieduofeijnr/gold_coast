@tool
class_name Palette
## The game's color palette. Every color in the game comes from here, so
## changing a color in this file changes it everywhere.
##
## These are provisional colors. The real color bible replaces them in Job 10.

## The color names. Scripts can show these as a dropdown in the Inspector
## (see PaletteMesh).
enum ColorName {
	KENTE_GOLD,
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
	SKIN_DEEP,
	CLOTH_MAROON,
	CLOTH_RED,
	CLOTH_CREAM,
	CLOTH_OCHRE,
	GOLD_JEWELRY,
	DARK_BROWN,
	WALL_MUD,
	WALL_PINK,
	WALL_OLIVE,
	WALL_BAND,
	PLINTH_DARK,
	PLINTH_LIGHT,
	ZINC_LIGHT,
	ZINC_DARK,
	TILE_RED,
	TILE_TERRACOTTA,
	THATCH_GOLD,
	THATCH_TAN,
	THATCH_BROWN,
	WOOD_DARK,
	WOOD_LIGHT,
	BAR_GREEN,
	PATCH_BRICK,
	PHONE_BODY,
	PHONE_EDGE,
	PHONE_BEZEL,
	PHONE_KEY,
	PHONE_KEY_EDGE,
	PHONE_PRINT,
	PHONE_LOGO,
	PHONE_LIGHT,
	LCD_BACKGROUND,
	LCD_GLOW,
	LCD_PIXEL,
	SUN_DAWN,
	SUN_NOON,
	SUN_DUSK,
	MOON_LIGHT,
	SKY_HORIZON_DAWN,
	SKY_TOP_NIGHT,
	SKY_HORIZON_NIGHT,
	GROUND_NIGHT,
	WAAKYE_BROWN,
	SHITO_BLACK,
	BANKU_WHITE,
	TILAPIA_GREY,
	LIGHT_SOUP,
	KENKEY_BEIGE,
	FRIED_FISH,
	KELEWELE_ORANGE,
	SACHET_BLUE,
	ENAMEL_WHITE,
	ENAMEL_RIM,
	ALUMINIUM,
	PAPER,
	WASH_WATER,
	GUTTER,
}

const COLORS: Dictionary[ColorName, Color] = {
	ColorName.KENTE_GOLD: Color("#F2B705"), # accents, taxi corners, signboards
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
	ColorName.SKIN_DEEP: Color("#7A4433"), # the player's skin
	ColorName.CLOTH_MAROON: Color("#6A1C15"), # her slit (wrap skirt)
	ColorName.CLOTH_RED: Color("#A3362A"), # her duku (headwrap)
	ColorName.CLOTH_CREAM: Color("#EAD3B4"), # her kaba (top)
	ColorName.CLOTH_OCHRE: Color("#E0A878"), # trim bands on her skirt
	ColorName.GOLD_JEWELRY: Color("#D9A55B"), # earrings, necklace, bangles
	ColorName.DARK_BROWN: Color("#3D1A14"), # sandals, eyes
	# Buildings: picked from the village pictures in blender/buildings/reference/.
	ColorName.WALL_MUD: Color("#926C47"), # mud-brown walls
	ColorName.WALL_PINK: Color("#C96E84"), # pink painted walls
	ColorName.WALL_OLIVE: Color("#8F8A62"), # olive painted walls
	ColorName.WALL_BAND: Color("#5A3A28"), # dark band along the bottom of walls
	ColorName.PLINTH_DARK: Color("#3E2B1C"), # raised earth plinths
	ColorName.PLINTH_LIGHT: Color("#BA9D7A"), # cement plinths, sills, and ledges
	ColorName.ZINC_LIGHT: Color("#D6D4CE"), # corrugated zinc roofs (light stripes)
	ColorName.ZINC_DARK: Color("#8F8C86"), # corrugated zinc roofs (dark stripes)
	ColorName.TILE_RED: Color("#B0453A"), # red tile and sheet roofs
	ColorName.TILE_TERRACOTTA: Color("#AD6149"), # terracotta tile roofs
	ColorName.THATCH_GOLD: Color("#BA932E"), # fresh thatch
	ColorName.THATCH_TAN: Color("#C8B364"), # pale thatch
	ColorName.THATCH_BROWN: Color("#A46E44"), # old thatch
	ColorName.WOOD_DARK: Color("#5A3220"), # doors, frames, shutters, awnings
	ColorName.WOOD_LIGHT: Color("#9A6C38"), # posts, counters, door panels
	ColorName.BAR_GREEN: Color("#2D4A3A"), # window bars
	ColorName.PATCH_BRICK: Color("#8A5A45"), # brick showing through peeling plaster
	# The mobile money phone (an old Nokia 1100 style).
	ColorName.PHONE_BODY: Color("#2B3340"), # the dark blue-grey body
	ColorName.PHONE_EDGE: Color("#4A5568"), # its rim
	ColorName.PHONE_BEZEL: Color("#12161D"), # the black frame around the screen
	ColorName.PHONE_KEY: Color("#C3CAD3"), # rubber keys
	ColorName.PHONE_KEY_EDGE: Color("#7F8897"), # key outlines
	ColorName.PHONE_PRINT: Color("#1E2530"), # numbers printed on the keys
	ColorName.PHONE_LOGO: Color("#AEB6C2"), # the brand name
	ColorName.PHONE_LIGHT: Color("#E8ECF1"), # the flashlight on top
	ColorName.LCD_BACKGROUND: Color("#A3B38A"), # the green-grey screen
	ColorName.LCD_GLOW: Color("#CBE39B"), # the screen with its backlight on
	ColorName.LCD_PIXEL: Color("#1E2A1A"), # the dark dots on the screen
	# The light through the day (see scenes/world/lighting.gd).
	ColorName.SUN_DAWN: Color("#FFA86B"), # the rising sun
	ColorName.SUN_NOON: Color("#FFF3DC"), # the midday sun
	ColorName.SUN_DUSK: Color("#FF8547"), # the setting sun
	ColorName.MOON_LIGHT: Color("#8DA6D8"), # moonlight
	ColorName.SKY_HORIZON_DAWN: Color("#F0B089"), # the horizon at sunrise and sunset
	ColorName.SKY_TOP_NIGHT: Color("#0B1430"), # the night sky overhead
	ColorName.SKY_HORIZON_NIGHT: Color("#1F2A4A"), # the night sky at the horizon
	ColorName.GROUND_NIGHT: Color("#24180F"), # past the edge of the map at night
	# Chop bar food and kitchenware.
	ColorName.WAAKYE_BROWN: Color("#74392C"), # waakye (rice and beans cooked with sorghum leaves)
	ColorName.SHITO_BLACK: Color("#2E1A12"), # shito, the black pepper sauce
	ColorName.BANKU_WHITE: Color("#EDE6D2"), # banku and fufu
	ColorName.TILAPIA_GREY: Color("#7F857C"), # grilled tilapia
	ColorName.LIGHT_SOUP: Color("#D0602F"), # light soup
	ColorName.KENKEY_BEIGE: Color("#DCCFA5"), # kenkey, groundnuts
	ColorName.FRIED_FISH: Color("#9A6232"), # fried fish
	ColorName.KELEWELE_ORANGE: Color("#DB8A2C"), # kelewele (spicy fried plantain)
	ColorName.SACHET_BLUE: Color("#B8DDF0"), # pure water sachets, washing-up water
	ColorName.ENAMEL_WHITE: Color("#F2F0EA"), # enamel bowls
	ColorName.ENAMEL_RIM: Color("#2E5AA6"), # the blue rim of enamel bowls
	ColorName.ALUMINIUM: Color("#B9BDC1"), # cooking pots and the washing basin
	ColorName.WASH_WATER: Color("#6E9FB4"), # soapy washing-up water
	ColorName.GUTTER: Color("#3B342E"), # the open gutters along the road
	# Pop-up signs and speech bubbles.
	ColorName.PAPER: Color("#FBF6EA"), # speech bubbles
}


## The color with this name.
static func color(color_name: ColorName) -> Color:
	return COLORS[color_name]


## A material in this color. Meshes of the same color share one material,
## which is faster to draw. The shared materials are kept on the scene tree (as
## metadata: extra values any object can carry), so they're cleaned up properly
## when the game closes. (A static variable here would make Godot report this
## script as leaked at exit.)
static func material(color_name: ColorName) -> StandardMaterial3D:
	var tree := Engine.get_main_loop()
	var shared: Dictionary = tree.get_meta(&"palette_materials", {})
	if not shared.has(color_name):
		var new_material := StandardMaterial3D.new()
		new_material.albedo_color = COLORS[color_name]
		shared[color_name] = new_material
		tree.set_meta(&"palette_materials", shared)
	return shared[color_name]
