extends Node3D
## The campaign's physical props and residents. It displays state supplied by the campaign.

const Surfaces = preload("res://scripts/surfaces.gd")
const WORKER := preload("res://assets/domestique.glb")
const GUARD := preload("res://assets/garde.glb")
const STEWARD := preload("res://assets/intendant.glb")
const CARGO := preload("res://assets/charge.glb")

const PLACES := {
	"services": Vector3(2.7, 0.12, 10.9),
	"veille": Vector3(7.8, 0.12, 15.5),
	"message": Vector3(11.7, 0.12, -12.45),
	"crise": Vector3(-10.4, 0.12, -9.35),
	"grenier": Vector3(8.6, 0.12, -0.90),
	"jument": Vector3(15.4, 0.12, -7.3),
	"galerie": Vector3(8.6, 0.12, -4.8),
	"garde_passage": Vector3(11.75, 0.12, -7.1),
	"reserve": Vector3(10.1, 0.12, -3.65),
	"banquet": Vector3(-3.9, 0.24, -12.45),
	"lendemain": Vector3(4.15, 0.24, -13.7),
	"ration": Vector3(-10.0, 0.12, -11.0),
	"conseil": Vector3(2.55, 0.24, -14.3),
	"retour": Vector3(-11.0, 0.12, -9.6),
	"repos": Vector3(-18.1, 0.12, 9.6),
	"moulin": Vector3(-22.8, 0.02, 50.15),
	"charte": Vector3(21.0, 0.02, 49.6),
	"lisiere": Vector3(1.7, 0.02, 72.4),
}

const PHASES := ["matin", "midi", "soir", "nuit"]
const LIMBS := ["BrasG", "BrasD", "JambeG", "JambeD"]
const GRANARY_Y := 0.12
const TEXTURES := "res://assets/textures/"

var _surfaces := Surfaces.new()
var _materials: Dictionary = {}
var _residents: Dictionary = {}
var _doors: Dictionary = {}
var _valley_displays: Dictionary = {}
var _dry_grain: Node3D
var _wet_grain: Node3D
var _reserve_grain: Node3D
var _dinner: Node3D
var _dinner_small: Node3D
var _mill_wheel: Node3D
var _wet_ground: Node3D
var _ration_crates: Node3D
var _return_board: Label3D
var _granary_sign: Label3D
var _rain: GPUParticles3D
var _storm_sound: AudioStreamPlayer3D
var _bell: AudioStreamPlayer3D
var _phase := ""
var _storm := false
var _mill_repaired := false


func _ready() -> void:
	_build_materials()
	_build_granary()
	_build_court()
	_build_lodge()
	_build_evidence()
	_build_valley()
	_build_residents()
	if DisplayServer.get_name() != "headless":
		_build_rain()
		_build_ambience()


func point(id: String) -> Vector3:
	if _residents.has(id):
		var resident: Resident = _residents[id]
		return resident.root.position
	return PLACES.get(id, Vector3.INF)


func update_campaign(view: Dictionary) -> void:
	var phase: String = view.get("phase", "matin")
	var slot := maxi(PHASES.find(phase), 0)
	var previous_phase := _phase
	_phase = phase
	if previous_phase != phase:
		for id: String in _residents:
			var resident: Resident = _residents[id]
			resident.destination = resident.stations[slot]
			if previous_phase.is_empty():
				resident.root.position = resident.destination
		if not previous_phase.is_empty() and _bell:
			_bell.play()

	var flags: Array = view.get("flags", [])
	var outcome: String = view.get("outcome", "")
	var storm: bool = view.get("crisis", "attente") == "active"
	if storm != _storm:
		_storm = storm
		if _rain:
			_rain.emitting = storm
		if _storm_sound:
			if storm:
				_storm_sound.play()
			else:
				_storm_sound.stop()
	var wet := flags.has("grain_mouille") or outcome == "perte"
	_dry_grain.visible = not wet
	_wet_grain.visible = wet
	_reserve_grain.visible = outcome != "reserve"
	_wet_ground.visible = storm or (wet and phase != "midi")
	_set_door("logement", int(view.get("rank", 0)) >= 1)
	_set_door("galerie", flags.has("galerie"))
	_set_door("reserve", flags.has("reserve_ouverte") or outcome == "reserve")
	_set_door("garde_passage", flags.has("garde_passage") or flags.has("responsabilite_garde"))
	_dinner.visible = outcome in ["banquet", "reserve"]
	_dinner_small.visible = outcome == "reduire"
	_ration_crates.visible = flags.has("promesse_vivres") or flags.has("ration_rations")
	_granary_sign.text = "Grenier · toiture endommagée" if storm else "Grenier de Valbrume"

	var decisions: Dictionary = view.get("decisions", {})
	_mill_repaired = decisions.get("hameau", "") == "reparer"
	for region: String in _valley_displays:
		var variants: Dictionary = _valley_displays[region]
		for option: String in variants:
			var variant: Node3D = variants[option]
			variant.visible = decisions.get(region, "") == option
	_return_board.text = "Le conseil a rendu ses décisions" if flags.has("retour_conseil") else "Consignes du jour"


