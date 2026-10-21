extends Node
## Runs every tests/test_*.gd file, then quits with exit code 0 if every
## check passed, or 1 if any failed. Run it from the gold-coast folder:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/test_runner.tscn

const TESTS_FOLDER := "res://tests"
const NOT_TESTS: Array[String] = ["test_case.gd", "test_runner.gd"]


func _ready() -> void:
	var failures := 0
	var files := DirAccess.get_files_at(TESTS_FOLDER)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file in NOT_TESTS:
			continue
		print(file)
		var test: TestCase = load(TESTS_FOLDER.path_join(file)).new()
		add_child(test)
		await test.run_tests()
		failures += test.failures
		test.queue_free()

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		print("%d CHECK(S) FAILED" % failures)
	get_tree().quit(1 if failures > 0 else 0)
