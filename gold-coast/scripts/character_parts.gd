class_name CharacterParts
## Draws a 3D character in as few parts as it can. The character models have one
## part per color (skin, top, skirt, trim, duku...), and the Compatibility
## renderer (the one web browsers use) has to bend every part of every character
## every frame, so fifty people in town made it slow. Merging the plain parts
## into one, keeping each part's color as the mesh's vertex colors, nearly
## doubled the frame rate. Shiny parts (gold jewelry) stay as they are, except
## with the Compatibility renderer, where they're merged too (still gold, but no
## longer shiny: they're tiny, and it's quicker still).


## Merges `body`'s plain parts into one. Call it once the character is dressed:
## the colors it keeps are the ones showing (override materials included).
static func merge(body: MeshInstance3D) -> void:
	var mesh := body.mesh
	if mesh == null:
		return
	var plain: Array[int] = []
	var shiny: Array[int] = []
	var merge_shiny := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	for i in mesh.get_surface_count():
		var material := _material(body, i)
		if material != null and (material.metallic < 0.01 or merge_shiny):
			plain.append(i)
		else:
			shiny.append(i)
	if plain.size() < 2:
		return
	var tool := SurfaceTool.new()
	var colors := PackedColorArray()
	for i in plain:
		tool.append_from(mesh, i, Transform3D.IDENTITY)
		var part := PackedColorArray()
		part.resize(mesh.surface_get_array_len(i))
		part.fill(_material(body, i).albedo_color)
		colors.append_array(part)
	var arrays := tool.commit_to_arrays()
	if (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() != colors.size():
		return # the parts didn't line up as expected, so leave it as it was
	arrays[Mesh.ARRAY_COLOR] = colors
	var merged := ArrayMesh.new()
	merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, _flags(mesh, plain[0]))
	merged.surface_set_material(0, _vertex_color_material())
	for i in shiny:
		merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(i), [], {}, _flags(mesh, i))
		merged.surface_set_material(merged.get_surface_count() - 1, _material(body, i))
	for i in body.get_surface_override_material_count():
		body.set_surface_override_material(i, null)
	body.mesh = merged


# The material a part shows: the character's own (an override) if it has one.
static func _material(body: MeshInstance3D, surface: int) -> StandardMaterial3D:
	var material := body.get_surface_override_material(surface)
	if material == null:
		material = body.mesh.surface_get_material(surface)
	return material as StandardMaterial3D


# Keeps how many bones can move each point of the mesh.
static func _flags(mesh: Mesh, surface: int) -> int:
	return mesh.surface_get_format(surface) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS


# One material for every merged character, showing the vertex colors. It's kept
# on the scene tree rather than in a static variable (see Palette.material()).
static func _vertex_color_material() -> StandardMaterial3D:
	var tree := Engine.get_main_loop()
	if not tree.has_meta(&"character_material"):
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true # the colors are written like albedo colors
		material.roughness = 0.85 # the same as the models' cloth and skin
		tree.set_meta(&"character_material", material)
	return tree.get_meta(&"character_material")
