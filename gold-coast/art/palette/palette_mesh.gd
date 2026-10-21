@tool
class_name PaletteMesh
extends MeshInstance3D
## A mesh that gets its color from the palette. Pick "Color Name" in the
## Inspector and the color always matches palette.gd.

@export var color_name := Palette.ColorName.CONCRETE:
	set(value):
		color_name = value
		material_override = Palette.material(color_name)


func _ready() -> void:
	material_override = Palette.material(color_name)


# Hide the material from the Inspector and don't save it into scene files.
# The palette is the only place colors live, so it's re-applied on load.
func _validate_property(property: Dictionary) -> void:
	if property.name == "material_override":
		property.usage &= ~(PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR)
