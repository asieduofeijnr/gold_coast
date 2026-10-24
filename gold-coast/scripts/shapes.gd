@tool
class_name Shapes
## Small helpers for building placeholder scenery out of simple shapes.


## A box you can see: the given size and palette color, centered at `at`.
static func box(box_size: Vector3, at: Vector3, color_name: Palette.ColorName) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	var box_instance := MeshInstance3D.new()
	box_instance.mesh = mesh
	box_instance.material_override = Palette.material(color_name)
	box_instance.position = at
	return box_instance


## A box you bump into (a collision shape), centered at `at`. It only works
## as a direct child of a physics body, such as a StaticBody3D.
static func solid_box(box_size: Vector3, at: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = box_size
	var solid := CollisionShape3D.new()
	solid.shape = shape
	solid.position = at
	return solid
