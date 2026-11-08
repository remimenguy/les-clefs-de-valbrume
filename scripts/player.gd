extends CharacterBody3D

const Surfaces = preload("res://scripts/surfaces.gd")
const WORKER := preload("res://assets/domestique.glb")
const KING := preload("res://assets/roi.glb")
const LOAD := preload("res://assets/charge.glb")
const LIMBS := ["BrasG", "BrasD", "JambeG", "JambeD"]
const SPEED := 4.2
const SPRINT := 6.9

var controls_enabled := false
var yaw := 0.0
var elevation := 0.33
var camera_distance := 6.1
var current_distance := 6.1
var camera := Camera3D.new()
var visual: Node3D
var limbs: Array[Node3D] = []
var phase := 0.0
var stride := 0.0
var rotating := false
var camera_target := Vector3.ZERO
var surfaces := Surfaces.new()
var cargo: Node3D
var carried := ""
var _footsteps: AudioStreamPlayer
var _footstep_sounds: Dictionary = {}
var _stride_distance := 0.0
var _gesture_time := 0.0
var _gesture_yaw := 0.0
var _gesture_delivery := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.42
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.31
	capsule.height = 1.78
	var body_shape := CollisionShape3D.new()
	body_shape.shape = capsule
	body_shape.position.y = 0.90
	add_child(body_shape)
	# Short steps at the bridge and royal hall are handled by walking onto the capsule's rounded foot.
	max_slides = 8
	set_royal(false)
	camera.fov = 61.0
	camera.far = 150.0
	camera.top_level = true
	add_child(camera)
	camera_target = global_position + Vector3.UP * 1.12
	if DisplayServer.get_name() != "headless":
		_footsteps = AudioStreamPlayer.new()
		add_child(_footsteps)
		_footsteps.volume_db = -18.0
		for surface in ["stone", "soil", "wood"]:
			_footstep_sounds[surface] = _make_step(surface)


func set_royal(royal: bool) -> void:
	cargo = null
	carried = ""
	var facing := PI
	if visual != null:
		facing = visual.rotation.y
		remove_child(visual)
		visual.queue_free()
	var scene: PackedScene = KING if royal else WORKER
	var prefix := "roi_" if royal else "domestique_"
	visual = scene.instantiate() as Node3D
	visual.rotation.y = facing
	surfaces.dress(visual, false)
	add_child(visual)
	limbs.clear()
	for limb: String in LIMBS:
		limbs.append(visual.get_node(NodePath(prefix + limb)) as Node3D)


func set_cargo(id: String) -> void:
	if id == carried:
		return
	carried = id
	if cargo:
		visual.remove_child(cargo)
		cargo.queue_free()
		cargo = null
	if id.is_empty():
		return
	cargo = LOAD.instantiate() as Node3D
	var asset_id := "grain" if id == "grain_sec" else id
	for piece: Node3D in cargo.get_children():
		piece.visible = piece.name == "charge_" + asset_id
	cargo.position = Vector3(0.282, 1.16, 0.355)
	cargo.scale = Vector3.ONE * 0.86
	if id == "puits":
		cargo.position.y -= 0.18
	surfaces.dress(cargo, false)
	visual.add_child(cargo)


func enable_controls(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		rotating = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		rotating = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if rotating else Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			camera_distance = clampf(camera_distance + (-0.60 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.60), 3.6, 8.8)
	elif event is InputEventMouseMotion and rotating:
		yaw -= event.relative.x * 0.005
		elevation = clampf(elevation + event.relative.y * 0.004, 0.27, 1.15)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("left", "right", "forward", "back")
	var direction := Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw)
	var speed := SPRINT if Input.is_action_pressed("sprint") else SPEED
	if carried in ["grain", "grain_sec", "bois", "foin"]:
		speed *= 0.84
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 28.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 28.0)
	velocity.y = 0.0 if is_on_floor() else velocity.y - delta * 24.0
	move_and_slide()
	if direction.length_squared() > 0.01:
		var angle := atan2(direction.x, direction.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, angle, 1.0 - exp(-delta * 15.0))
		_gesture_time = 0.0
	elif _gesture_time > 0.0:
		visual.rotation.y = lerp_angle(visual.rotation.y, _gesture_yaw, 1.0 - exp(-delta * 14.0))
		_gesture_time = maxf(0.0, _gesture_time - delta)
	_animate(delta)
	_update_camera(delta)


