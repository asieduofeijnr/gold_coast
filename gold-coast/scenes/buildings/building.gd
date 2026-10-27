@tool
class_name Building
extends Node3D
## A building made in Blender (a .glb file from blender/scripts/build_buildings.py).
## The model brings its own collision box, so the player can't walk through it.
## Its front faces +Z. Pointing at it with the mouse shows its name over the roof
## (see BuildingNames).

## How far above the roof its name shows, in metres.
const NAME_GAP := 0.6
## The physics layer for shapes that only block the view, never the player:
## the roof copies the see-through check looks at (layer 2).
const VIEW_ONLY_LAYER := 2

## The building's model, e.g. art/models/buildings/chop_bar.glb.
@export var model: PackedScene:
	set(value):
		model = value
		_rebuild()
## What kind of building it is, like "Apartment Block", shown when you point at it.
@export var building_name := "Building"
## Its own name, shown underneath, like "Adom Court" ("" for none).
@export var subtitle := ""

## The model, placed by this script. It's an "internal" child: hidden in the
## scene tree and never saved, because the `model` setting is enough to remake it.
var model_instance: Node3D

## How see-through the building is, from 0 (solid) to 1 (invisible). SeeThrough
## raises it while the building stands between the camera and the player.
var fade := 0.0:
	set(value):
		fade = value
		for mesh_instance in _meshes:
			mesh_instance.transparency = value

var _meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	_rebuild()


## The Building that `node` (say, a collision shape the mouse is pointing at)
## is part of, or null if it isn't part of one.
static func find_from(node: Node) -> Building:
	while node != null and not node is Building:
		node = node.get_parent()
	return node as Building


## How high over the building's base its name shows, in metres.
func name_height() -> float:
	return bounds().end.y - global_position.y + NAME_GAP


## The box around the whole building, roof included, in world space.
func bounds() -> AABB:
	var box := AABB()
	for mesh_instance in _meshes:
		var mesh_box := mesh_instance.global_transform * mesh_instance.get_aabb()
		box = mesh_box if box.size == Vector3.ZERO else box.merge(mesh_box)
	return box


func _rebuild() -> void:
	if not is_node_ready():
		return
	if model_instance != null:
		model_instance.free()
		model_instance = null
	_meshes.clear()
	if model != null:
		model_instance = model.instantiate() as Node3D
		add_child(model_instance, false, Node.INTERNAL_MODE_FRONT)
		for mesh_instance in model_instance.find_children("*", "MeshInstance3D"):
			_meshes.append(mesh_instance)
		# The roof copy blocks the view (for SeeThrough) but must never block the player.
		for occluder: StaticBody3D in model_instance.find_children("RoofOccluder*", "StaticBody3D"):
			occluder.collision_layer = VIEW_ONLY_LAYER
			occluder.collision_mask = 0