func _process(delta: float) -> void:
	if _mill_repaired:
		_mill_wheel.rotate_x(delta * 0.64)
	for id: String in _residents:
		var resident: Resident = _residents[id]
		resident.walk(delta)


func _build_granary() -> void:
	const WALL_HEIGHT := 2.9
	const SOUTH := -1.5
	const NORTH := -6.2
	const CENTER_Z := -3.85
	var wall_center := WALL_HEIGHT * 0.5 + GRANARY_Y
	# A roomy central aisle and a separate keyed bay on the east wall.
	_solid(Vector3(6.2, wall_center, CENTER_Z), Vector3(0.24, WALL_HEIGHT, 4.70), "crépi")
	_solid(Vector3(11.4, wall_center, CENTER_Z), Vector3(0.24, WALL_HEIGHT, 4.70), "crépi")
	for z in [SOUTH, NORTH]:
		_solid(Vector3(6.85, wall_center, z), Vector3(1.50, WALL_HEIGHT, 0.25), "crépi")
		_solid(Vector3(10.5, wall_center, z), Vector3(2.0, WALL_HEIGHT, 0.25), "crépi")
		_solid(Vector3(8.55, 2.72, z), Vector3(2.0, 0.57, 0.25), "crépi")
		for x in [6.2, 7.55, 9.5, 11.4]:
			_box(self, Vector3(x, wall_center, z), Vector3(0.15, WALL_HEIGHT, 0.33), "poutre")
		_box(self, Vector3(6.86, 1.11, z), Vector3(1.50, 0.13, 0.30), "poutre")
		_box(self, Vector3(10.5, 1.11, z), Vector3(1.92, 0.13, 0.30), "poutre")
		_box(self, Vector3(8.8, 2.26, z), Vector3(5.32, 0.19, 0.35), "poutre")
		for x in [6.87, 10.46]:
			_box(self, Vector3(x, 0.42, z), Vector3(1.31, 0.17, 0.33), "pierre")
	_brace(Vector3(6.29, 0.34, SOUTH + 0.17), Vector3(7.45, 1.07, SOUTH + 0.17), 0.09)
	_brace(Vector3(9.62, 1.18, SOUTH + 0.17), Vector3(11.30, 2.22, SOUTH + 0.17), 0.09)
	_brace(Vector3(11.30, 0.32, SOUTH + 0.17), Vector3(9.62, 1.07, SOUTH + 0.17), 0.09)
	# One shallow stone threshold avoids snagging the player's capsule.
	_box(self, Vector3(8.8, 0.122, CENTER_Z), Vector3(5.08, 0.032, 4.5), "dalle")
	var eave := Vector3(8.8, 3.04, CENTER_Z)
	for side in [-1.0, 1.0]:
		var panel := _box(self, eave + Vector3(1.44 * side, 0.65, 0.0), Vector3(3.16, 0.16, 5.26), "ardoise")
		panel.rotation.z = -0.43 * side
		for i in 4:
			var seam := _box(self, panel.position + Vector3(0.0, 0.09, -1.96 + i * 1.31),
				Vector3(3.17, 0.09, 0.035), "ardoise")
			seam.rotation.z = panel.rotation.z
	_solid(Vector3(8.8, 2.91, CENTER_Z), Vector3(5.18, 0.17, 4.8), "poutre")
	_box(self, eave + Vector3(0.0, 1.29, 0.0), Vector3(0.16, 0.12, 5.33), "poutre")

	_solid(Vector3(9.51, 1.21, -5.22), Vector3(0.13, 2.2, 1.96), "poutre")
	_solid(Vector3(11.08, 1.21, -4.20), Vector3(0.50, 2.2, 0.13), "poutre")
	_add_door("reserve", Vector3(10.23, 0.12, -4.20), 1.33, 2.16)
	_sign(Vector3(10.22, 2.53, -4.08), "Réserve scellée")
	_add_door("galerie", Vector3(8.55, 0.12, NORTH), 1.95, 2.23)

	# Covered bypass beside the council hall. Its north end is open.
	_solid(Vector3(7.34, 1.40, -8.60), Vector3(0.17, 2.56, 4.75), "pierre")
	_solid(Vector3(8.58, 2.77, -8.64), Vector3(2.66, 0.18, 5.12), "ardoise")
	for z in [-6.30, -7.84, -9.39, -11.05]:
		_solid(Vector3(9.83, 1.41, z), Vector3(0.15, 2.58, 0.15), "poutre")
		_box(self, Vector3(8.59, 2.63, z), Vector3(2.61, 0.18, 0.18), "poutre")
	_lantern(Vector3(7.52, 2.08, -8.70), 4.1)
	_sign(Vector3(8.56, 2.46, NORTH + 0.15), "Galerie de service")

	# Guarded west entry to the stables. The southern approach remains clear.
	for z in [-9.87, -8.57, -6.89, -6.20]:
		_solid(Vector3(12.64, 0.77, z), Vector3(0.14, 1.32, 0.14), "poutre")
	for z in [-9.22, -6.55]:
		for y in [0.50, 0.95]:
			_box(self, Vector3(12.64, y, z), Vector3(0.11, 0.14, 1.25 if z < -8.0 else 0.67), "poutre")
	_solid(Vector3(12.64, 0.69, -9.25), Vector3(0.13, 1.2, 1.36), "")
	_solid(Vector3(12.64, 0.69, -6.55), Vector3(0.13, 1.2, 0.69), "")
	_add_door("garde_passage", Vector3(12.64, 0.12, -7.73), 1.68, 1.27, PI / 2)
	_sign(Vector3(12.38, 1.77, -7.73), "Accès des écuries")
	_granary_sign = _sign(Vector3(8.55, 2.54, -1.31), "Grenier de Valbrume")
	_lantern(Vector3(7.30, 2.31, -1.17), 5.1)
	_lantern(Vector3(10.50, 2.32, -3.18), 4.2)

	_dry_grain = _group("Sacs secs")
	_wet_grain = _group("Grain endommagé")
	_reserve_grain = _group("Sacs de réserve")
	for i in 5:
		var x := 6.61 + float(i % 2) * 0.46
		var z := -2.27 - float(i) * 0.40
		_sack(_dry_grain, Vector3(x, 0.40, z), float(i) * 0.38, 1.0)
		_sack(_wet_grain, Vector3(x, 0.26, z), float(i) * 0.38, 0.59)
	for i in 3:
		_sack(_reserve_grain, Vector3(10.05 + float(i % 2) * 0.50, 0.40, -5.41 - float(i) * 0.25),
			float(i) * 0.49, 0.83)
	_box(_wet_grain, Vector3(7.03, 0.148, -3.57), Vector3(1.24, 0.03, 1.03), "grain mouillé")
	_wet_grain.hide()


