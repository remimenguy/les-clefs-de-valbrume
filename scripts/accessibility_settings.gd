extends RefCounted

const PATH := "user://valbrume_options.cfg"
const DEFAULT_GUIDANCE := true
const DEFAULT_TEXT_SCALE := 100
const TEXT_SCALES := [100, 125, 150]
const INTERACT := &"interact"
const JOURNAL := &"journal"
const MOVEMENT := [&"left", &"right", &"forward", &"back", &"sprint"]

var detailed_rendering := false
var guidance := DEFAULT_GUIDANCE
var text_scale := DEFAULT_TEXT_SCALE
var interact_key := KEY_E
var journal_key := KEY_J


func load_from(path: String) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		apply_bindings()
		return
	var saved_quality: Variant = file.get_value("affichage", "détaillé", false)
	detailed_rendering = saved_quality if saved_quality is bool else false
	var saved_guidance: Variant = file.get_value("lecture", "repères", DEFAULT_GUIDANCE)
	var saved_scale: Variant = file.get_value("lecture", "taille_texte", DEFAULT_TEXT_SCALE)
	var saved_interact: Variant = file.get_value("clavier", "interaction", KEY_E)
	var saved_journal: Variant = file.get_value("clavier", "journal", KEY_J)
	guidance = saved_guidance if saved_guidance is bool else DEFAULT_GUIDANCE
	text_scale = saved_scale if saved_scale is int and saved_scale in TEXT_SCALES else DEFAULT_TEXT_SCALE
	if saved_interact is int and saved_journal is int 			and _can_bind(saved_interact) and _can_bind(saved_journal) 			and saved_interact != saved_journal:
		interact_key = saved_interact as Key
		journal_key = saved_journal as Key
	apply_bindings()


func save_to(path: String) -> Error:
	var file := ConfigFile.new()
	file.set_value("affichage", "détaillé", detailed_rendering)
	file.set_value("lecture", "repères", guidance)
	file.set_value("lecture", "taille_texte", text_scale)
	file.set_value("clavier", "interaction", int(interact_key))
	file.set_value("clavier", "journal", int(journal_key))
	var pending := path + ".tmp"
	var result := file.save(pending)
	if result != OK:
		return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(path))


func reset() -> void:
	detailed_rendering = false
	guidance = DEFAULT_GUIDANCE
	text_scale = DEFAULT_TEXT_SCALE
	interact_key = KEY_E
	journal_key = KEY_J
	apply_bindings()


func bind(action: StringName, key: Key) -> String:
	if not _can_bind(key):
		return "Cette touche est réservée. Essaie une autre lettre, un chiffre ou une touche de fonction."
	if (action == INTERACT and key == journal_key) or (action == JOURNAL and key == interact_key):
		return "Cette touche est déjà attribuée à l’autre commande."
	match action:
		INTERACT:
			interact_key = key
		JOURNAL:
			journal_key = key
		_:
			return "Cette commande ne peut pas être modifiée ici."
	apply_bindings()
	return ""


func apply_bindings() -> void:
	_apply_keyboard(INTERACT, [interact_key])
	_apply_keyboard(JOURNAL, [journal_key, KEY_ESCAPE, KEY_TAB])


static func key_label(physical: Key) -> String:
	var local := physical if DisplayServer.get_name() == "headless" else DisplayServer.keyboard_get_keycode_from_physical(physical)
	var caption := OS.get_keycode_string(local if local != KEY_NONE else physical)
	return caption.to_lower()


func _can_bind(key: Key) -> bool:
	var supported := (key >= KEY_A and key <= KEY_Z) or (key >= KEY_0 and key <= KEY_9) 		or (key >= KEY_F1 and key <= KEY_F12)
	if not supported:
		return false
	for action: StringName in MOVEMENT:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey and (event.physical_keycode == key or event.keycode == key):
				return false
	return true


func _apply_keyboard(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
