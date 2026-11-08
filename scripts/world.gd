extends Node3D

const Stage = preload("res://scripts/campaign_stage.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Surfaces = preload("res://scripts/surfaces.gd")
const SKY_TEXTURE := preload("res://assets/textures/valbrume_sky.hdr")
const CASTLE := preload("res://assets/chateau.glb")
const VALLEY := preload("res://assets/vallee.glb")
const GATE := preload("res://assets/herse.glb")
const CHICKEN := preload("res://assets/poule.glb")
const HORSE := preload("res://assets/cheval.glb")

const START := Vector3(0, 0.14, 13.7)
const GATE_POINT := Vector3(0, 0.13, 22)
const PLACES := {
	"grain": Vector3(12, 0.12, 11.9),
	"poules": Vector3(15.7, 0.12, 5.36),
	"foin": Vector3(13.5, 0.12, -1.45),
	"cheval": Vector3(17.9, 0.12, -7.9),
	"puits": Vector3(0, 0.12, 3),
	"jardin": Vector3(-14, 0.12, 8.0),
	"bois": Vector3(-14, 0.12, -4.0),
	"cuisine": Vector3(-14.5, 0.12, -11.0),
	"pain": Vector3(-12.4, 0.12, -11.0),
	"table": Vector3(-3.9, 0.24, -12.45),
	"garde": Vector3(5.3, 0.12, 18),
	"sceau": Vector3(13, 0.12, -13.15),
	"intendant": Vector3(4.8, 0.24, -15),
	"trone": Vector3(0, 0.24, -16.8),
	"pont": Vector3(0, 0.1, 36.3),
	"sac_sec": Vector3(8.15, 0.12, -2.56),
	"balances": Vector3(-26.2, 0.02, 52.9),
	"ancien_chemin": Vector3(26.5, 0.02, 55.8),
	"affouage": Vector3(-8.6, 0.02, 76.3),
	"temoin_maison": Vector3(-13.0, 0.12, -9.2),
	"temoin_garnison": Vector3(7.8, 0.12, 15.5),
	"temoin_vallee": Vector3(-5.1, 0.24, -12.2),
	"hameau": Vector3(-19, 0.02, 47.7),
	"ruines": Vector3(20.9, 0.02, 48.7),
	"boisroyal": Vector3(0, 0.02, 71),
}
const SIGNPOSTS := {
	"Écurie": Vector3(15.6, 0, -4.25), "Potager": Vector3(-16.5, 0, 8.9),
	"Cuisines": Vector3(-12.8, 0, -10.25), "Basse-cour": Vector3(17.6, 0, 9.65),
	"Logis royal": Vector3(0, 0, -11.1), "Archives": Vector3(13, 0, -12.25),
}

var gate_shape: CollisionShape3D
var gate_model: Node3D
var chickens: Array[Node3D] = []
var horse: Node3D
var birds_fed := false
var horse_fed := false
var gate_tween: Tween
var clock := 0.0
var surfaces := Surfaces.new()
var campaign_stage: Stage
var key_light: DirectionalLight3D
var sky_environment: Environment
var campaign_phase := ""


func _ready() -> void:
	_lighting()
	_place(VALLEY, Vector3.ZERO, 0.0, true)
	_place(CASTLE, Vector3.ZERO, 0.0, true)
	_build_collisions()
	var scenery := Scenery.new()
	add_child(scenery)
	for trunk: Vector3 in scenery.trunks:
		_solid_at(trunk.x, trunk.z, 0.53, 0.53, 2.2)
	gate_model = _place(GATE, GATE_POINT)
	gate_shape = _box(GATE_POINT + Vector3.UP * 2, Vector3(4.48, 4.1, 0.35))
	for i in 4:
		var chick := _place(CHICKEN, Vector3(14.2 + i * 0.9, 0.12, 3.3 + (i % 2) * 3.65), i * 1.8)
		chickens.append(chick)
	horse = _place(HORSE, Vector3(16.8, 0.12, -8.9), 0.54)
	campaign_stage = Stage.new()
	add_child(campaign_stage)
	for title: String in SIGNPOSTS:
		_sign(title, SIGNPOSTS[title])


func point(id: String) -> Vector3:
	match id:
		"depart":
			return START
		"herse":
			return GATE_POINT
	var campaign_point := campaign_stage.point(id)
	return campaign_point if campaign_point.is_finite() else PLACES.get(id, Vector3.INF)


func update_campaign(view: Dictionary) -> void:
	campaign_stage.update_campaign(view)
	var flags: Array = view["flags"]
	birds_fed = flags.has("poules_nourries")
	horse_fed = flags.has("cheval_nourri") or flags.has("jument_calmee")
	var next_phase: String = view["phase"]
	if campaign_phase == next_phase:
		return
	campaign_phase = next_phase
	var light: Array = {
		"matin": [1.46, Color("#ffdeb7"), -30.0, 0.58],
		"midi": [1.72, Color("#fff1d7"), -50.0, 0.64],
		"soir": [0.93, Color("#ffc185"), -19.0, 0.45],
		"nuit": [0.30, Color("#9bb7df"), -28.0, 0.38],
	}[next_phase]
	key_light.light_energy = light[0]
	key_light.light_color = light[1]
	key_light.rotation_degrees.x = light[2]
	sky_environment.ambient_light_energy = light[3]


func _process(delta: float) -> void:
	clock += delta
	for i in chickens.size():
		var chick := chickens[i]
		var t := clock * (0.51 + 0.09 * i) + i * 2.4
		var center := Vector3(14.2 + i * 0.9, 0.12, 3.3 + (i % 2) * 3.65)
		if birds_fed:
			center = Vector3(16.05 + (i - 1.5) * 0.50, 0.12, 5.55 + (i % 2) * 0.62)
		var radius := 0.27 if birds_fed else 0.7
		var desired := center + Vector3(cos(t) * radius, absf(sin(t * 13.0)) * 0.047, sin(t) * radius)
		chick.position = chick.position.lerp(desired, 1.0 - exp(-delta * 3.0))
		chick.rotation.y = lerp_angle(chick.rotation.y, -t, 1.0 - exp(-delta * 3.0))
	if horse_fed:
		horse.position = horse.position.lerp(Vector3(17.5, 0.12, -8.55), 1.0 - exp(-delta * 1.4))
		horse.rotation.y = lerp_angle(horse.rotation.y, 1.37, 1.0 - exp(-delta * 1.4))
	horse.rotation.z = sin(clock * 1.25) * 0.012


func apply_progress(_deeds: int, king: bool, animate: bool = false) -> void:
	var height := 5.0 if king else 0.0
	if gate_tween and gate_tween.is_running():
		gate_tween.kill()
	if animate and king:
		gate_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		gate_tween.tween_property(gate_model, "position:y", GATE_POINT.y + height, 2.2)
		gate_tween.tween_callback(func() -> void: gate_shape.disabled = true)
	else:
		gate_shape.set_deferred("disabled", king)
		gate_model.position.y = GATE_POINT.y + height


func _place(scene: PackedScene, location: Vector3, yaw: float = 0.0, fixed: bool = false) -> Node3D:
	var item := scene.instantiate() as Node3D
	item.position = location
	item.rotation.y = yaw
	surfaces.dress(item, fixed)
	add_child(item)
	return item


func _build_collisions() -> void:
	_box(Vector3(0, -0.34, 17), Vector3(154, 0.68, 148))
	_box(Vector3(0, -0.02, 0), Vector3(43.0, 0.27, 43))
	_box(Vector3(0, 0.038, 21.81), Vector3(4.24, 0.08, 0.90), 0.13)
	_box(Vector3(0, 0.05, -16), Vector3(16.5, 0.38, 7.3))
	_box(Vector3(0, 0.10, 29.9), Vector3(4.16, 0.25, 10.2))
	_box(Vector3(0, 0.063, 24.14), Vector3(4.11, 0.10, 1.44), -0.16)
	_box(Vector3(0, 0.063, 35.66), Vector3(4.11, 0.10, 1.44), 0.16)
	_box(Vector3(0, 0.134, -12.03), Vector3(15.8, 0.09, 1.28), 0.10)
	_box(Vector3(0, 0.36, -17.67), Vector3(3.8, 0.27, 2.8))
	_box(Vector3(0, 0.31, -15.94), Vector3(3.78, 0.12, 0.84), 0.31)
	_box(Vector3(0, 0.57, -18.05), Vector3(2.9, 0.2, 1.9))
	_box(Vector3(0, 0.537, -16.86), Vector3(2.88, 0.10, 0.53), 0.33)
	_solid_at(0, -22, 44, 1.2, 6.15)
	_box(Vector3(0, 6.14, 22), Vector3(4.5, 1.83, 1.55))
	for sign_value in [-1.0, 1.0]:
		var side: float = sign_value
		_solid_at(side * 22, 0, 1.22, 44, 6.15)
		_solid_at(side * 12.32, 22, 19.42, 1.2, 6.15)
		_solid_at(side * 2.52, 22, 0.59, 1.5, 5.7)
		_solid_at(side * 4.35, 22, 3.65, 3.55, 8.2)
		for z in [-22.0, 22.0]:
			_solid_at(side * 22, z, 4.6, 4.65, 10.0)
		_solid_at(side * 8.0, -16.2, 1.04, 6.0, 5.6)
		_solid_at(side * 7.3, -13.45, 1.05, 1.0, 4.9)
		_solid_at(side * 6.0, -20, 2.9, 2.9, 8.5)
		_solid_at(side * 40.6, 29.9, 77.0, 7.3, 1.0)
		_solid_at(side * 2.03, 29.9, 0.15, 10.4, 0.85)
		_solid_at(side * 66.0, 17, 1, 133, 4)
	_solid_at(0, 82.5, 134, 1, 4)
	_solid_at(0, -42.5, 134, 1, 4)
	_solid_at(0, -19.4, 16.6, 1.05, 5.6)
	_solid_at(0, -18.04, 1.6, 1.25, 1.8)
	_solid_at(-3.9, -13.65, 3.0, 1.18, 1.1)
	_solid_at(0, 3, 1.8, 1.8, 2.7)
	_solid_at(-13, -15, 5.5, 4.16, 4.3)
	_solid_at(-12.6, -12.1, 2.27, 0.69, 0.93)
	_solid_at(13, -16.2, 5.76, 4.55, 4.1)
	_solid_at(18.8, 5.15, 2.6, 2.14, 2.2)
	_solid_at(16.45, 2.0, 6.9, 0.18, 1.12)
	_solid_at(16.45, 8.5, 6.9, 0.18, 1.12)
	_solid_at(19.9, 5.25, 0.18, 6.5, 1.12)
	_solid_at(13, 7.45, 0.18, 2.1, 1.12)
	_solid_at(16.4, -10.5, 6.4, 0.20, 1.12)
	_solid_at(19.6, -7.95, 0.20, 5.1, 1.12)
	_solid_at(18.8, -8.36, 0.62, 2.25, 0.74)
	_solid_at(12.0, 12.75, 1.78, 0.85, 0.68)
	_solid_at(14.9, -2.28, 2.85, 0.92, 0.67)
	_solid_at(-14, -4.65, 1.95, 1.2, 0.65)
	for x in [-17.0, -14.0, -11.0]:
		_solid_at(x, 5.15, 1.78, 5.45, 0.4)
	for house in [Vector4(-19, 52, 6, 4.8), Vector4(-28, 46, 5.6, 4.3),
			Vector4(-15, 42.5, 4.9, 4.1), Vector4(-25, 56.5, 4.1, 3.7)]:
		_solid_at(house.x, house.y, house.z, house.w, 3.2)
	_solid_at(17.3, 51, 2.4, 2.4, 4.1)
	_solid_at(24.4, 51, 2.4, 2.4, 4.1)
	_solid_at(20.85, 53, 7.1, 1.0, 3.6)


func _solid_at(x: float, z: float, width: float, depth: float, height: float) -> void:
	_box(Vector3(x, height / 2.0, z), Vector3(width, height, depth))


func _box(center: Vector3, size: Vector3, tilt: float = 0.0) -> CollisionShape3D:
	var body := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	body.position = center
	body.rotation.x = tilt
	body.add_child(shape_node)
	add_child(body)
	return shape_node


func _sign(title: String, location: Vector3) -> void:
	var sign_label := Label3D.new()
	sign_label.text = title
	sign_label.font_size = 32
	sign_label.outline_size = 8
	sign_label.pixel_size = 0.011
	sign_label.modulate = Color("#efe0bb")
	sign_label.outline_modulate = Color("#2b2720")
	sign_label.position = location + Vector3.UP * 1.55
	sign_label.visibility_range_end = 24.0
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign_label)


