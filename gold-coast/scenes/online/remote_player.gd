class_name RemotePlayer
extends Node3D
## Another player in the shared Gold Coast (see TownPlayers): the same
## character as yours, but in her own colors (from her username, so she always
## looks the same), without your gold star pin, and with her @username over her
## head. About 10 times a second her game says where she is
## (move_to()), and she walks smoothly there, turning the way she faces. She
## walks, sits, eats, sleeps, or goes indoors as she does over there. Players
## walk through each other.

const MODEL := preload("res://scenes/player/player_model.tscn")
## How quickly she closes the gap to where she should be (bigger is quicker).
const CATCH_UP := 10.0
## Further away than this (say, after loading a game), she's put straight there.
const JUMP := 6.0
## How high her name floats over her feet.
const NAME_HEIGHT := 2.2
## The outfits other players wear: top, slit, trim, and duku. None is the
## player's own cream and maroon.
const OUTFITS := [
	[Palette.ColorName.KENTE_GOLD, Palette.ColorName.PALM_GREEN, Palette.ColorName.CLOTH_RED, Palette.ColorName.KENTE_GOLD],
	[Palette.ColorName.SACHET_BLUE, Palette.ColorName.PLAYER_BLUE, Palette.ColorName.PAPER, Palette.ColorName.PLAYER_BLUE],
	[Palette.ColorName.WALL_PINK, Palette.ColorName.WOOD_DARK, Palette.ColorName.KENTE_GOLD, Palette.ColorName.WALL_PINK],
	[Palette.ColorName.WALL_MINT, Palette.ColorName.TROTRO_BLUE, Palette.ColorName.PAPER, Palette.ColorName.WALL_MINT],
	[Palette.ColorName.KELEWELE_ORANGE, Palette.ColorName.DARK_BROWN, Palette.ColorName.KENTE_GOLD, Palette.ColorName.KELEWELE_ORANGE],
	[Palette.ColorName.BANKU_WHITE, Palette.ColorName.ENAMEL_RIM, Palette.ColorName.TILE_RED, Palette.ColorName.ENAMEL_RIM],
	[Palette.ColorName.WALL_SALMON, Palette.ColorName.PALM_GREEN, Palette.ColorName.PAPER, Palette.ColorName.WALL_SALMON],
	[Palette.ColorName.LIGHT_SOUP, Palette.ColorName.SHITO_BLACK, Palette.ColorName.KENTE_GOLD, Palette.ColorName.LIGHT_SOUP],
]

## Her username (set it before she's added to the scene).
var username := ""

var _model: PlayerModel
var _name: Label3D
var _target := Vector3.ZERO
var _facing := 0.0
var _placed := false


func _ready() -> void:
	_model = MODEL.instantiate() as PlayerModel
	_model.marked = false # the star pin is only for you
	_model.outfit = outfit_for(username)
	add_child(_model)
	_name = Shapes.name_label("@" + username)
	_name.pixel_size = 0.004
	_name.position.y = NAME_HEIGHT
	add_child(_name)


## The outfit a player wears, from her username: the same one every time.
static func outfit_for(player_username: String) -> Dictionary:
	var colors: Array = OUTFITS[posmod(player_username.hash(), OUTFITS.size())]
	return {"cloth_cream": colors[0], "cloth_maroon": colors[1], "cloth_ochre": colors[2], "cloth_red": colors[3]}


## Where her game says she is now: a move from TownPlayers.move_of().
func move_to(move: Dictionary) -> void:
	_target = Vector3(float(move.get("x", 0.0)), float(move.get("y", 0.0)), float(move.get("z", 0.0)))
	_facing = float(move.get("f", 0.0))
	if not _placed or position.distance_to(_target) > JUMP:
		position = _target
		rotation.y = _facing
		_placed = true
	_model.move_speed = float(move.get("s", 0.0))
	_model.pose = StringName(String(move.get("p", "")))
	_model.sleeping = bool(move.get("sl", false))
	_model.inside = bool(move.get("in", false))


## The name over her head (for tests).
func name_shown() -> String:
	return _name.text


## Her character (for tests).
func get_model() -> PlayerModel:
	return _model


func _process(delta: float) -> void:
	var step := 1.0 - exp(-CATCH_UP * delta)
	position = position.lerp(_target, step)
	rotation.y = lerp_angle(rotation.y, _facing, step)