func _build_court() -> void:
	_board(Vector3(2.72, 0.12, 10.22))
	_return_board = _sign(Vector3(2.72, 1.95, 10.29), "Consignes du jour")
	_board(Vector3(7.82, 0.12, 14.72))
	_sign(Vector3(7.82, 1.92, 14.80), "Registre de veille")
	_board(Vector3(-17.98, 0.12, 8.99))
	_sign(Vector3(-17.98, 1.94, 9.10), "Quartier du personnel")
	_lantern(Vector3(-18.56, 2.11, 8.83), 4.0)

	_dinner = _group("Table du banquet")
	_dinner_small = _group("Repas réduit")
	for i in 4:
		var position := Vector3(-5.0 + i * 0.71, 1.20, -13.68)
		_cargo(_dinner, "pain", position, 0.56, float(i) * 0.42)
		if i == 1 or i == 2:
			_cargo(_dinner_small, "pain", position, 0.50, float(i) * 0.59)
	_dinner.hide()
	_dinner_small.hide()

	_ration_crates = _group("Vivres promis")
	for i in 3:
		_crate(_ration_crates, Vector3(-16.4 - i * 0.58, 0.40, -10.73), 0.56)
	_ration_crates.hide()

	_wet_ground = _group("Flaques")
	for p: Vector3 in [
		Vector3(3.7, 0.127, -3.9), Vector3(7.7, 0.145, -0.8),
		Vector3(-9.2, 0.130, -8.6), Vector3(2.2, 0.137, 5.8),
		Vector3(-4.3, 0.137, 11.4), Vector3(7.3, 0.127, 8.2),
	]:
		_puddle(p)
	_wet_ground.hide()