func _animate(delta: float) -> void:
	var pace := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	stride = lerpf(stride, minf(pace / SPEED, 1.26), 1.0 - exp(-delta * 12.0))
	phase = fmod(phase + delta * (2.0 + pace * 1.55), TAU)
	if not _footstep_sounds.is_empty() and is_on_floor() and pace > 0.5:
		_stride_distance += pace * delta
		if _stride_distance > (0.84 if pace > SPEED else 0.69):
			_stride_distance = 0.0
			_play_step()
	visual.position.y = 0.018 * sin(phase * 2.0) * stride
	for i in limbs.size():
		var limb := limbs[i]
		var pivot := Vector3((-0.22 if i % 2 == 0 else 0.22), 1.42, 0.0)
		if i >= 2:
			pivot = Vector3((-0.10 if i % 2 == 0 else 0.10), 0.88, 0.0)
		var sign_value := 1.0 if i == 0 or i == 3 else -1.0
		limb.rotation.x = sin(phase) * stride * sign_value * (0.49 if i >= 2 else 0.38)
		if i == 1 and not carried.is_empty():
			limb.rotation.x = -0.96 + sin(phase) * stride * 0.028
		if i == 1 and _gesture_time > 0.0:
			var extension := sin((1.0 - _gesture_time / 0.45) * PI)
			limb.rotation.x = lerpf(limb.rotation.x, -0.85 if _gesture_delivery else -0.58, extension)
		limb.position = pivot - limb.basis * pivot


func _update_camera(delta: float) -> void:
	var anchor := global_position + Vector3.UP * 1.12
	camera_target = camera_target.lerp(anchor, 1.0 - exp(-delta * 15.0))
	current_distance = lerpf(current_distance, camera_distance, 1.0 - exp(-delta * 9.0))
	var distance := current_distance
	var offset := Vector3(0, sin(elevation), cos(elevation)).rotated(Vector3.UP, yaw) * distance
	var desired := camera_target + offset
	var ray := PhysicsRayQueryParameters3D.create(camera_target, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		var collision: Vector3 = hit["position"]
		desired = collision - offset.normalized() * 0.31
	if camera.global_position.distance_squared_to(desired) > 150.0 or not hit.is_empty():
		camera.global_position = desired
	else:
		camera.global_position = camera.global_position.lerp(desired, 1.0 - exp(-delta * 13.0))
	camera.look_at(camera_target + Vector3.UP * 0.15)



func service_gesture(at: Vector3, delivery: bool) -> void:
	var direction := at - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.02:
		return
	_gesture_yaw = atan2(direction.x, direction.z)
	_gesture_delivery = delivery
	_gesture_time = 0.45


func _play_step() -> void:
	var at := global_position
	var surface := "soil"
	if absf(at.x) < 2.1 and at.z > 24.0 and at.z < 35.9:
		surface = "wood"
	elif (absf(at.x) < 2.2 and absf(at.z) < 22.0) or at.z < -12.0 or absf(at.z - 7.4) < 1.0:
		surface = "stone"
	_footsteps.stream = _footstep_sounds[surface]
	_footsteps.pitch_scale = randf_range(0.92, 1.11)
	_footsteps.play()


func _make_step(surface: String) -> AudioStreamWAV:
	const RATE := 16000
	const SAMPLES := 1800
	var data := PackedByteArray()
	data.resize(SAMPLES * 2)
	var random := RandomNumberGenerator.new()
	random.seed = surface.hash()
	var resonance := {"stone": 147.0, "soil": 87.0, "wood": 113.0}
	var last := 0.0
	for index in SAMPLES:
		var time := float(index) / RATE
		var noise := random.randf_range(-1.0, 1.0)
		last = lerpf(last, noise, 0.24)
		var grit := (noise - last) * (0.39 if surface == "stone" else 0.19)
		var body := sin(TAU * float(resonance[surface]) * time) * 0.44
		var envelope := minf(time * 510.0, 1.0) * exp(-time * (39.0 if surface == "wood" else 55.0))
		data.encode_s16(index * 2, roundi((body + grit + last * 0.33) * envelope * 20000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream
