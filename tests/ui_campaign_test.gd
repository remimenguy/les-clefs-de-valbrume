extends SceneTree

const Hud := preload("res://scripts/hud.gd")

var failures := 0
var selections: Array[String] = []
var dismissals := 0


func _initialize() -> void:
	await process_frame
	var ui: CanvasLayer = Hud.new()
	if not ui.has_method("dialogue") or not ui.has_method("campaign_journal"):
		_check(false, "Le journal et les dialogues de campagne sont disponibles")
		ui.free()
		quit(1)
		return

	var path := "user://ui_test_%s.cfg" % Time.get_ticks_usec()
	ui.set("settings_path", path)
	root.add_child(ui)
	ui.connect("choice_requested", func(choice: String) -> void: selections.append(choice))
	ui.connect("dialogue_dismissed", func() -> void: dismissals += 1)
	var view := {
		"rank_title": "Maître des clefs", "rank": 2, "day": 3, "phase": "soir",
		"minute": 1145, "grain": 5, "objectives": [
			{"id": "grenier", "title": "Voir le grenier", "hint": "Écoute la pluie sur le toit."},
		],
		"records": ["La jument a retrouvé son calme."], "supporters": ["Agnès"],
		"outcome": "", "decisions": {}, "completed": 2, "total": 5, "carried": "Sac de grain",
		"royal": false,
	}
	ui.call("update_campaign", view)
	_check((ui.get("rank") as Label).text == "Maître des clefs", "Le HUD présente le rang de campagne")
	ui.call("campaign_journal", view)
	var overlay: Control = ui.get("overlay")
	_check(_has_text(overlay, "Voir le grenier") and _has_text(overlay, "La jument a retrouvé son calme."),
		"Le journal distingue la priorité et les faits consignés")

	var options := overlay.find_child("Options", true, false) as Button
	_check(options != null, "Le journal ouvre les réglages")
	if options != null:
		options.pressed.emit()
		var guidance := overlay.find_child("Guidance", true, false) as CheckButton
		guidance.button_pressed = false
		_check(ui.get("guidance_enabled") == false and FileAccess.file_exists(path),
			"Le guidage est désactivé et le réglage est enregistré")
		var rebind := overlay.find_child("RebindInteract", true, false) as Button
		rebind.pressed.emit()
		var key := InputEventKey.new()
		key.pressed = true
		key.physical_keycode = KEY_K
		Input.parse_input_event(key)
		await process_frame
		_check(InputMap.event_is_action(key, &"interact"), "La nouvelle touche est active")
		var back := overlay.find_child("CloseOptions", true, false) as Button
		back.pressed.emit()
		_check(_has_text(overlay, "Voir le grenier"), "Les réglages reviennent au journal")

	ui.call("dialogue", {
		"speaker": "Agnès", "title": "La nuit du grenier", "text": "Il reste cinq mesures de grain.",
		"choices": [
			{"id": "reduire", "label": "Réduire le repas", "detail": "Préserver les rations."},
			{"id": "banquet", "label": "Tenir le banquet", "detail": "Tenir la promesse faite aux invités."},
		],
	})
	_check(_has_text(overlay, "Préserver les rations."), "Le dialogue détaille la conséquence d’un choix")
	var choice := overlay.find_child("Choice_reduire", true, false) as Button
	_check(choice != null, "Le choix possède une cible de focus")
	if choice != null:
		choice.pressed.emit()
		choice.pressed.emit()
	_check(selections == ["reduire"], "Le choix est transmis une seule fois")
	ui.call("dismiss_dialogue")
	ui.call("dismiss_dialogue")
	_check(dismissals == 1, "Le dialogue émet une seule demande de fermeture")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	ui.queue_free()
	await process_frame
	print("Interface de campagne : %d échec(s)" % failures)
	quit(int(failures > 0))


func _has_text(parent: Control, value: String) -> bool:
	for label: Label in parent.find_children("*", "Label", true, false):
		if label.text == value:
			return true
	return false


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
