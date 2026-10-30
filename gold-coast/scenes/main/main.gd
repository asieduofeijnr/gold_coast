extends Node3D
## The game's main scene: the neighborhood, the player, the camera, and the HUD.
## When the game starts, the title screen asks whether to carry on from the
## saved game or start a new one. Loading the save or starting a new game from
## the phone's menu reloads this scene, and skips the title screen.
## The game saves when she goes to bed at home, or from the phone's menu.

# Where she stands at the start of a new game.
var _start_spot: Vector3
var _start_facing := 0.0

@onready var player: Player = $Player
@onready var title_screen: TitleScreen = $HUD/TitleScreen
@onready var pause_menu: PauseMenu = $HUD/PauseMenu


func _ready() -> void:
	_start_spot = player.global_position
	_start_facing = player.rotation.y
	title_screen.started.connect(_on_title_screen_started)
	pause_menu.restart_requested.connect(restart)
	# Only when this is the game itself: tests load this scene inside their own.
	if get_tree().current_scene != self:
		return
	var how := GameState.start_with
	GameState.start_with = ""
	if how == "load":
		if GameState.load_game():
			continue_from_save()
	elif how == "":
		title_screen.open()
	# ("new": GameState was reset before this scene loaded.)


## Starts again: carrying on from the saved game ("load"), or a new game
## ("new"). The scene loads again, so the whole town starts afresh.
func restart(how: String) -> void:
	get_tree().paused = false
	if how == "new":
		GameState.reset()
	if get_tree().current_scene == self:
		GameState.start_with = how
		get_tree().reload_current_scene()
	elif how == "load": # in a test: carry on right here
		if GameState.load_game():
			continue_from_save()
	else:
		player.place(_start_spot, _start_facing)


## After loading a saved game, she's back where she was: in her bed at home
## (asleep, until she's rested), or on the spot where the game was saved.
func continue_from_save() -> void:
	if GameState.in_bed:
		var door := ($Home as Home).door
		player.place(door.global_position + Vector3(0, 0.05, 0), player.rotation.y)
		player.act_at(door, &"", Callable())
	elif GameState.spot_loaded:
		player.place(GameState.player_position, GameState.player_facing)
	($IsoCamera as IsoCamera).snap()


func _on_title_screen_started(continuing: bool) -> void:
	if continuing and GameState.load_game():
		continue_from_save()
