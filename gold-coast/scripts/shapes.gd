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


## A round shape you can see, standing upright and centered at `at`: a
## cylinder, or a bowl or bucket shape if the top and bottom are different sizes.
static func cylinder(top_radius: float, bottom_radius: float, height: float, at: Vector3,
		color_name: Palette.ColorName) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.rings = 1
	var shape := MeshInstance3D.new()
	shape.mesh = mesh
	shape.material_override = Palette.material(color_name)
	shape.position = at
	return shape


## A ball you can see, centered at `at`. `squash` below 1 flattens it into a
## mound (0.5 = half as tall as it is wide).
static func sphere(radius: float, at: Vector3, color_name: Palette.ColorName, squash := 1.0) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 16
	mesh.rings = 8
	var ball := MeshInstance3D.new()
	ball.mesh = mesh
	ball.material_override = Palette.material(color_name)
	ball.position = at
	return ball


## A name that floats in the air and always turns to face the camera.
static func name_label(text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	label.font_size = 64
	label.outline_size = 16
	label.modulate = Palette.color(Palette.ColorName.ROAD_MARKING)
	label.outline_modulate = Palette.color(Palette.ColorName.DARK_BROWN)
	return label
