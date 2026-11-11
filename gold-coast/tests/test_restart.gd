extends TestCase
## Checks restarting from the phone's menu (LOG OUT, LOAD GAME, and NEW GAME all
## do it, with GameState.restart_scene()):
## - the town that was running is freed at once, so nothing still waiting in it
##   (like a chicken halfway through a walk) wakes up after it's left the tree:
##   in the web build, that froze the game
## - a fresh town is the game's scene, and begins as asked: straight into a new
##   game, or with the title screen

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


## Waits a frame at a time, as the townspeople and chickens do, and says so if
## it ever wakes up out of the tree.
class Waiter extends Node:
	var woke_outside: Array = []

	func _ready() -> void:
		_wait()

	func _wait() -> void:
		while true:
			await Engine.get_main_loop().process_frame
			if not is_inside_tree():
				woke_outside.append(name)
				return


func run_tests() -> void:
	var runner := get_tree().current_scene
	GameState.reset()
	GameState.time_speed = 0.0
	# The town as the game's own scene, as when you play (not inside this test).
	var main := MAIN_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(main)
	await wait_until(func() -> bool: return main.is_inside_tree(), 1.0)
	get_tree().current_scene = main
	await wait_physics_frames(5)
	if get_tree().current_scene != main:
		check(false, "the town is the game's scene, ready to restart")
		return
	var waiter := Waiter.new()
	main.add_child(waiter)
	var woke_outside := waiter.woke_outside
	await wait_physics_frames(2)

	GameState.restart_scene("new")
	await wait_physics_frames(10)
	var fresh := get_tree().current_scene
	check(not is_instance_valid(main) and woke_outside.is_empty(),
			"restarting frees the old town at once: nothing in it wakes up after it's left the tree")
	check(fresh != null and fresh.is_inside_tree() and fresh.scene_file_path == MAIN_SCENE.resource_path
			and not (fresh.get_node("HUD/TitleScreen") as TitleScreen).is_open(),
			"  ...and a fresh town is the game's scene, straight into a new game (NEW GAME)")

	GameState.restart_scene("")
	await wait_physics_frames(10)
	var again := get_tree().current_scene
	check(again != null and not is_instance_valid(fresh) and (again.get_node("HUD/TitleScreen") as TitleScreen).is_open(),
			"  ...or with the title screen (LOG OUT)")

	# Back to the test runner as the scene.
	get_tree().current_scene = runner
	if again != null:
		again.queue_free()
	await wait_physics_frames(2)
	get_tree().paused = false
	GameState.reset()