func _build_lodge() -> void:
	# An optional room with its own latch, away from the public route to the council.
	_solid(Vector3(-7.7, 1.40, -5.1), Vector3(0.22, 2.56, 3.8), "crépi")
	_solid(Vector3(-4.3, 1.40, -5.1), Vector3(0.22, 2.56, 3.8), "crépi")
	_solid(Vector3(-6.0, 1.40, -7.0), Vector3(3.4, 2.56, 0.22), "crépi")
	for x: float in [-7.26, -4.74]:
		_solid(Vector3(x, 1.4, -3.2), Vector3(0.83, 2.56, 0.22), "crépi")
	_box(self, Vector3(-6.0, 2.58, -5.1), Vector3(3.62, 0.14, 4.12), "ardoise")
	_box(self, Vector3(-6.0, 0.121, -5.1), Vector3(3.19, 0.032, 3.62), "dalle")
	_box(self, Vector3(-6.82, 0.58, -6.43), Vector3(0.95, 0.12, 0.63), "poutre")
	_crate(self, Vector3(-5.25, 0.40, -6.47), 0.66)
	_add_door("logement", Vector3(-6.0, 0.12, -3.2), 1.69, 2.25)
	_sign(Vector3(-6.0, 2.48, -3.04), "Logement du service")
	_lantern(Vector3(-7.0, 2.10, -5.95), 4.5)


func _build_evidence() -> void:
	_crate(self, Vector3(-26.2, 0.18, 52.9), 0.6)
	_sign(Vector3(-26.2, 1.19, 52.9), "Mesures du hameau")
	_box(self, Vector3(26.5, 0.15, 55.8), Vector3(0.71, 0.26, 0.52), "pierre")
	_sign(Vector3(26.5, 1.21, 55.8), "Ancienne borne de chemin")
	_board(Vector3(-8.6, 0.03, 76.3))
	_sign(Vector3(-8.6, 1.68, 76.3), "Registre de coupe")


func _build_valley() -> void:
	# The wheel stands clear of the hameau route, beside the mill's west wall.
	_mill_wheel = _group("Roue du moulin")
	_mill_wheel.position = Vector3(-22.29, 1.43, 52.55)
	for i in 12:
		var theta := TAU * float(i) / 12.0
		var spoke := _box(_mill_wheel, Vector3(0, cos(theta) * 0.50, sin(theta) * 0.50),
			Vector3(0.16, 0.92, 0.095), "poutre")
		spoke.rotation.x = theta
		var paddle := _box(_mill_wheel, Vector3(0, cos(theta) * 1.04, sin(theta) * 1.04),
			Vector3(0.37, 0.13, 0.56), "poutre")
		paddle.rotation.x = theta
	for side in [-1.0, 1.0]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.96
		ring.outer_radius = 1.08
		ring.rings = 24
		ring.ring_segments = 8
		var mesh := _mesh(_mill_wheel, ring, Vector3(side * 0.20, 0, 0), "poutre")
		mesh.rotation.z = PI / 2.0
	_sign(Vector3(-22.4, 1.46, 50.58), "Moulin des Aulnes")

	var repaired := _variant("hameau", "reparer")
	_sack(repaired, Vector3(-23.08, 0.33, 50.91), 0.2, 0.79)
	_sack(repaired, Vector3(-23.63, 0.29, 50.84), -0.5, 0.72)
	var audited := _variant("hameau", "verifier")
	_board(Vector3(-22.80, 0.0, 49.53), audited)
	_sign(Vector3(-22.8, 1.66, 49.59), "Mesures vérifiées", audited)
	var taxes := _variant("hameau", "alleger")
	_board(Vector3(-22.80, 0.0, 49.53), taxes)
	_sign(Vector3(-22.8, 1.66, 49.59), "Prélèvement réduit", taxes)

	_crate(self, Vector3(21.98, 0.30, 49.35), 0.56)
	_sign(Vector3(21.94, 1.15, 49.31), "Anciennes archives")
	var opened := _variant("ruines", "ouvrir")
	_board(Vector3(20.93, 0.0, 50.14), opened)
	_sign(Vector3(20.93, 1.63, 50.20), "Libre passage", opened)
	var investigated := _variant("ruines", "enqueter")
	_crate(investigated, Vector3(21.68, 0.34, 50.06), 0.64)
	_sign(Vector3(21.68, 1.27, 50.11), "Pièces à examiner", investigated)
	var toll := _variant("ruines", "peage")
	_board(Vector3(20.93, 0.0, 50.14), toll)
	_sign(Vector3(20.93, 1.63, 50.20), "Droit de passage", toll)

	_board(Vector3(2.80, 0.0, 73.29))
	_sign(Vector3(2.8, 1.69, 73.40), "Lisière de la couronne")
	var cut := _variant("boisroyal", "coupe")
	for i in 3:
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.115
		log_mesh.bottom_radius = 0.135
		log_mesh.height = 1.25
		log_mesh.radial_segments = 9
		var log_piece := _mesh(cut, log_mesh, Vector3(3.08 + i * 0.23, 0.14, 72.26), "poutre")
		log_piece.rotation.x = PI / 2.0
	_sign(Vector3(3.33, 1.18, 72.32), "Coupe autorisée", cut)
	var preserved := _variant("boisroyal", "proteger")
	for x in [2.77, 3.35, 3.92]:
		_box(preserved, Vector3(x, 0.51, 72.32), Vector3(0.11, 1.02, 0.11), "poutre")
	_box(preserved, Vector3(3.34, 0.60, 72.32), Vector3(1.25, 0.11, 0.13), "poutre")
	_sign(Vector3(3.33, 1.22, 72.35), "Bois protégé", preserved)
	var purchased := _variant("boisroyal", "acheter")
	_crate(purchased, Vector3(3.25, 0.27, 72.31), 0.50)
	_sign(Vector3(3.30, 1.22, 72.35), "Livraison du bois", purchased)


