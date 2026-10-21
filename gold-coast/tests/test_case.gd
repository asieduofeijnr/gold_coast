class_name TestCase
extends Node
## Base class for test files. Each test file extends this, overrides
## run_tests(), and calls check() for every thing it wants to verify.

var failures := 0


## Override this in each test file.
func run_tests() -> void:
	await get_tree().process_frame


## Records one check and prints PASS or FAIL.
func check(passed: bool, description: String) -> void:
	if passed:
		print("  PASS  ", description)
	else:
		failures += 1
		print("  FAIL  ", description)


## Waits for a number of physics steps (60 steps = 1 second of game time).
func wait_physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
