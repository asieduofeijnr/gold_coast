class_name BuildingNames
extends Node
## Shows a building's name over its roof while the mouse points at it (a
## Nameplate): what kind of building it is, and its own name underneath. Names
## aren't shown all the time, because most buildings already have theirs
## painted on.

## The name over the roof (for tests).
var nameplate: Nameplate
## The building the mouse is pointing at, or null.
var pointed: Building

var _mouse_in_window := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # so it can hide the name while a menu has the game paused
	var layer := CanvasLayer.new()
	add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	nameplate = Nameplate.new()
	nameplate.visible = false
	layer.add_child(nameplate)
	get_window().mouse_entered.connect(func() -> void: _mouse_in_window = true)
	get_window().mouse_exited.connect(func() -> void: _mouse_in_window = false)


# Physics queries are only safe during the physics step, so this runs there.
func _physics_process(_delta: float) -> void:
	# No names while a menu is open, the mouse is off the window, or it's over the phone.
	if _mouse_in_window and not get_tree().paused and get_viewport().gui_get_hovered_control() == null:
		point_at(get_viewport().get_mouse_position())
	else:
		_show(null)


## Points at whatever shows at `screen_position`, as the mouse does every step:
## if it's a building, its name shows. Returns the building (or null).
func point_at(screen_position: Vector2) -> Building:
	_show(_building_at(screen_position))
	return pointed


func _building_at(screen_position: Vector2) -> Building:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var from := camera.project_ray_origin(screen_position)
	var to := from + camera.project_ray_normal(screen_position) * camera.far
	var query := PhysicsRayQueryParameters3D.create(from, to, Player.CLICK_LAYERS)
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player != null:
		query.exclude = [player.get_rid()] # look past her, at what's behind
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	return null if hit.is_empty() else Building.find_from(hit.collider)


func _show(building: Building) -> void:
	if building == pointed:
		return
	pointed = building
	if building == null:
		nameplate.disappear()
		return
	nameplate.anchor = building
	nameplate.height = building.name_height()
	nameplate.title = building.building_name
	nameplate.subtitle = building.subtitle
	nameplate.appear()
