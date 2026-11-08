extends SceneTree

var failures := 0
var campaign_script: Script


func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/campaign.gd"):
		check(false, "La campagne doit gérer le choix et la reprise des services")
		quit(1)
		return
	campaign_script = load("res://scripts/campaign.gd")
	_branching()
	_expiry_and_recovery()
	_guard_route()
	_migration()
	print("Campagne : %d échec(s)" % failures)
	quit(int(failures > 0))


func _branching() -> void:
	var run: Variant = campaign_script.new()
	check(run.rank_title() == "Domestique", "Rang initial")
	check(not run.perform("grain"), "Le service doit d’abord être pris")
	check(run.perform("services", "accepter"), "Prise de service")
	check(run.perform("foin"), "Le foin peut être ramassé avant le grain")
	check(not run.perform("grain"), "Un seul objet volumineux peut être porté")
	var restored: Variant = campaign_script.new()
	check(restored.restore(run.snapshot()) and restored.carried_item() == "foin", "La charge survit à une reprise")
	check(run.perform("cheval", "calmer"), "Le premier soin apprend à rassurer la jument")
	_do(run, ["grain", "poules"])
	check(run.rank_title() == "Valet", "Deux services attestés donnent le rang de valet")
	_do(run, ["bois", "cuisine", "pain", "table"])
	check(run.perform("message", "garnison"), "Le destinataire du message est choisi")
	check(run.rank_title() == "Maître des clefs", "Le service et le message ouvrent les clefs")
	check(run.perform("crise", "accepter"), "La crise démarre")
	check(not run.perform("banquet", "banquet"), "Un chemin d’acheminement est nécessaire")
	_do(run, ["grenier"])
	check(run.perform("jument", "calmer"), "La technique apprise est réutilisable")
	check(not run.perform("banquet", "reserve"), "La réserve fermée ne fournit aucun sac")
	_do(run, ["reserve", "sac_sec"])
	var suspended: Variant = campaign_script.new()
	check(suspended.restore(run.snapshot()), "Sauvegarde de la réserve ouverte")
	check(suspended.perform("banquet", "reserve"), "Le choix réutilise l’accès sauvegardé")
	check(not suspended.perform("banquet", "reserve"), "Le choix ne peut être payé ou validé deux fois")
	check(suspended.world_view()["outcome"] == "reserve" and suspended.world_view()["grain"] == 8, "Le bilan du grenier est cohérent")
	check(suspended.perform("lendemain", "expliquer"), "La crise conduit à un rapport le lendemain")
	check(suspended.perform("ration", "deleguer"), "L’intendant répartit les responsabilités")
	check(not suspended.perform("conseil", "temoigner"), "Le conseil attend les témoignages")
	check(suspended.perform("temoin_maison", "attester"), "Témoignage de la maison")
	check(suspended.perform("temoin_vallee", "attester"), "Témoignage de la vallée")
	check(suspended.perform("conseil", "temoigner"), "Le conseil reconnaît les services")
	check(not suspended.perform("hameau", "verifier"), "Le régent ne peut pas agir en roi")
	check(suspended.perform("trone", "couronner") and suspended.is_king(), "Sacre unique")
	check(not suspended.perform("hameau", "verifier"), "L’enquête précède la décision")
	_do(suspended, ["moulin", "balances", "charte", "ancien_chemin", "lisiere", "affouage"])
	check(suspended.perform("hameau", "reparer"), "Décision pour le hameau")
	check(suspended.perform("ruines", "ouvrir"), "Décision pour les ruines")
	check(suspended.perform("boisroyal", "proteger"), "Décision pour le bois")
	check(suspended.perform("retour", "conclure"), "Retour au château après les trois enquêtes")
	check(not suspended.perform("retour", "conclure"), "L’épilogue ne se rejoue pas")
	check(suspended.journal_view()["decisions"].size() == 3, "Le journal mémorise les trois décisions")


func _expiry_and_recovery() -> void:
	var run: Variant = campaign_script.new()
	check(run.restore({"version": 1, "deed": 5, "step": 0, "discoveries": []}), "Reprise d’une ancienne partie")
	check(run.perform("crise", "accepter"), "La crise est accessible après migration")
	run.advance_minutes(200)
	check(run.world_view()["outcome"] == "perte", "La crise peut expirer")
	check(run.perform("lendemain", "expliquer"), "L’expiration mène au rapport")
	check(run.rank_title() == "Intendant", "Un échec partiel ne bloque pas la campagne")


func _guard_route() -> void:
	var run: Variant = campaign_script.new()
	check(run.restore({"version": 1, "deed": 5, "step": 0, "discoveries": []}), "Le garde reste accessible après migration")
	check(run.perform("crise", "accepter") and run.perform("grenier"), "L’inspection ouvre les itinéraires")
	check(not run.options("jument").has("calmer"), "Sans apprentissage, l’itinéraire de la jument n’est pas proposé")
	check(run.perform("jument", "garde") and run.perform("garde_passage", "autoriser"), "L’accès gardé fournit un itinéraire de secours")
	check(run.perform("sac_sec") and run.perform("banquet", "banquet"), "Le banquet peut être maintenu par l’accès gardé")
	check(run.grain == 3 and run.flags.has("responsabilite_garde"), "Le registre conserve l’ordre et les vivres restants")


func _migration() -> void:
	var run: Variant = campaign_script.new()
	check(run.restore({"version": 1, "deed": 8, "step": 0, "discoveries": ["hameau"]}), "Migration d’un ancien roi")
	check(run.is_king() and run.discoveries == ["hameau"], "Rang et lieux déjà visités sont préservés")
	check(run.perform("hameau", "alleger"), "Un ancien lieu découvert peut recevoir une décision")
	var copy: Variant = campaign_script.new()
	check(copy.restore(run.snapshot()) and copy.journal_view()["decisions"].has("hameau"), "Le nouveau format reprend la décision")
	var invalid: Dictionary = run.snapshot()
	invalid["grain"] = -1
	check(not copy.restore(invalid) and copy.is_king(), "Un état corrompu est refusé sans altérer la partie")


func _do(run: Variant, steps: Array) -> void:
	for id: String in steps:
		check(run.perform(id), "Action disponible " + id)


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
