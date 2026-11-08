extends SceneTree

const Scenery = preload("res://scripts/scenery.gd")
const EXPECTED_VISUAL_INSTANCES := 1237
const EXPECTED_TRUNKS := 89

var failures := 0


func _initialize() -> void:
	call_deferred("_test_batches")


func _test_batches() -> void:
	var scenery := Scenery.new()
	root.add_child(scenery)
	var visual_instances := 0
	var near_shadow_batches := 0
	var bounded_visual_batches := 0
	var full_detail_batches := 0
	var largest_cell := 0.0
	var shadow_batches: Array[MultiMesh] = []
	var visual_batches: Array[MultiMesh] = []
	for batch: MultiMeshInstance3D in scenery.get_children():
		var mesh := batch.multimesh
		var bounds := mesh.custom_aabb
		if batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			near_shadow_batches += 1
			shadow_batches.append(mesh)
			_check(batch.visibility_range_end > 0 and batch.visibility_range_end <= 55,
				"Les ombres de la végétation sont limitées aux cellules proches.")
			continue

		visual_instances += mesh.instance_count
		visual_batches.append(mesh)
		largest_cell = maxf(largest_cell, maxf(bounds.size.x, bounds.size.z))
		if batch.visibility_range_end > 0.0:
			bounded_visual_batches += 1
		if is_equal_approx(batch.lod_bias, 1.0):
			full_detail_batches += 1
		_check(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"Les lots visibles séparent leur géométrie de leurs ombres.")

	_check(visual_instances == EXPECTED_VISUAL_INSTANCES, "La densité d’origine est conservée.")
	_check(scenery.trunks.size() == EXPECTED_TRUNKS, "Les positions de collision des troncs sont conservées.")
	_check(largest_cell > 0.0 and largest_cell <= 52.0,
		"La végétation peut être écartée cellule par cellule.")
	_check(bounded_visual_batches > 0, "Les petits détails ont une distance d’affichage maximale.")
	_check(full_detail_batches < visual_batches.size(), "Les cellules éloignées exploitent les LOD importés.")
	_check(near_shadow_batches > 0, "Les arbres proches gardent leurs ombres.")
	for mesh in shadow_batches:
		_check(mesh in visual_batches, "Les ombres réutilisent les instances des arbres visibles.")
	print("Décor · %d instances, %d cellules visibles, %d cellules d’ombre, largeur max %.1f m · %d échec(s)" %
		[visual_instances, visual_batches.size(), near_shadow_batches, largest_cell, failures])
	quit(int(failures > 0))


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
