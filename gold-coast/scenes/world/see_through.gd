class_name SeeThrough
extends Node
## Fades out any building standing between the camera and the player, so she
## never disappears behind one. It turns solid again once she moves on.
## Anything else in the "see_through" group with a `fade` setting (like a
## market umbrella) fades the same way.
##
## It looks along lines of sight from the player toward the camera and sees
## which buildings they pass through: their walls, or the invisible copy of
## their roof (which is on its own physics layer, so it never blocks walking).

# Heights on the player that must stay visible: her feet, middle, and head.
const CHECK_HEIGHTS := [0.15, 0.9, 1.7]
# Physics layers the lines of sight test: 1 (walls and other solid things)
# and 2 (roof copies, for seeing only).
const SIGHT_LAYERS := 0b11
## The group for things besides buildings that fade when they're in the way.
const GROUP := &"see_through"

## Who must stay visible (the player).
@export var target: Node3D
## The node whose children are the buildings that can fade.
@export var buildings: Node
## How see-through a building in the way becomes: 0 = solid, 1 = invisible.
@export_range(0.0, 1.0) var faded := 0.7
## How long fading in or out takes, in seconds.
@export var fade_time := 0.2


# Physics queries are only safe during the physics step, so this runs there.
func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or target == null or buildings == null:
		return
	# The camera looks along its -Z axis, so its +Z points back toward it. With
	# an orthographic camera, every line of sight runs in that same direction.
	var toward_camera := camera.global_basis.z * camera.far
	var in_the_way: Array[Node] = []
	for height: float in CHECK_HEIGHTS:
		var point := target.global_position + Vector3.UP * height
		for thing in _things_on_line(point, point + toward_camera):
			if thing not in in_the_way:
				in_the_way.append(thing)
	var step := faded * delta / fade_time
	for thing in _fading_things():
		var goal := faded if thing in in_the_way else 0.0
		var fade: float = thing.get("fade")
		if fade != goal:
			thing.set("fade", move_toward(fade, goal, step))


# Everything that can fade: the buildings, and anything in the see_through group.
func _fading_things() -> Array[Node]:
	var things: Array[Node] = []
	for child in buildings.get_children():
		if child is Building:
			things.append(child)
	things.append_array(get_tree().get_nodes_in_group(GROUP))
	return things


## Every building (or other fading thing) the line from `from` to `to` passes through.
func _things_on_line(from: Vector3, to: Vector3) -> Array[Node]:
	var found: Array[Node] = []
	var query := PhysicsRayQueryParameters3D.create(from, to, SIGHT_LAYERS)
	var skip: Array[RID] = []
	if target is CollisionObject3D:
		skip.append((target as CollisionObject3D).get_rid())
	var space := target.get_world_3d().direct_space_state
	for i in 8: # a ray stops at the first thing it hits, so cast again past it
		query.exclude = skip
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		skip.append(hit.rid)
		var thing := _fading_thing_of(hit.collider)
		if thing != null and thing not in found:
			found.append(thing)
	return found


## The Building (or other fading thing) a hit shape belongs to, if any. The
## billboard, for one, doesn't belong to any.
func _fading_thing_of(node: Node) -> Node:
	while node != null and not (node is Building or node.is_in_group(GROUP)):
		node = node.get_parent()
	return node
