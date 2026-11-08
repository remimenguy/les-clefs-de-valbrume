extends Node3D

signal world_ready

const Campaign = preload("res://scripts/campaign.gd")
const Story = preload("res://scripts/campaign_content.gd")
const SaveGame = preload("res://scripts/save_game.gd")
const Hud = preload("res://scripts/hud.gd")
const WORLD_PATH := "res://scripts/world.gd"
const PLAYER_PATH := "res://scripts/player.gd"
const CASTLE_PATH := "res://assets/chateau.glb"
const REACH := 2.25
const LANDMARK_REACH := 3.6
const SECONDS_PER_MINUTE := 3.4
const SCENE_IDS := {"cheval": "horse", "trone": "sacre"}
const REGIONAL_ACTORS := {"meuniere": "hameau", "veilleur": "ruines", "forestiere": "boisroyal"}

var save_path := SaveGame.PATH
var progress := Campaign.new()
var world: Variant
var player: Variant
var interface := Hud.new()
var marker: Label3D
var active := false
var loading := false
var journal_open := false
var dialogue_id := ""
var target_id := ""
var target_position := Vector3.ZERO
var prompt := ""
var interaction_id := ""
var _clock := 0.0
var _minute_clock := 0.0
var _refresh_clock := 0.0
var _started_at := Time.get_ticks_msec()
var _leaving := false
var _objectives: Array[Dictionary] = []
var _load_requested := false


func _ready() -> void:
	_bind_inputs()
	SaveGame.load_into(progress, save_path)
	add_child(interface)
	interface.start_requested.connect(start_game)
	interface.new_campaign_requested.connect(_new_campaign)
	interface.quality_changed.connect(_set_quality)
	interface.journal_requested.connect(_toggle_journal)
	interface.choice_requested.connect(_choose)
	interface.dialogue_dismissed.connect(_close_dialogue)
	interface.quit_requested.connect(_quit_game)
	interface.title_screen(progress.flags.has("service_pris"))
	if DisplayServer.get_name() != "headless":
		_prefetch_world.call_deferred()
	if "--timings" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		print("Menu disponible après %d ms depuis l’initialisation de la scène" %
			(Time.get_ticks_msec() - _started_at))


func _prefetch_world() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not active and not loading:
		_request_world()


func _request_world() -> bool:
	if not _load_requested:
		_load_requested = ResourceLoader.load_threaded_request(CASTLE_PATH) == OK
	return _load_requested