func _build_residents() -> void:
	_add_resident("cuisiniere", STEWARD, "intendant", Color("#824a43"), 0.91,
		[Vector3(-13.6, 0.12, -10.42), Vector3(-11.3, 0.12, -9.3),
			Vector3(-10.7, 0.12, -10.21), Vector3(-12.8, 0.12, -9.65)])
	_add_resident("palefrenier", WORKER, "domestique", Color("#625943"), 1.02,
		[Vector3(15.25, 0.12, -5.14), Vector3(16.43, 0.12, -6.16),
			Vector3(17.63, 0.12, -6.8), Vector3(15.12, 0.12, -5.80)])
	_add_resident("garde", GUARD, "garde", Color("#504c47"), 1.0,
		[Vector3(5.3, 0.12, 18), Vector3(5.38, 0.12, 16.68),
			Vector3(5.83, 0.12, 17.50), Vector3(5.5, 0.12, 18.8)])
	_add_resident("intendant", STEWARD, "intendant", Color("#564761"), 1.01,
		[Vector3(4.8, 0.24, -15), Vector3(4.06, 0.24, -14.27),
			Vector3(5.3, 0.24, -13.7), Vector3(4.68, 0.24, -14.95)])
	_add_resident("scribe", STEWARD, "intendant", Color("#6b5341"), 0.94,
		[Vector3(12, 0.12, -11.54), Vector3(13.5, 0.12, -12.57),
			Vector3(13.1, 0.12, -11.48), Vector3(12.26, 0.12, -12.37)])
	_add_resident("messager", WORKER, "domestique", Color("#6c7847"), 0.93,
		[Vector3(10.54, 0.12, -11.65), Vector3(10.78, 0.12, -12.32),
			Vector3(12.64, 0.12, -11.52), Vector3(11.45, 0.12, -10.36)])
	_add_resident("jardiniere", WORKER, "domestique", Color("#59674b"), 0.89,
		[Vector3(-12.37, 0.12, 8.69), Vector3(-14.2, 0.12, 9.04),
			Vector3(-16.55, 0.12, 8.97), Vector3(-16.74, 0.12, 9.97)])
	_add_resident("charpentier", WORKER, "domestique", Color("#78583e"), 1.04,
		[Vector3(-16.30, 0.12, -2.73), Vector3(-18.25, 0.12, -3.01),
			Vector3(-17.30, 0.12, -5.97), Vector3(-17.28, 0.12, -3.46)])
	_add_resident("chapelaine", STEWARD, "intendant", Color("#3a4e56"), 0.92,
		[Vector3(-6.27, 0.24, -15.36), Vector3(-6.31, 0.24, -14.51),
			Vector3(-6.59, 0.24, -15.91), Vector3(-6.10, 0.24, -15.6)])
	_add_resident("meuniere", WORKER, "domestique", Color("#846448"), 0.92,
		[Vector3(-23.01, 0.02, 50.15), Vector3(-23.46, 0.02, 49.63),
			Vector3(-23.62, 0.02, 50.41), Vector3(-22.96, 0.02, 49.66)])
	_add_resident("veilleur", GUARD, "garde", Color("#676354"), 0.98,
		[Vector3(18.56, 0.02, 48.17), Vector3(19.69, 0.02, 48.45),
			Vector3(21.28, 0.02, 48.31), Vector3(19.84, 0.02, 47.68)])
	_add_resident("forestiere", WORKER, "domestique", Color("#4c5d4b"), 0.95,
		[Vector3(2.03, 0.02, 72.56), Vector3(3.24, 0.02, 73.84),
			Vector3(2.47, 0.02, 74.7), Vector3(1.92, 0.02, 72.87)])