func _lighting() -> void:
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = SKY_TEXTURE
	sky_material.energy_multiplier = 0.92
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.sky_rotation.y = deg_to_rad(85.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c2d0e1")
	environment.ambient_light_energy = 0.54
	environment.ambient_light_sky_contribution = 0.36
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.21
	environment.ssao_enabled = false
	environment.ssao_radius = 0.86
	environment.ssao_intensity = 0.95
	environment.glow_enabled = true
	environment.glow_bloom = 0.08
	environment.fog_enabled = true
	environment.fog_light_color = Color("#adb4aa")
	environment.fog_density = 0.0019
	environment.fog_sky_affect = 0.25
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-31, -40, 0)
	sun.light_color = Color("#ffe1be")
	sun.light_energy = 1.65
	sun.light_angular_distance = 0.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)
	key_light = sun
	sky_environment = environment

	_warm_light(Vector3(-13.5, 2.4, -11.83), 7.0, 1.08)
	_warm_light(Vector3(-5.5, 3.0, -17.9), 8.5, 1.15)
	_warm_light(Vector3(5.5, 3.0, -17.9), 8.5, 1.15)
	_warm_light(Vector3(-2.46, 2.5, 21.07), 5.8, 0.75)
	_warm_light(Vector3(2.46, 2.5, 21.07), 5.8, 0.75)


func set_quality(detailed: bool) -> void:
	sky_environment.ssao_enabled = detailed
	key_light.directional_shadow_max_distance = 61.0 if detailed else 45.0
	key_light.light_angular_distance = 0.68 if detailed else 0.25


func _warm_light(center: Vector3, radius: float, energy: float) -> void:
	var lantern := OmniLight3D.new()
	lantern.position = center
	lantern.light_color = Color("#ffc17a")
	lantern.omni_range = radius
	lantern.omni_attenuation = 1.7
	lantern.light_energy = energy
	add_child(lantern)