func start_game() -> void:
	if active or loading:
		return
	loading = true
	var load_start := Time.get_ticks_msec()
	interface.loading_status(0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	if not _request_world():
		_load_failed()
		return
	var fraction: Array = []
	var status := ResourceLoader.load_threaded_get_status(CASTLE_PATH, fraction)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		interface.loading_status(float(fraction[0]) * 0.82 if not fraction.is_empty() else 0.0)
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(CASTLE_PATH, fraction)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		_load_failed()
		return
	# Hold the imported castle while the world script takes over its reference.
	var castle_resource := ResourceLoader.load_threaded_get(CASTLE_PATH)
	var world_script := load(WORLD_PATH) as Script
	var player_script := load(PLAYER_PATH) as Script
	if castle_resource == null or world_script == null or player_script == null:
		_load_failed()
		return
	world = world_script.new()
	add_child(world)
	_set_quality(interface.quality_enabled)
	interface.loading_status(0.95)
	await get_tree().process_frame
	player = player_script.new()
	player.position = progress.checkpoint if progress.checkpoint.is_finite() else world.point("depart")
	add_child(player)
	if progress.is_king():
		player.set_royal(true)
	player.set_cargo(progress.carried_item())
	_build_marker()
	_sync_world()
	world.apply_progress(progress.deed, progress.is_king())
	player.camera.make_current()
	await get_tree().physics_frame
	loading = false
	active = true
	player.enable_controls(true)
	interface.gameplay()
	_refresh_objective()
	world_ready.emit()
	if "--timings" in OS.get_cmdline_user_args():
		print("Monde jouable après %d ms depuis le bouton" % (Time.get_ticks_msec() - load_start))


func _set_quality(detailed: bool) -> void:
	get_viewport().scaling_3d_scale = 1.0 if detailed else 0.78
	if world != null:
		world.set_quality(detailed)


func _new_campaign() -> void:
	if active or loading:
		return
	if not SaveGame.archive(progress, save_path):
		interface.loading_failed("La sauvegarde précédente n’a pas pu être mise de côté.")
		return
	var old := progress
	progress = Campaign.new()
	if not SaveGame.write(progress, save_path):
		progress = old
		interface.loading_failed("La sauvegarde précédente n’a pas pu être mise de côté.")
		return
	start_game()


func _load_failed() -> void:
	_load_requested = false
	loading = false
	interface.loading_failed("Valbrume n’a pas pu charger la scène. Tu peux réessayer.")


func _input(event: InputEvent) -> void:
	if not active or interface.is_settings_open() or not event.is_action_pressed("journal"):
		return
	if event is InputEventKey and event.physical_keycode == KEY_TAB and (journal_open or not dialogue_id.is_empty()):
		return
	if dialogue_id.is_empty():
		_toggle_journal()
	else:
		interface.dismiss_dialogue()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if active and not journal_open and dialogue_id.is_empty() and event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not active or journal_open or not dialogue_id.is_empty():
		return
	_clock += delta
	_minute_clock += delta
	if _minute_clock >= SECONDS_PER_MINUTE:
		_minute_clock -= SECONDS_PER_MINUTE
		if progress.advance_minutes(1):
			player.set_cargo(progress.carried_item())
			_publish("La dernière cloche", "Une partie des réserves est perdue. Le rapport du lendemain reste possible.")
		else:
			_sync_world()
			_refresh_objective()
	if player.position.z >= 35.6 and progress.mark_crossing():
		_persist()
		_refresh_objective()
	_refresh_clock += delta
	if _refresh_clock >= 0.14:
		_refresh_clock = 0.0
		_refresh_objective()
	interaction_id = _near_interaction()
	prompt = _prompt(interaction_id)
	marker.visible = interface.guidance_enabled and not target_id.is_empty()
	marker.position = target_position + Vector3.UP * (1.71 + sin(_clock * 3.2) * 0.14)
	interface.update_context(player.position, target_position, not target_id.is_empty(), progress.is_king(), prompt)


func _near_interaction() -> String:
	if not progress.is_king() and _near(world.point("herse"), REACH):
		return "herse_fermee"
	var selected := ""
	var best := INF
	for objective: Dictionary in _objectives:
		var id: String = objective["id"]
		var point: Vector3 = world.point(id)
		var limit := LANDMARK_REACH if Campaign.ROYAL_CLUES.has(id) else REACH
		if not _can_reach(point, limit):
			continue
		var distance: float = player.position.distance_squared_to(point)
		if distance < best:
			selected = id
			best = distance
	if not selected.is_empty():
		return selected
	if progress.available("repos") and _can_reach(world.point("repos"), 1.8):
		return "repos"
	for actor: String in Story.ACTORS:
		var place: Vector3 = world.point(actor)
		if _can_reach(place, 1.65):
			return "resident/" + actor
	return ""


func _prompt(id: String) -> String:
	if id == "herse_fermee":
		return "Examiner la herse"
	if id.begins_with("resident/"):
		return "Parler à " + str(Story.ACTORS[id.get_slice("/", 1)]).get_slice(",", 0)
	return Campaign.ACTIONS.get(id, ["", ""])[0]


func _get_prompt() -> String:
	return _prompt(_near_interaction())


func _interact() -> void:
	var id := _near_interaction()
	if id.is_empty():
		return
	if id == "herse_fermee":
		interface.notify("Herse fermée", "Seul le souverain peut faire lever la herse.")
		return
	if id.begins_with("resident/"):
		var actor := id.get_slice("/", 1)
		var region: String = REGIONAL_ACTORS.get(actor, "")
		var scene := Story.resident(actor, progress.phase(), progress.outcome, progress.decisions.get(region, ""))
		_show_dialogue(id, scene)
		return
	var choices := progress.options(id)
	if choices.is_empty():
		_perform(id, "")
		return
	var scene := Story.scene(SCENE_IDS.get(id, id))
	if id in Campaign.TESTIMONY:
		scene = _witness_scene(id)
	var offered: Array[Dictionary] = []
	for choice: Dictionary in scene.get("choices", []):
		if choices.has(choice["id"]):
			offered.append(choice)
	if offered.is_empty():
		return
	scene["choices"] = offered
	_show_dialogue(id, scene)


func _witness_scene(id: String) -> Dictionary:
	var lines: Array = {
		"temoin_maison": ["cuisiniere", "J’ai compté les sacs et vu le repas sortir du fournil. Dis au conseil que je témoignerai sur ce que nous avons pu servir."],
		"temoin_garnison": ["garde", "Le registre dit qui a demandé les clefs et ce qui était accessible. Je présenterai les faits à la relève du conseil."],
		"temoin_vallee": ["meuniere", "J’ai entendu l’engagement sur les vivres. Je parlerai pour ceux qui livrent le grain et pour ceux qui en attendent."],
	}[id]
	return {"speaker": Story.ACTORS[lines[0]], "title": "Un témoignage pour le conseil", "text": lines[1],
		"choices": [{"id": "attester", "label": "Consigner le témoignage", "detail": "Ce témoignage sera entendu au conseil."}]}


func _show_dialogue(id: String, scene: Dictionary) -> void:
	dialogue_id = id
	player.enable_controls(false)
	marker.hide()
	interface.dialogue(scene)


func _choose(choice: String) -> void:
	var id := dialogue_id
	if id.is_empty():
		return
	_close_dialogue()
	if not id.begins_with("resident/"):
		_perform(id, choice)


func _close_dialogue() -> void:
	if dialogue_id.is_empty():
		return
	dialogue_id = ""
	player.enable_controls(true)
	interface.gameplay()


func _perform(id: String, choice: String) -> void:
	var old_rank := progress.rank
	var before := progress.records.size()
	var old_cargo := progress.carried_item()
	if not progress.perform(id, choice):
		return
	var promoted := old_rank != progress.rank
	if promoted and progress.is_king():
		player.set_royal(true)
		world.apply_progress(progress.deed, true, true)
	player.set_cargo(progress.carried_item())
	if player.has_method("service_gesture"):
		player.service_gesture(world.point(id), not old_cargo.is_empty())
	var description := progress.records[-1] if progress.records.size() > before else ""
	if promoted:
		_publish("Nouveau rang · " + progress.rank_title(), description)
	elif not description.is_empty():
		_publish(_prompt(id), description)
	else:
		_publish("", "")


func _publish(title: String, description: String) -> void:
	if not title.is_empty():
		interface.notify(title, description)
	_sync_world()
	_persist()
	_refresh_objective()


func _sync_world() -> void:
	world.update_campaign(progress.world_view())
	var journal := _journal_view()
	_objectives.assign(journal["objectives"])
	interface.update_campaign(journal)


func _journal_view() -> Dictionary:
	var view := progress.journal_view()
	var names: Array[String] = []
	for actor: String in progress.supporters:
		names.append(Story.ACTORS.get(actor, actor))
	view["supporters"] = names
	return view


func _persist() -> void:
	if player != null:
		progress.checkpoint = player.position
	if not SaveGame.write(progress, save_path):
		interface.notify("Sauvegarde indisponible", "Ta progression reste active pour cette partie.")


func _quit_game() -> void:
	_leaving = true
	if active:
		_persist()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and active and not _leaving:
		_persist()


func _near(location: Vector3, distance: float) -> bool:
	if not location.is_finite():
		return false
	var here: Vector3 = player.position
	return Vector2(here.x - location.x, here.z - location.z).length_squared() <= distance * distance


func _can_reach(location: Vector3, distance: float) -> bool:
	if not _near(location, distance):
		return false
	var start: Vector3 = player.position + Vector3.UP
	var end := location + Vector3.UP
	if start.distance_squared_to(end) < 0.02:
		return true
	var ray := PhysicsRayQueryParameters3D.create(start, end, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or end.distance_to(hit["position"]) <= 0.42


func _refresh_objective() -> void:
	var tasks := _objectives
	var next: Dictionary = tasks[0] if not tasks.is_empty() else {}
	if progress.is_king() and not progress.flags.has("pont_franchi") and not tasks.is_empty():
		if player.position.z < 23.0:
			next = {"id": "herse", "title": "Franchir la herse", "hint": "Descends l’allée et quitte le château par la grande porte."}
		else:
			next = {"id": "pont", "title": "Traverser le pont", "hint": "Le pont de chêne mène aux chemins de la vallée."}
	elif not tasks.is_empty():
		var best := INF
		for task: Dictionary in tasks:
			var point: Vector3 = world.point(task["id"])
			if not point.is_finite():
				continue
			var distance: float = player.position.distance_squared_to(point)
			if distance < best:
				next = task
				best = distance
	target_id = next.get("id", "")
	target_position = Vector3.ZERO if target_id.is_empty() else world.point(target_id)
	if not target_position.is_finite():
		target_id = ""
		target_position = Vector3.ZERO
	interface.objective.text = next.get("title", "Le règne de Valbrume")
	interface.hint.text = next.get("hint", "Les affaires sont consignées. Tu peux retourner voir les gens de la vallée.")


func _toggle_journal() -> void:
	if not active or not dialogue_id.is_empty() or interface.is_settings_open():
		return
	journal_open = not journal_open
	player.enable_controls(not journal_open)
	if journal_open:
		marker.hide()
		interface.campaign_journal(_journal_view())
	else:
		interface.gameplay()


func _bind_inputs() -> void:
	var bindings := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"forward": [KEY_W, KEY_UP], "back": [KEY_S, KEY_DOWN],
		"sprint": [KEY_SHIFT], "interact": [KEY_E], "journal": [KEY_J, KEY_TAB, KEY_ESCAPE],
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


func _build_marker() -> void:
	marker = Label3D.new()
	marker.text = "◆"
	marker.font_size = 54
	marker.outline_size = 15
	marker.pixel_size = 0.011
	marker.modulate = Color("#ffd083")
	marker.outline_modulate = Color("#4c311e")
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.hide()
	add_child(marker)