func _add_resident(id: String, packed: PackedScene, prefix: String, dye: Color,
		height: float, stations: Array[Vector3]) -> void:
	var resident := Resident.new()
	resident.root = _group(id.capitalize())
	resident.root.position = stations[0]
	resident.destination = stations[0]
	resident.stations = stations
	resident.visual = packed.instantiate() as Node3D
	resident.visual.scale = Vector3.ONE * height
	resident.visual.rotation.y = 0.16 + float(_residents.size() % 5) * 0.39
	resident.root.add_child(resident.visual)
	_surfaces.dress(resident.visual, false)
	for limb_name: String in LIMBS:
		var limb := resident.visual.get_node_or_null(NodePath(prefix + "_" + limb_name)) as Node3D
		if limb:
			resident.limbs.append(limb)
	var cloth_names := ["Tunique", "Gambison", "Bordeaux"]
	for child: Node in resident.visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.mesh.surface_get_material(surface)
			if original and original.resource_name.get_slice(".", 0) in cloth_names:
				var material := mesh.get_active_material(surface).duplicate() as StandardMaterial3D
				material.albedo_color = dye
				mesh.set_surface_override_material(surface, material)
	_residents[id] = resident


func _build_materials() -> void:
	_materials["poutre"] = _textured("wood_planks_grey", Color("#82705d"), 0.9)
	_materials["crépi"] = _textured("white_rough_plaster", Color("#baa783"), 0.61)
	_materials["pierre"] = _textured("rock_surface", Color("#a09483"), 0.65)
	_materials["dalle"] = _textured("cobblestone_floor_03", Color("#ada79b"), 0.56)
	_materials["ardoise"] = _textured("roof_slates_03", Color("#535b61"), 0.48)
	_materials["fer"] = _color(Color("#35342e"), 0.49)
	_materials["papier"] = _color(Color("#d6c5a1"), 0.86)
	_materials["grain mouillé"] = _color(Color("#514238"), 0.44)
	_materials["eau"] = _color(Color("#535951"), 0.27)
	var flame := _color(Color("#f5b361"), 0.4)
	flame.emission_enabled = true
	flame.emission = Color("#ffab50")
	flame.emission_energy_multiplier = 1.6
	_materials["flamme"] = flame


func _textured(texture: String, color: Color, uv_scale: float) -> StandardMaterial3D:
	var mat := _color(color, 0.89)
	mat.albedo_texture = load(TEXTURES + texture + "_albedo.jpg") as Texture2D
	mat.normal_texture = load(TEXTURES + texture + "_normal.jpg") as Texture2D
	mat.normal_enabled = true
	mat.normal_scale = 0.65
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * uv_scale
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat


