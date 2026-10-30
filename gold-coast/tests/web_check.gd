extends Node
## A check of the web build, in a real web browser. The "Web check" export
## preset makes a build that starts here instead of with the title screen. It:
## 1. checks it's in a browser, drawing with the Compatibility renderer (WebGL 2),
##    with storage that lasts between visits
## 2. starts the town and measures the frame rate for a few seconds
## 3. saves the game, waits a moment, and reloads the page
## 4. after the reload, checks the saved game is still there
## Each check, then WEB CHECK PASS (or FAIL), goes to the browser's console, and
## the result goes into the page's title. They show on the page too, for a
## person trying it in a browser (it takes about 15 seconds).

const STEP_FILE := "user://web_check_step.json"
const SAVE_FILE := "user://web_check_save.json"
const MONEY := 4321

var _failures := 0
var _report: Label


func _ready() -> void:
	_make_report()
	GameState.save_path = SAVE_FILE
	if FileAccess.file_exists(STEP_FILE):
		_after_reload()
	else:
		await _first_visit()


func _first_visit() -> void:
	_check(OS.has_feature("web"), "it's running in a web browser")
	_check(RenderingServer.get_current_rendering_method() == "gl_compatibility",
			"it draws with the Compatibility renderer (WebGL 2)")
	_check(OS.is_userfs_persistent(), "the browser keeps the game's files (its saves) between visits")
	GameState.reset()
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(4.0).timeout # the town gets going
	var frames := Engine.get_frames_drawn()
	var started := Time.get_ticks_msec()
	await get_tree().create_timer(5.0).timeout
	var fps := (Engine.get_frames_drawn() - frames) / ((Time.get_ticks_msec() - started) / 1000.0)
	_note("about %.0f frames a second" % fps)
	GameState.money = MONEY
	_check(GameState.save_game(), "the game saves")
	# What the page shows so far, to show again after the reload.
	var step := FileAccess.open(STEP_FILE, FileAccess.WRITE)
	step.store_string(JSON.stringify({"failures": _failures, "report": _report.text}))
	step.close()
	_report.text += "Reloading the page...\n"
	await get_tree().create_timer(2.0).timeout # time for the browser to store the files
	JavaScriptBridge.eval("location.reload()")


func _after_reload() -> void:
	var step: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STEP_FILE))
	DirAccess.remove_absolute(STEP_FILE)
	_failures = int(step.failures)
	_report.text = step.report
	_check(GameState.load_game() and GameState.money == MONEY, "after reloading the page, the saved game is still there")
	GameState.delete_save()
	var result := "WEB CHECK PASS" if _failures == 0 else "WEB CHECK FAIL (%d)" % _failures
	print(result)
	_report.text += "\n" + result
	_report.add_theme_color_override("font_color", Color.PALE_GREEN if _failures == 0 else Color.SALMON)
	JavaScriptBridge.eval("document.title = '%s'" % result)


func _check(passed: bool, what: String) -> void:
	_note("%s  %s" % ["PASS" if passed else "FAIL", what])
	if not passed:
		_failures += 1


# A line for the console and the page.
func _note(line: String) -> void:
	print("WEB CHECK: " + line)
	_report.text += line + "\n"


# The checks on the page: white writing on a dark panel, over the game.
func _make_report() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100 # above the game's own screens (its HUD is on layer 2)
	add_child(layer)
	_report = Label.new()
	_report.position = Vector2(16, 16)
	_report.add_theme_font_size_override("font_size", 18)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	panel.set_content_margin_all(12.0)
	_report.add_theme_stylebox_override("normal", panel)
	_report.text = "The web check (about 15 seconds)\n\n"
	layer.add_child(_report)
