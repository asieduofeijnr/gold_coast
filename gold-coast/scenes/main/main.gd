extends Node3D
## The game's main scene: the neighborhood, the player, the camera, and the HUD.
## When the game starts, it carries on from the saved game if there is one.
## The game saves each time she goes to bed at home (see GameState).


func _ready() -> void:
	# Only when this is the game itself: tests load this scene inside their own.
	if get_tree().current_scene == self and GameState.load_game():
		continue_from_save()


## After loading a saved game: the game saved when she went to bed, so she's
## back in her bed at home, asleep, and gets up when she's rested.
func continue_from_save() -> void:
	if not GameState.in_bed:
		return
	var door := ($Home as Home).door
	var player := $Player as Player
	player.global_position = door.global_position + Vector3(0, 0.05, 0)
	player.reset_physics_interpolation()
	player.act_at(door, &"", Callable())
