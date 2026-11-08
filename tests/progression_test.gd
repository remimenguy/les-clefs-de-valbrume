extends SceneTree

const Progress = preload("res://scripts/progression.gd")
var failures := 0

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	var progress := Progress.new()
	check(progress.rank_title() == "Domestique", "Le premier rang est Domestique")
	check(not progress.is_king(), "La herse reste fermée au départ")
	check(not progress.interact("poules"), "Le grain précède le nourrissage")
	check(progress.interact("grain"), "Le grain peut être ramassé")
	check(not progress.interact("grain"), "Un ramassage ne se répète pas")
	check(progress.carried_item() == "grain", "Le ramassage donne un objet à transporter")
	check(progress.deed == 0 and progress.step == 1, "Le ramassage seul ne valide pas la tâche")
	var restored := Progress.new()
	check(restored.restore(progress.snapshot()) and restored.target() == "poules", "La sauvegarde conserve une livraison en cours")
	check(not restored.restore({"version": 1, "deed": 8, "step": 99, "discoveries": []}), "Un index invalide est rejeté")
	check(restored.target() == "poules", "Une sauvegarde invalide ne modifie pas la partie")
	check(not progress.discover("hameau"), "La vallée ne se découvre pas avant le sacre")
	for stop in ["poules", "foin", "cheval", "puits", "jardin", "bois", "cuisine", "pain", "table", "garde", "sceau", "intendant"]:
		check(progress.interact(stop), "Étape valide : " + stop)
	check(progress.rank_title() == "Régent" and not progress.is_king(), "Le régent doit encore être couronné")
	check(progress.interact("trone") and progress.is_king(), "Le couronnement débloque la vallée")
	check(not progress.interact("trone"), "Le couronnement se valide une seule fois")
	check(progress.discover("hameau") and not progress.discover("hameau"), "Une découverte ne compte qu’une fois")
	check(not progress.discover("inconnu"), "Un lieu inconnu est rejeté")
	check(restored.restore(progress.snapshot()) and restored.is_king() and restored.discoveries == ["hameau"], "Le royaume est restauré")
	print("Progression : %d échec(s)" % failures)
	quit(int(failures > 0))
