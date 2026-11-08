extends Node3D

const Surfaces = preload("res://scripts/surfaces.gd")
const OAK := preload("res://assets/chene.glb")
const TREE := preload("res://assets/nature/arbre.glb")
const GRASS := preload("res://assets/nature/touffe.glb")
const REEDS := preload("res://assets/nature/herbes.glb")
const SHRUB := preload("res://assets/nature/arbuste.glb")
const ROCK := preload("res://assets/nature/rocher.glb")
const TREE_CELL_SIZE := 28.0
const DETAIL_CELL_SIZE := 20.0
const TREE_SHADOW_DISTANCE := 48.0

var random := RandomNumberGenerator.new()
var trunks: Array[Vector3] = []
var surfaces := Surfaces.new()


func _ready() -> void:
	random.seed = 1840
	var trees: Array[Transform3D] = []
	var oaks: Array[Transform3D] = []
	var shrubs: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	var grass: Array[Transform3D] = []
	var reeds: Array[Transform3D] = []
	for point in [Vector2(-19, 15), Vector2(19, 14), Vector2(-18, -7), Vector2(19, -14)]:
		oaks.append(_transform(point.x, 0.08, point.y, 0.68, 0.83))
		trunks.append(Vector3(point.x, 0.0, point.y))
	for point in [Vector2(-6.7, 66), Vector2(7.1, 65), Vector2(-8.3, 71),
			Vector2(7.2, 74), Vector2(-6.1, 77), Vector2(6.5, 80), Vector2(11, 59)]:
		oaks.append(_transform(point.x, 0, point.y, 1.15, 1.64))
		trunks.append(Vector3(point.x, 0.0, point.y))
	for i in 118:
		var x := random.randf_range(-63.0, 63.0)
		var z := random.randf_range(-38.0, 83.0)
		if (absf(x) < 25.0 and z < 58.0) or absf(x) < 5.0 or (z > 24.0 and z < 36.0):
			continue
		var grove := oaks if i % 3 != 0 else trees
		grove.append(_transform(x, 0, z, 0.76, 1.56))
		trunks.append(Vector3(x, 0, z))
	for i in 65:
		var x := random.randf_range(-47.0, 47.0)
		var z := random.randf_range(34.5, 81.0)
		if absf(x) > 3.1 and not _on_path(x, z):
			shrubs.append(_transform(x, 0, z, 0.27, 0.76))
			rocks.append(_transform(x + 0.6, -0.08, z + 1.2, 0.19, 0.52))
	for side in [-1.0, 1.0]:
		for i in 370:
			var x := random.randf_range(2.28, 32.0) * float(side)
			var z := random.randf_range(22.85, 81.0)
			if _on_path(x, z) or (z > 26.2 and z < 33.6):
				continue
			grass.append(_transform(x, 0, z, 0.78, 2.3))
		for i in 145:
			var x := random.randf_range(2.45, 40.0) * float(side)
			var z := random.randf_range(0.17, 0.98)
			z = 26.45 - z if i % 2 == 0 else 33.38 + z
			reeds.append(_transform(x, 0, z, 0.9, 2.42))
		for i in 70:
			var x := random.randf_range(19.8, 21.35) * float(side)
			var z := random.randf_range(-19.5, 20.8)
			grass.append(_transform(x, 0.08, z, 0.48, 1.33))
		for z in [-5.5, 13.0, 18.8]:
			shrubs.append(_transform(20.2 * float(side), 0.08, z, 0.33, 0.53))
	_batch(OAK, oaks, TREE_CELL_SIZE, 0.0, 0.85, true)
	_batch(TREE, trees, TREE_CELL_SIZE, 0.0, 0.65, true)
	_batch(SHRUB, shrubs, DETAIL_CELL_SIZE, 58.0, 0.72)
	_batch(ROCK, rocks, DETAIL_CELL_SIZE, 82.0, 0.85)
	_batch(GRASS, grass, DETAIL_CELL_SIZE, 38.0, 0.76)
	_batch(REEDS, reeds, DETAIL_CELL_SIZE, 46.0, 0.76)


func _on_path(x: float, z: float) -> bool:
	return absf(x) < 2.0 or (absf(z - 47.0) < 2.0 and absf(x) < 25.0)


func _transform(x: float, y: float, z: float, min_scale: float, max_scale: float) -> Transform3D:
	var scale_value := random.randf_range(min_scale, max_scale)
	var basis := Basis(Vector3.UP, random.randf() * TAU).scaled(Vector3.ONE * scale_value)
	return Transform3D(basis, Vector3(x, y, z))


func _batch(scene: PackedScene, placements: Array[Transform3D], cell_size: float,
		view_distance: float, lod_bias: float, tree_shadows: bool = false) -> void:
	var cells: Dictionary[Vector2i, Array] = {}
	for placement in placements:
		var cell := Vector2i(floori(placement.origin.x / cell_size), floori(placement.origin.z / cell_size))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(placement)

	var source := scene.instantiate() as Node3D
	var mesh_node := source.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mesh := mesh_node.mesh.duplicate() as Mesh
	surfaces.dress(mesh_node, false)
	for index in mesh.get_surface_count():
		var material := mesh_node.get_active_material(index) as StandardMaterial3D
		if material and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			material = material.duplicate() as StandardMaterial3D
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold = 0.23
		if material:
			mesh.surface_set_material(index, material)
	source.free()

	# The renderer selects one imported LOD per MultiMesh. Small bounds keep that
	# choice representative of the whole group and let off-screen cells be culled.
	var mesh_bounds := mesh.get_aabb()
	for cell: Vector2i in cells:
		var center := Vector3((cell.x + 0.5) * cell_size, 0.0, (cell.y + 0.5) * cell_size)
		var group: Array = cells[cell]
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = mesh
		batch.instance_count = group.size()
		var bounds := AABB()
		for index in group.size():
			var placement: Transform3D = group[index]
			placement.origin -= center
			batch.set_instance_transform(index, placement)
			var instance_bounds := placement * mesh_bounds
			bounds = instance_bounds if index == 0 else bounds.merge(instance_bounds)
		batch.custom_aabb = bounds
		_add_batch(batch, center, view_distance, lod_bias, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		if tree_shadows:
			_add_batch(batch, center, TREE_SHADOW_DISTANCE, 0.45,
				GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)


func _add_batch(batch: MultiMesh, center: Vector3, view_distance: float, lod_bias: float,
		shadows: GeometryInstance3D.ShadowCastingSetting) -> void:
	var instances := MultiMeshInstance3D.new()
	instances.multimesh = batch
	instances.position = center
	instances.cast_shadow = shadows
	instances.lod_bias = lod_bias
	instances.visibility_range_end = view_distance
	if view_distance > 0.0:
		instances.visibility_range_end_margin = 6.0
	add_child(instances)
