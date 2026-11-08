extends RefCounted

const ROAD := preload("res://assets/road.gdshader")
const WATER := preload("res://assets/river.gdshader")
const TEXTURE_ROOT := "res://assets/textures/"
const STONE := ["rock_surface", 0.57, 0.78]
const WOOD := ["wood_planks_grey", 0.88, 0.58]
const GRASS := ["grass_ground", 0.42, 0.54]
const CLOTH := ["valbrume_laine", 7.2, 0.27]
const LEATHER := ["fabric_leather_01", 4.3, 0.24]
const PAVING := ["rock_surface", 0.94, 0.71]
const SURFACES := {
	"Mortier": STONE, "Pierre": STONE, "Pierre claire": STONE, "Pierre ombre": STONE,
	"Pierre grise": STONE, "Pierre mousse": STONE, "Roche": ["rock_surface", 0.23, 1.0],
	"Cour": ["stony_dirt_path", 0.38, 0.88],
	"Pavé": ["stony_dirt_path", 0.41, 0.71],
	"Dalle": ["cobblestone_floor_03", 0.46, 0.91],
	"Calcaire": PAVING, "Dalle sombre": PAVING, "Dalle claire": PAVING, "Dalle olive": PAVING,
	"Chêne": WOOD, "Chêne clair": WOOD, "Écorce": ["pine_bark", 1.1, 0.64],
	"Ardoise": ["roof_slates_03", 0.43, 0.75],
	"Ardoise claire": ["roof_slates_03", 0.43, 0.57],
	"Ardoise patine": ["roof_slates_03", 0.43, 0.60],
	"Crépi": ["white_rough_plaster", 0.64, 0.57],
	"Herbe": GRASS, "Herbe claire": GRASS, "Herbe ombre": GRASS,
	"Terre": ["forest_floor", 0.70, 0.63],
	"Tunique": CLOTH, "Bordeaux": CLOTH, "Lin": CLOTH, "Toile": CLOTH,
	"Braies": CLOTH, "Fourrure": CLOTH, "Velours": CLOTH, "Gambison": CLOTH,
	"Cuir": LEATHER, "Cuir sombre": LEATHER, "Semelle": LEATHER,
	"Maille": ["valbrume_maille", 7.2, 0.32],
}

var cache: Dictionary = {}


func dress(node: Node3D, fixed: bool) -> void:
	if node is MeshInstance3D:
		_dress_mesh(node, fixed)
	for child in node.get_children():
		if child is Node3D:
			dress(child, fixed)


func _dress_mesh(instance: MeshInstance3D, fixed: bool) -> void:
	for index in instance.mesh.get_surface_count():
		var original := instance.mesh.surface_get_material(index) as StandardMaterial3D
		if original == null:
			continue
		var label := original.resource_name.get_slice(".", 0)
		if label == "Eau" and instance.name.begins_with("vallee"):
			var water := ShaderMaterial.new()
			water.shader = WATER
			instance.set_surface_override_material(index, water)
		elif label in ["Chemin vallée", "Chemin traverse"]:
			instance.set_surface_override_material(index, _road(label == "Chemin traverse"))
		elif SURFACES.has(label):
			var key := "%s/%s" % [label, fixed]
			if not cache.has(key):
				cache[key] = _textured(original, SURFACES[label], fixed)
			instance.set_surface_override_material(index, cache[key])


func _textured(original: StandardMaterial3D, spec: Array, fixed: bool) -> StandardMaterial3D:
	var mat := original.duplicate() as StandardMaterial3D
	var prefix: String = TEXTURE_ROOT + spec[0]
	mat.albedo_texture = load(prefix + "_albedo.jpg") as Texture2D
	mat.normal_texture = load(prefix + "_normal.jpg") as Texture2D
	mat.roughness_texture = load(prefix + "_roughness.jpg") as Texture2D
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.normal_enabled = true
	mat.normal_scale = spec[2]
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = fixed
	mat.uv1_triplanar_sharpness = 5.0
	mat.uv1_scale = Vector3.ONE * float(spec[1])
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Keep the photographed albedo readable while retaining each original material's tint.
	if spec[0] == "valbrume_laine" or spec[0] == "valbrume_maille":
		mat.albedo_color = Color.WHITE.lerp(original.albedo_color, 0.94)
	else:
		mat.albedo_color = Color.WHITE.lerp(original.albedo_color, 0.52 if fixed else 0.68)
	return mat


func _road(crossing: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ROAD
	material.set_shader_parameter("gravel", load(TEXTURE_ROOT + "stony_dirt_path_albedo.jpg"))
	material.set_shader_parameter("meadow", load(TEXTURE_ROOT + "grass_ground_albedo.jpg"))
	material.set_shader_parameter("grit", load(TEXTURE_ROOT + "stony_dirt_path_normal.jpg"))
	material.set_shader_parameter("crossing", crossing)
	return material
