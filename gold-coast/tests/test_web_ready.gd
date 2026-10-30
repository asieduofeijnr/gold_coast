extends TestCase
## Checks the web build's setup, and what makes the game look right and run fast
## in a browser:
## - each character is drawn in one or two parts instead of one per color
##   (with its own colors kept, and still bending with its skeleton)
## - characters only animate while they're on the screen
## - the Compatibility renderer's look, and the desktop look left alone
## - the Web export presets (no threads, the tests left out) and the web check
## - F8 shows the frame rate (in builds made for testing)

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func run_tests() -> void:
	GameState.reset()
	GameState.time_speed = 0.0
	GameState.town_life = true
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await wait_physics_frames(10)
	_check_parts(main)
	_check_on_screen_animation(main)
	_check_look(main)
	_check_presets()
	await _check_fps(main)
	main.queue_free()
	await get_tree().process_frame
	GameState.town_life = false
	GameState.reset()


func _check_parts(main: Node) -> void:
	var bodies: Array[MeshInstance3D] = []
	for mesh_instance: MeshInstance3D in main.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.skin != null:
			bodies.append(mesh_instance)
	var parts := 0
	var most := 0
	var bending := true
	for body in bodies:
		parts += body.mesh.get_surface_count()
		most = maxi(most, body.mesh.get_surface_count())
		var bones: Variant = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_BONES]
		bending = bending and bones != null and not (bones as PackedInt32Array).is_empty()
	check(bodies.size() > 30 and most <= 2 and bending,
			"%d characters are drawn in %d parts in all (at most %d each, from up to 7), and still bend with their skeletons"
			% [bodies.size(), parts, most])
	var trader := main.get_node("Market/Trader") as Vendor
	var trader_body := trader.find_children("*", "MeshInstance3D")[0] as MeshInstance3D
	var colors: Variant = trader_body.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] # null if it has none
	var top := Palette.color(trader.top_color)
	var wearing := false
	for color: Color in (colors if colors is PackedColorArray else PackedColorArray()):
		if color.is_equal_approx(top):
			wearing = true
			break
	check(wearing and trader_body.mesh.surface_get_material(0).vertex_color_use_as_albedo,
			"  ...each in their own colors (Madam Serwaa's top is still hers)")


func _check_on_screen_animation(main: Node) -> void:
	var person: Townsperson = (main.get_node("TownLife") as TownLife).people[0]
	var player := person.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var notifier: VisibleOnScreenNotifier3D = null
	for child in person.get_children(true):
		if child is VisibleOnScreenNotifier3D:
			notifier = child
	var still := false
	if notifier != null:
		player.active = true # as if the camera could see them
		notifier.screen_exited.emit()
		still = not player.active
		notifier.screen_entered.emit()
	check(notifier != null and still and player.active,
			"townspeople only animate while the camera can see them (off the screen, they hold still)")


func _check_look(main: Node) -> void:
	var lighting := main.get_node("Lighting") as Lighting
	var desktop := (lighting.get_node("WorldEnvironment") as WorldEnvironment).environment
	var web := Lighting.compatibility_environment(desktop)
	check(web.tonemap_mode == Environment.TONE_MAPPER_LINEAR and is_equal_approx(web.tonemap_exposure, 0.94)
			and web.adjustment_enabled and is_equal_approx(web.adjustment_contrast, 0.86)
			and is_equal_approx(web.adjustment_saturation, 1.15),
			"with the web's renderer, daylight isn't washed out: a linear tone map, a little darker, less contrast, more color")
	check(desktop.tonemap_mode == Environment.TONE_MAPPER_FILMIC and not desktop.adjustment_enabled,
			"  ...and the desktop game's own look is left as it is")


func _check_presets() -> void:
	var presets := ConfigFile.new()
	var found := presets.load("res://export_presets.cfg") == OK
	var web := ""
	var check_build := ""
	for section in presets.get_sections():
		if presets.get_value(section, "name", "") == "Web":
			web = section
		elif presets.get_value(section, "name", "") == "Web check":
			check_build = section
	check(found and web != "" and presets.get_value(web, "platform", "") == "Web"
			and presets.get_value(web, "export_path", "") == "build/web/index.html"
			and presets.get_value(web, "exclude_filter", "") == "tests/*"
			and presets.get_value(web + ".options", "variant/thread_support", true) == false,
			"the Web export builds into build/web, without threads (so any web host works), and leaves the tests out")
	check(check_build != "" and presets.get_value(check_build, "custom_features", "") == "web_check"
			and ProjectSettings.get_setting("application/run/main_scene.web_check", "") == "res://tests/web_check.tscn",
			"  ...and the Web check build starts with the web check instead of the game")


func _check_fps(main: Node) -> void:
	var hud := main.get_node("HUD")
	await press_action("debug_show_fps")
	await wait_physics_frames(2)
	var showing: bool = hud.is_showing_fps()
	await press_action("debug_show_fps")
	check(showing and not hud.is_showing_fps(), "F8 shows the frame rate, and hides it again")
