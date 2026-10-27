extends Node
## Runs every tests/test_*.gd file, then quits with exit code 0 if every
## check passed, or 1 if any failed. Run it from the gold-coast folder:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/test_runner.tscn
## To run just some files, name them after "--":
##   ... res://tests/test_runner.tscn -- test_chop_bar.gd test_home.gd

const TESTS_FOLDER := "res://tests"
const NOT_TESTS: Array[String] = ["test_case.gd", "test_runner.gd"]
## Tests save to their own file, so they never touch your saved game.
const TEST_SAVE := "user://test_save.json"


func _ready() -> void:
	GameState.save_path = TEST_SAVE
	GameState.town_life = false # tests that want townspeople switch them on
	var failures := 0
	var files := DirAccess.get_files_at(TESTS_FOLDER)
	files.sort()
	var only := OS.get_cmdline_user_args() # the file names after "--", if any
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file in NOT_TESTS:
			continue
		if not only.is_empty() and file not in only:
			continue
		print(file)
		var test: TestCase = load(TESTS_FOLDER.path_join(file)).new()
		add_child(test)
		await test.run_tests()
		failures += test.failures
		test.queue_free()

	GameState.delete_save()
	# Give any sound still playing (like the phone's text beep) a moment to be
	# cleaned up, or Godot reports it as leaked when the game quits.
	await get_tree().create_timer(0.3).timeout
	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		print("%d CHECK(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)
