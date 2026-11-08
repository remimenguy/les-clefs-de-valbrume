extends SceneTree

const Game := preload("res://main.tscn")
const SaveGame = preload("res://scripts/save_game.gd")
const Campaign = preload("res://scripts/campaign.gd")
var failures := 0


func _initialize() -> void:
	await process_frame
	var path := "user://valbrume_test_%s.json" % Time.get_ticks_usec()
	var game := Game.instantiate()
	game.save_path = path
	root.add_child(game)
	await process_frame
	_check(game.world == null and not game.active, "Le menu s’affiche sans construire le monde")
	await game.start_game()
	if not game.active:
		_check(false, "Le château doit se charger depuis le menu")
		quit(1)
		return
	_check(game.target_id == "services", "Le jeu indique le tableau au départ")
	_press(&"journal")
	await physics_frame
	_check(game.journal_open and game.interface.overlay.visible and not game.player.controls_enabled,
		"Le journal affiche son écran et suspend les déplacements")
	_press(&"journal")
	await physics_frame
	_check(not game.journal_open and game.interface.hud.visible and game.player.controls_enabled,
		"Fermer le journal restaure les déplacements")
	_press(&"interact")
	await physics_frame
	_check(not game.progress.flags.has("service_pris"), "Interagir à distance ne valide pas le service")
	game.player.position = Vector3(0, 0.15, 19)
	await _drive("back", 110)
	_check(game.player.position.z < 22.0, "La herse bloque physiquement le joueur")
	await _action(game, "services", "accepter")
	await _action(game, "grain")
	_check(game.player.cargo != null and game.player.cargo.get_node("charge_grain").visible,
		"Le sac est visible après le ramassage")
	await _action(game, "poules")
	_check(game.player.cargo == null and game.world.birds_fed, "Le sac est déposé et les poules réagissent")
	await _action(game, "foin")
	await _action(game, "cheval", "calmer")
	_check(game.world.campaign_stage._doors["logement"]["open"], "Le rang de valet déverrouille le logement")
	for id: String in ["bois", "cuisine", "pain", "table"]:
		await _action(game, id)
	await _action(game, "message", "garnison")
	await _action(game, "crise", "accepter")
	await _action(game, "grenier")
	await _action(game, "jument", "galerie")
	await _action(game, "galerie")
	await _action(game, "sac_sec")
	_check(game.player.cargo != null and game.player.cargo.get_node("charge_grain").visible,
		"Le sac sauvé est porté pendant la crise")
	await _action(game, "banquet", "reduire")
	await _action(game, "lendemain", "expliquer")
	await _action(game, "ration", "rations")
	await _action(game, "temoin_maison", "attester")
	await _action(game, "temoin_garnison", "attester")
	await _action(game, "conseil", "temoigner")
	_check(game.progress.rank_title() == "Régent" and not game.world.gate_shape.disabled,
		"La herse reste fermée au rang de régent")
	await _action(game, "trone", "couronner")
	_check(game.progress.is_king() and game.target_id == "herse", "Le sacre active la sortie")
	_check(game.player.visual.name == "roi", "L’avatar porte la tenue royale")
	await create_timer(2.55).timeout
	_check(game.world.gate_shape.disabled, "La herse retire sa collision après ouverture")
	game.player.position = Vector3(0, 0.15, 19)
	await _drive("back", 300)
	_check(game.player.position.z > 36, "Le roi franchit la herse puis le pont à pied")
	await _action(game, "moulin")
	await _action(game, "balances")
	await _action(game, "hameau", "reparer")
	await _action(game, "charte")
	await _action(game, "ancien_chemin")
	await _action(game, "ruines", "ouvrir")
	await _action(game, "lisiere")
	await _action(game, "affouage")
	await _action(game, "boisroyal", "proteger")
	game.player.position = Vector3(0, 0.03, 24)
	game.player.velocity = Vector3.ZERO
	await _drive("forward", 95)
	_check(game.player.position.z < 20.5, "Le roi franchit le seuil de la herse en rentrant au château")
	await _action(game, "retour", "conclure")
	_check(game.progress.discoveries.size() == 3 and game.target_id.is_empty(),
		"Les trois décisions et le retour terminent le parcours")
	var restored := Campaign.new()
	SaveGame.load_into(restored, path)
	_check(restored.decisions == game.progress.decisions and restored.flags.has("retour_conseil"),
		"La sauvegarde disque reprend décisions et épilogue")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	var backup := Campaign.new()
	SaveGame.load_into(backup, path)
	_check(backup.is_king() and backup.discoveries.size() == 3 and not backup.flags.has("retour_conseil"),
		"La copie précédente récupère une sauvegarde endommagée")
	for suffix in ["", ".bak", ".tmp"]:
		var absolute := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(absolute):
			DirAccess.remove_absolute(absolute)
	game.queue_free()
	await process_frame
	print("Parcours en jeu : %d échec(s)" % failures)
	quit(int(failures > 0))


func _action(game: Node3D, id: String, choice: String = "") -> void:
	var at: Vector3 = game.world.point(id)
	game.player.position = at + Vector3(0.0, 0.025, 0.0)
	game.player.velocity = Vector3.ZERO
	await physics_frame
	_check(game._near_interaction() == id, "Action accessible à son point " + id)
	_press(&"interact")
	await physics_frame
	if not choice.is_empty():
		var button := game.interface.overlay.find_child("Choice_" + choice, true, false) as Button
		_check(game.dialogue_id == id and button != null, "Le dialogue propose " + choice + " pour " + id)
		if button:
			button.pressed.emit()
			await physics_frame
	_check(game.dialogue_id.is_empty(), "Le contrôle revient au joueur après " + id)


func _press(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()


func _drive(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)
	for i in 13:
		await physics_frame


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