func _color(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _build_rain() -> void:
	_rain = GPUParticles3D.new()
	_rain.position = Vector3(0.0, 9.5, 0.0)
	_rain.amount = 1550
	_rain.lifetime = 0.72
	_rain.visibility_aabb = AABB(Vector3(-23, -10, -24), Vector3(46, 11, 48))
	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3(21.0, 0.18, 21.0)
	motion.direction = Vector3(-0.11, -1.0, 0.07)
	motion.spread = 1.7
	motion.initial_velocity_min = 9.8
	motion.initial_velocity_max = 12.2
	motion.gravity = Vector3(-1.0, -6.0, 0.5)
	_rain.process_material = motion
	var streak := BoxMesh.new()
	streak.size = Vector3(0.006, 0.22, 0.006)
	var rain_material := _color(Color("#a9bcc968"), 0.4)
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material = rain_material
	_rain.draw_pass_1 = streak
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rain.emitting = false
	add_child(_rain)


func _build_ambience() -> void:
	_bell = AudioStreamPlayer3D.new()
	_bell.position = Vector3(19.0, 5.1, -19.5)
	_bell.max_distance = 92.0
	_bell.unit_size = 25.0
	_bell.volume_db = -13.0
	_bell.stream = _ambience_stream(false)
	add_child(_bell)

	_storm_sound = AudioStreamPlayer3D.new()
	_storm_sound.position = Vector3(3.0, 4.2, -0.5)
	_storm_sound.max_distance = 62.0
	_storm_sound.unit_size = 28.0
	_storm_sound.volume_db = -23.0
	_storm_sound.stream = _ambience_stream(true)
	add_child(_storm_sound)


func _ambience_stream(rain: bool) -> AudioStreamWAV:
	var rate := 16000
	var samples := rate * (4 if rain else 5)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 7307
	var low := 0.0
	for index in samples:
		var seconds := float(index) / rate
		var wave := 0.0
		if rain:
			var noise := random.randf_range(-1.0, 1.0)
			low = 0.94 * low + 0.06 * noise
			wave = (0.49 * low + 0.08 * noise) * minf(1.0, minf(seconds, 4.0 - seconds) * 48.0)
		else:
			for beat in [0.0, 1.04]:
				var age: float = seconds - beat
				if age >= 0.0:
					wave += minf(1.0, age * 125.0) * exp(-age * 1.9) * (
						sin(TAU * 185.0 * age) * 0.24 + sin(TAU * 278.7 * age) * 0.085
						+ sin(TAU * 438.1 * age) * 0.05 * exp(-age * 2.8))
		bytes.encode_s16(index * 2, roundi(wave * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	if rain:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples
	return stream


func _add_door(id: String, center: Vector3, width: float, height: float, yaw := 0.0) -> void:
	var door := Node3D.new()
	door.name = "Porte " + id
	door.position = center
	door.rotation.y = yaw
	add_child(door)
	var pivot := Node3D.new()
	pivot.position.x = -width * 0.5
	door.add_child(pivot)
	for i in 7:
		var board_width := width / 7.0
		_box(pivot, Vector3((float(i) + 0.5) * board_width, height * 0.5, 0.0),
			Vector3(board_width - 0.014, height - 0.055, 0.12), "poutre")
	for y in [height * 0.26, height * 0.73]:
		_box(pivot, Vector3(width * 0.52, y, 0.073), Vector3(width * 0.91, 0.08, 0.045), "fer")
		for x in [width * 0.15, width * 0.48, width * 0.86]:
			_box(pivot, Vector3(x, y, 0.103), Vector3(0.028, 0.028, 0.025), "fer")
	_box(pivot, Vector3(width * 0.83, height * 0.54, 0.105), Vector3(0.094, 0.13, 0.055), "fer")
	var collision := _collision(door, Vector3(0.0, height * 0.5, 0.0), Vector3(width, height, 0.16))
	_doors[id] = {"pivot": pivot, "collision": collision, "open": false, "tween": null}


func _set_door(id: String, opened: bool) -> void:
	var data: Dictionary = _doors[id]
	if data["open"] == opened:
		return
	data["open"] = opened
	var pivot: Node3D = data["pivot"]
	var collision: CollisionShape3D = data["collision"]
	var old_tween: Tween = data["tween"]
	if old_tween:
		old_tween.kill()
	var swing := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(pivot, "rotation:y", 1.69 if opened else 0.0, 0.48)
	collision.set_deferred("disabled", opened)
	data["tween"] = swing


func _lantern(at: Vector3, radius: float) -> void:
	for offset in [-0.10, 0.10]:
		_box(self, at + Vector3(0, offset, 0), Vector3(0.20, 0.04, 0.19), "fer")
	_box(self, at, Vector3(0.10, 0.17, 0.10), "flamme")
	for x in [-0.085, 0.085]:
		for z in [-0.08, 0.08]:
			_box(self, at + Vector3(x, 0, z), Vector3(0.022, 0.20, 0.022), "fer")
	var light := OmniLight3D.new()
	light.position = at
	light.omni_range = radius
	light.omni_attenuation = 1.9
	light.light_color = Color("#ffbd79")
	light.light_energy = 1.15
	add_child(light)


func _board(at: Vector3, parent: Node3D = self) -> void:
	for x in [-0.51, 0.51]:
		_box(parent, at + Vector3(x, 0.74, 0.0), Vector3(0.10, 1.48, 0.13), "poutre")
	_box(parent, at + Vector3(0.0, 1.17, 0.0), Vector3(1.22, 0.54, 0.13), "poutre")
	_box(parent, at + Vector3(0.05, 1.16, 0.08), Vector3(0.34, 0.37, 0.03), "papier")


func _sign(at: Vector3, caption: String, parent: Node3D = self) -> Label3D:
	var signpost := Label3D.new()
	signpost.position = at
	signpost.text = caption
	signpost.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	signpost.modulate = Color("#e8d8b5")
	signpost.outline_modulate = Color("#28231d")
	signpost.font_size = 33
	signpost.outline_size = 7
	signpost.pixel_size = 0.009
	signpost.visibility_range_end = 17.0
	parent.add_child(signpost)
	return signpost


func _puddle(at: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.71
	mesh.bottom_radius = 0.71
	mesh.height = 0.009
	mesh.radial_segments = 16
	mesh.rings = 1
	var puddle := _mesh(_wet_ground, mesh, at, "eau")
	puddle.scale = Vector3(1.32, 1.0, 0.62)
	puddle.rotation.y = at.x * 0.61


func _crate(parent: Node3D, at: Vector3, width: float) -> void:
	_box(parent, at, Vector3(width, width, width), "poutre")
	for x in [-width * 0.31, width * 0.31]:
		_box(parent, at + Vector3(x, 0, width * 0.50), Vector3(0.055, width, 0.045), "fer")


func _sack(parent: Node3D, at: Vector3, yaw: float, stretch: float) -> void:
	var sack := _cargo(parent, "grain", at, 1.17, yaw)
	sack.scale.y *= stretch


func _cargo(parent: Node3D, id: String, at: Vector3, width: float, yaw: float) -> Node3D:
	var cargo := CARGO.instantiate() as Node3D
	cargo.position = at
	cargo.scale = Vector3.ONE * width
	cargo.rotation.y = yaw
	for child: Node3D in cargo.get_children():
		child.visible = child.name == "charge_" + id
	_surfaces.dress(cargo, false)
	parent.add_child(cargo)
	return cargo


func _brace(from: Vector3, to: Vector3, width: float) -> void:
	var piece := _box(self, (from + to) * 0.5, Vector3(width, from.distance_to(to), width), "poutre")
	piece.rotation.z = -atan2(to.x - from.x, to.y - from.y)


func _variant(region: String, option: String) -> Node3D:
	if not _valley_displays.has(region):
		_valley_displays[region] = {}
	var variant := _group(region.capitalize() + " · " + option)
	variant.hide()
	_valley_displays[region][option] = variant
	return variant


func _group(label: String) -> Node3D:
	var group := Node3D.new()
	group.name = label
	add_child(group)
	return group


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, style: String) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = at
	visual.material_override = _materials[style]
	parent.add_child(visual)
	return visual


func _box(parent: Node3D, at: Vector3, size: Vector3, style: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, at, style)


func _solid(at: Vector3, size: Vector3, style: String) -> void:
	_collision(self, at, size)
	if not style.is_empty():
		_box(self, at, size, style)


func _collision(parent: Node3D, at: Vector3, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return collision


class Resident:
	var root: Node3D
	var visual: Node3D
	var stations: Array[Vector3]
	var destination: Vector3
	var limbs: Array[Node3D] = []
	var walk_phase := 0.0
	var stride := 0.0

	func walk(delta: float) -> void:
		var direction := destination - root.position
		var moving := direction.length_squared() > 0.003
		if moving:
			root.position = root.position.move_toward(destination, delta * 1.35)
			visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-delta * 8.0))
		stride = move_toward(stride, 1.0 if moving else 0.0, delta * 6.0)
		if stride == 0.0 and not moving:
			return
		walk_phase = fmod(walk_phase + delta * 7.5, TAU)
		visual.position.y = sin(walk_phase * 2.0) * stride * 0.018
		for index in limbs.size():
			var limb := limbs[index]
			var x := -1.0 if index % 2 == 0 else 1.0
			var swing := 1.0 if index == 0 or index == 3 else -1.0
			var pivot := Vector3(x * 0.21, 1.42, 0.0) if index < 2 else Vector3(x * 0.10, 0.88, 0.0)
			limb.rotation.x = sin(walk_phase) * swing * stride * 0.34
			limb.position = pivot - limb.basis * pivot
