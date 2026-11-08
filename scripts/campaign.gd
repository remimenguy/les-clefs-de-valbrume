extends "res://scripts/progression.gd"

const ROYAL_CLUES := {"hameau": "moulin", "ruines": "charte", "boisroyal": "lisiere"}
const ROYAL_EVIDENCE := {"hameau": "balances", "ruines": "ancien_chemin", "boisroyal": "affouage"}
const TESTIMONY := ["temoin_maison", "temoin_garnison", "temoin_vallee"]
const ROYAL_ORDERS := {
	"hameau": ["reparer", "verifier", "alleger"],
	"ruines": ["ouvrir", "enqueter", "peage"],
	"boisroyal": ["coupe", "proteger", "acheter"],
}
const JOBS := [
	["grain", "poules", "poules_nourries", "cuisiniere"],
	["foin", "cheval", "cheval_nourri", "palefrenier"],
	["puits", "jardin", "jardin_arrose", "jardiniere"],
	["bois", "cuisine", "foyer_allume", "cuisiniere"],
	["pain", "table", "table_servie", "intendant"],
]
const VALID_FLAGS := [
	"service_pris", "poules_nourries", "cheval_nourri", "jardin_arrose",
	"foyer_allume", "table_servie", "message_remis", "veille_faite",
	"jument_apprise", "grenier_inspecte", "jument_calmee", "galerie",
	"route_garde", "garde_passage", "responsabilite_garde", "route_prete",
	"reserve_ouverte", "grain_mouille", "rapport_rendu", "ration_rations",
	"ration_dette", "ration_deleguer", "promesse_vivres", "conseil_tenu",
	"enquete_moulin", "enquete_charte", "enquete_lisiere", "enquete_balances",
	"enquete_ancien_chemin", "enquete_affouage", "pont_franchi", "retour_conseil",
	"temoin_maison", "temoin_garnison", "temoin_vallee", "sac_livre",
]
const SUPPORT_IDS := ["cuisiniere", "palefrenier", "jardiniere", "garde", "intendant", "scribe", "meuniere"]
const OUTCOMES := ["", "banquet", "reduire", "reserve", "perte"]
const CARGO_NAMES := {
	"grain": "Sac de grain", "foin": "Botte de foin", "puits": "Seau d’eau",
	"bois": "Bûches", "pain": "Miche de pain", "sceau": "Sceau royal", "grain_sec": "Sac de grain sec",
}
const ACTIONS := {
	"services": ["Prendre ton service", "Lis le tableau des services au bord de l’allée. Choisis par quel travail commencer."],
	"grain": ["Prendre le grain", "Les sacs sont près des tonneaux de la cour."],
	"poules": ["Nourrir les poules", "Apporte le grain à l’auge de la basse-cour."],
	"foin": ["Prendre du foin", "Une botte t’attend devant l’écurie."],
	"cheval": ["Approcher le cheval", "Observe l’animal avant de lui présenter le foin."],
	"puits": ["Puiser de l’eau", "Remplis un seau au puits de la cour."],
	"jardin": ["Arroser le potager", "Apporte le seau jusqu’aux planches de légumes."],
	"bois": ["Ramasser des bûches", "Le bois est empilé près du chemin des cuisines."],
	"cuisine": ["Raviver le foyer", "Apporte les bûches aux cuisines."],
	"pain": ["Prendre la miche", "Le pain chaud attend aux cuisines."],
	"table": ["Servir la table", "Dépose la miche sur la table du logis."],
	"message": ["Transmettre le message", "Aux archives, décide qui doit recevoir la première copie."],
	"veille": ["Faire la relève", "Retrouve le veilleur du côté de la herse. Il peut te parler des accès de service."],
	"crise": ["La nuit du grenier", "Ysabeau t’attend près des cuisines. La cloche du soir approche."],
	"grenier": ["Inspecter le grenier", "Entre par la cour. Observe les sacs et les traces d’eau près de l’entrée."],
	"jument": ["Trouver un passage", "Retrouve Perrin à l’écurie. Il connaît la jument et les autres chemins."],
	"galerie": ["Passer par la galerie", "Emprunte l’accès de service près du grenier et vérifie que la galerie est libre."],
	"garde_passage": ["Demander le passage", "Parle au garde près de la sortie de service de l’écurie."],
	"sac_sec": ["Préparer le sac sec", "Retourne au grenier pour emporter un sac avant de donner ton ordre aux cuisines."],
	"reserve": ["Ouvrir la réserve", "Vérifie le verrou du grenier. L’ouverture sera inscrite au registre."],
	"banquet": ["Décider du repas", "Rejoins la table du logis. Le grain doit être réparti avant la dernière cloche."],
	"lendemain": ["Rendre compte", "Présente le bilan à Ysabeau au logis. Le rapport ouvre la journée suivante."],
	"ration": ["Répartir les vivres", "Retrouve Aélis près des cuisines et décide comment couvrir les prochains services."],
	"temoin_maison": ["Entendre Aélis", "Demande à Aélis près des cuisines de témoigner sur les services du château."],
	"temoin_garnison": ["Entendre Colin", "La garnison tient son registre près de la herse. Demande à Colin d’en attester."],
	"temoin_vallee": ["Entendre la représentante", "La représentante de la vallée attend près de la table du logis."],
	"conseil": ["Entendre les témoignages", "Rejoins le conseil au logis pour faire reconnaître le travail accompli."],
	"trone": ["Recevoir la couronne", "La chapelaine t’attend au pied du trône."],
	"moulin": ["Examiner le moulin", "Regarde les mesures et l’état du moulin au hameau des Aulnes."],
	"balances": ["Comparer les mesures", "Vérifie les boisseaux déposés dans la cour du hameau."],
	"hameau": ["Statuer sur le moulin", "Écoute Agnès au hameau et rends ta décision."],
	"charte": ["Lire la borne de Haute-Garde", "Examine les inscriptions près de l’arcade des ruines."],
	"ancien_chemin": ["Suivre l’ancien chemin", "Vérifie le tracé au-delà de la borne de Haute-Garde."],
	"ruines": ["Statuer sur le droit de passage", "Le veilleur des ruines attend ton jugement."],
	"lisiere": ["Observer les coupes du bois", "Cherche les traces de coupe à la lisière du bois du Cerf."],
	"affouage": ["Lire les marques de coupe", "Traverse le bois jusqu’à la seconde coupe, au pied du versant."],
	"boisroyal": ["Décider de l’usage du bois", "Écoute la forestière et choisis une règle pour l’hiver."],
	"retour": ["Retourner aux cuisines", "Rentre par la herse. Aélis t’attend pour parler de ce que tu as vu dehors."],
	"repos": ["Prendre du repos", "Le banc des domestiques est à l’ouest de la cour."],
	"intendant": ["Remettre l’ancien sceau", "Le sceau de ton ancien registre est encore dans tes mains."],
}
const CHOICES := {
	"services": ["accepter"], "cheval": ["calmer", "mener"], "message": ["maison", "garnison"],
	"veille": ["accepter"], "crise": ["accepter"], "jument": ["calmer", "galerie", "garde"],
	"garde_passage": ["autoriser"], "banquet": ["banquet", "reduire", "reserve"],
	"lendemain": ["expliquer"], "ration": ["rations", "dette", "deleguer"],
	"temoin_maison": ["attester"], "temoin_garnison": ["attester"], "temoin_vallee": ["attester"],
	"conseil": ["temoigner"], "trone": ["couronner"], "retour": ["conclure"], "repos": ["dormir"],
}
const ORDER_EFFECTS := {
	"reparer": [-2, "Le hameau répare le moulin. Une première livraison est promise."],
	"verifier": [0, "Agnès et le scribe vérifieront ensemble les mesures de farine."],
	"alleger": [-1, "La couronne renonce à une part du prélèvement du hameau."],
	"ouvrir": [0, "La route de Haute-Garde est ouverte aux deux familles."],
	"enqueter": [0, "Le conseil demandera une seconde lecture de la charte."],
	"peage": [1, "Un péage paiera l’entretien de la route de Haute-Garde."],
	"coupe": [0, "Le bois ouvre un droit de coupe contrôlé par la forestière."],
	"proteger": [-1, "Une zone du bois est protégée. Le château contribue à l’approvisionnement."],
	"acheter": [-2, "La couronne achète du bois ailleurs pour passer l’hiver."],
}

var rank := 0
var day := 1
var minute := 390
var grain := 8
var deadline := -1
var outcome := ""
var cargo := ""
var flags: Array[String] = []
var supporters: Array[String] = []
var records: Array[String] = []
var decisions: Dictionary = {}
var checkpoint := Vector3.INF


func rank_index() -> int:
	return rank


func is_king() -> bool:
	return rank == RANKS.size() - 1


func carried_item() -> String:
	return cargo


func target() -> String:
	var list := objectives()
	return list[0]["id"] if not list.is_empty() else ""


func action() -> String:
	return ACTIONS.get(target(), ["", ""])[0]


func hint() -> String:
	return ACTIONS.get(target(), ["", ""])[1]


func interact(id: String) -> bool:
	return perform(id)


func discover(_id: String) -> bool:
	# Discovery in this campaign is tied to a completed investigation and decision.
	return false


func phase() -> String:
	if minute >= 1260 or minute < 360:
		return "nuit"
	if minute >= 1020:
		return "soir"
	return "midi" if minute >= 660 else "matin"


func crisis() -> String:
	if not outcome.is_empty():
		return "resolue"
	return "active" if deadline >= 0 else "attente"


func advance_minutes(amount: int) -> bool:
	if amount <= 0:
		return false
	var now := mini(_absolute() + amount, 9999 * 1440 - 1)
	day = now / 1440 + 1
	minute = now % 1440
	if deadline >= 0 and now >= deadline:
		_resolve_crisis("perte")
		return true
	return false


func mark_crossing() -> bool:
	return is_king() and _flag("pont_franchi")


func objectives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in _available():
		var details: Array = ACTIONS[id]
		var objective := {"id": id, "title": details[0], "hint": details[1]}
		if id == "banquet" and deadline >= 0:
			objective["hint"] += " Dernière cloche dans %d min." % (deadline - _absolute())
		result.append(objective)
	return result


func options(id: String) -> Array:
	if not available(id):
		return []
	var choices: Array = ROYAL_ORDERS.get(id, CHOICES.get(id, [])).duplicate()
	if id == "jument" and not flags.has("jument_apprise"):
		choices.erase("calmer")
	if id == "banquet" and not flags.has("reserve_ouverte"):
		choices.erase("reserve")
	return choices


func available(id: String) -> bool:
	if id == "repos":
		return flags.has("service_pris") and deadline < 0
	return _available().has(id)


func _available() -> Array[String]:
	var result: Array[String] = []
	if not flags.has("service_pris"):
		return ["services"]
	if cargo == "sceau":
		result.append("intendant")
	elif not cargo.is_empty():
		for job: Array in JOBS:
			if job[0] == cargo:
				result.append(job[1])
				break
	# During emergencies, the route and deadline take priority over routine chores.
	match rank:
		0:
			if cargo.is_empty():
				for index in 3:
					_add_job(result, index)
		1:
			if cargo.is_empty():
				_add_job(result, 3 if not flags.has("foyer_allume") else 4)
			if not flags.has("message_remis"):
				result.append("message")
		2:
			if deadline >= 0:
				if not flags.has("grenier_inspecte"):
					result.append("grenier")
				elif not flags.has("route_prete"):
					if flags.has("galerie"):
						result.append("galerie")
					elif flags.has("route_garde"):
						result.append("garde_passage")
					else:
						result.append("jument")
				else:
					result.append("banquet" if cargo == "grain_sec" else "sac_sec")
					if not flags.has("reserve_ouverte"):
						result.append("reserve")
			elif not outcome.is_empty():
				result.append("lendemain")
			else:
				result.append("crise")
				if not flags.has("veille_faite"):
					result.append("veille")
		3:
			if not _has_ration():
				result.append("ration")
			elif _witness_count() >= 2:
				result.append("conseil")
			else:
				for witness: String in TESTIMONY:
					if not flags.has(witness):
						result.append(witness)
		4:
			result.append("trone")
		5:
			for region: String in ROYAL_CLUES:
				if not decisions.has(region):
					var clue: String = ROYAL_CLUES[region]
					var evidence: String = ROYAL_EVIDENCE[region]
					if not flags.has("enquete_" + clue):
						result.append(clue)
					elif not flags.has("enquete_" + evidence):
						result.append(evidence)
					else:
						result.append(region)
			if result.is_empty() and not flags.has("retour_conseil"):
				result.append("retour")
	return result


func _add_job(result: Array[String], index: int) -> void:
	var job: Array = JOBS[index]
	if not flags.has(job[2]):
		result.append(job[0])


func perform(id: String, choice: String = "") -> bool:
	if not available(id):
		return false
	var choices := options(id)
	if (not choices.is_empty() and not choices.has(choice)) or (choices.is_empty() and not choice.is_empty()):
		return false
	for job: Array in JOBS:
		if id == job[0]:
			cargo = id
			return true
		if id == job[1]:
			cargo = ""
			_flag(job[2])
			_support(job[3])
			if choice == "calmer":
				_flag("jument_apprise")
			_record("%s. %s" % [ACTIONS[id][0], "Le geste rassure la jument." if choice == "calmer" else "Le service est rendu."])
			_review_promotions()
			return true
	match id:
		"services":
			_flag("service_pris")
			_record("Le premier service commence dans la cour.")
		"message":
			_flag("message_remis")
			_support("garde" if choice == "garnison" else "scribe")
			_record("La première copie part %s." % ("à la garnison" if choice == "garnison" else "à la maison"))
			_review_promotions()
		"veille":
			_flag("veille_faite")
			_support("garde")
			_record("La relève connaît désormais ton nom et le motif de ta ronde.")
		"crise":
			if minute >= 1050:
				day = mini(day + 1, 9999)
			minute = 1050
			deadline = _absolute() + 110
			grain = 7
			_flag("grain_mouille")
			_record("Un orage menace les sacs du grenier. La dernière cloche est à 19 h 20.")
		"grenier":
			_flag("grenier_inspecte")
			_record("Des sacs ont pris l’eau. Sept mesures sèches restent utilisables.")
		"jument":
			match choice:
				"calmer":
					_flag("jument_calmee")
					_flag("route_prete")
					_record("La jument reconnaît ton approche et libère le passage.")
				"galerie":
					_flag("galerie")
					_record("Perrin t’indique la galerie de service du grenier.")
				"garde":
					_flag("route_garde")
					_record("Le passage gardé peut servir avec l’accord du garde.")
		"galerie":
			_flag("route_prete")
			_record("Tu vérifies le passage de service pour les porteurs.")
		"garde_passage":
			_flag("garde_passage")
			_flag("responsabilite_garde")
			_flag("route_prete")
			_support("garde")
			_record("Colin ouvre le passage. Ton nom reste au registre de veille.")
		"sac_sec":
			cargo = "grain_sec"
			_record("Le sac sec peut être porté aux cuisines.")
		"reserve":
			_flag("reserve_ouverte")
			_record("La réserve est ouverte et inscrite au registre. Quatre mesures sont disponibles.")
		"banquet":
			_flag("sac_livre")
			_resolve_crisis(choice)
		"lendemain":
			_flag("rapport_rendu")
			_support("intendant")
			_support("cuisiniere")
			_next_dawn()
			_promote(3, "Ysabeau te confie les comptes et les services du château.")
		"ration":
			_flag("ration_" + choice)
			match choice:
				"rations":
					grain = maxi(0, grain - 1)
					_support("meuniere")
					_record("Une mesure est réservée aux rations promises.")
				"dette":
					grain += 2
					_support("scribe")
					_record("Deux mesures sont avancées au château. La dette est consignée.")
				"deleguer":
					_support("cuisiniere")
					_record("Aélis et Perrin prennent la relève des prochains services.")
			_flag("promesse_vivres")
		"temoin_maison", "temoin_garnison", "temoin_vallee":
			_flag(id)
			_support({"temoin_maison": "cuisiniere", "temoin_garnison": "garde", "temoin_vallee": "meuniere"}[id])
			_record({
				"temoin_maison": "Aélis atteste que les cuisines ont tenu leur service.",
				"temoin_garnison": "Colin présentera les passages consignés pendant la crise.",
				"temoin_vallee": "La représentante de la vallée fera entendre l’engagement sur les rations.",
			}[id])
		"conseil":
			_flag("conseil_tenu")
			_support("intendant")
			_promote(4, "Le conseil reconnaît les témoignages de la maison et te confie la régence.")
		"trone":
			_promote(5, "Le conseil confirme le sacre. La grande herse s’ouvre.")
		"moulin", "charte", "lisiere", "balances", "ancien_chemin", "affouage":
			_flag("enquete_" + id)
			_record({
				"moulin": "Les mesures du moulin diffèrent du registre. L’essieu montre des traces de rupture.",
				"charte": "L’inscription mentionne un droit de passage partagé par deux familles.",
				"lisiere": "Les souches fraîches jouxtent les arbres marqués de la couronne.",
				"balances": "Deux boisseaux scellés portent des graduations différentes. La différence est mesurable.",
				"ancien_chemin": "Une trace de charrette confirme l’ancienne voie des deux familles.",
				"affouage": "Les marques récentes distinguent les coupes pour le chauffage du bois réservé.",

			}[id])
		"hameau", "ruines", "boisroyal":
			decisions[id] = choice
			if not discoveries.has(id):
				discoveries.append(id)
			var effect: Array = ORDER_EFFECTS[choice]
			grain = maxi(0, grain + int(effect[0]))
			_record(effect[1])
		"retour":
			_flag("retour_conseil")
			_record("Tu rapportes au château ce que les trois lieux t’ont appris.")
		"intendant":
			cargo = ""
			_support("intendant")
			_record("Ysabeau reçoit le sceau repris avec ton ancien registre.")
		"repos":
			_next_dawn()
			_record("Tu prends du repos. La cloche annonce une nouvelle journée.")
		_:
			return false
	return true


func world_view() -> Dictionary:
	return {"minute": minute, "phase": phase(), "rank": rank, "crisis": crisis(),
		"outcome": outcome, "flags": flags.duplicate(), "decisions": decisions.duplicate(), "grain": grain}


func journal_view() -> Dictionary:
	var view := world_view()
	view.merge({"rank_title": rank_title(), "day": day, "objectives": objectives(),
		"records": records.duplicate(), "supporters": supporters.duplicate(),
		"completed": decisions.size() if is_king() else rank,
		"total": ROYAL_CLUES.size() if is_king() else RANKS.size() - 1,
		"carried": CARGO_NAMES.get(cargo, ""), "royal": is_king()})
	return view


func snapshot() -> Dictionary:
	return {"version": 2, "rank": rank, "day": day, "minute": minute, "grain": grain,
		"deadline": deadline, "outcome": outcome, "cargo": cargo, "flags": flags.duplicate(),
		"supporters": supporters.duplicate(), "records": records.duplicate(), "decisions": decisions.duplicate(),
		"discoveries": discoveries.duplicate(), "checkpoint": _saved_checkpoint()}


func restore(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if data.get("version") == 1:
		return _migrate(data)
	if data.get("version") != 2 or not _valid_state(data):
		return false
	rank = int(data["rank"])
	deed = THRESHOLDS[rank]
	day = int(data["day"])
	minute = int(data["minute"])
	grain = int(data["grain"])
	deadline = int(data["deadline"])
	outcome = data["outcome"]
	cargo = data["cargo"]
	flags.assign(data["flags"])
	supporters.assign(data["supporters"])
	records.assign(data["records"])
	discoveries.assign(data["discoveries"])
	decisions = data["decisions"].duplicate()
	var spot: Array = data["checkpoint"]
	checkpoint = Vector3(spot[0], spot[1], spot[2]) if spot.size() == 3 else Vector3.INF
	return true


func _valid_state(data: Dictionary) -> bool:
	if not _integer(data.get("rank"), 0, 5) or not _integer(data.get("day"), 1, 9999):
		return false
	if not _integer(data.get("minute"), 0, 1439) or not _integer(data.get("grain"), 0, 99):
		return false
	if not _integer(data.get("deadline"), -1, 9999 * 1440 + 110) or not OUTCOMES.has(data.get("outcome")):
		return false
	var now: int = (int(data["day"]) - 1) * 1440 + int(data["minute"])
	var due: int = int(data["deadline"])
	if due >= 0 and (data["rank"] != 2 or due <= now or due > now + 110 or data["outcome"] != ""):
		return false
	if data.get("cargo") != "" and not CARGO_NAMES.has(data.get("cargo")):
		return false
	if not _list(data.get("flags"), VALID_FLAGS) or not _list(data.get("supporters"), SUPPORT_IDS):
		return false
	if not _list(data.get("discoveries"), ROYAL_CLUES.keys()) or not data.get("records") is Array:
		return false
	if data["records"].size() > 40:
		return false
	for line: Variant in data["records"]:
		if not line is String or line.length() > 240:
			return false
	var orders: Variant = data.get("decisions")
	if not orders is Dictionary or (data["rank"] < 5 and (not orders.is_empty() or not data["discoveries"].is_empty())):
		return false
	for id: Variant in orders:
		if not ROYAL_ORDERS.has(id) or not ROYAL_ORDERS[id].has(orders[id]) or not data["discoveries"].has(id):
			return false
	return _valid_checkpoint(data.get("checkpoint"), data["rank"] == 5)


func _migrate(data: Dictionary) -> bool:
	var legacy = load("res://scripts/progression.gd").new()
	if not legacy.restore(data):
		return false
	var old_deed: int = legacy.deed
	restore({"version": 2, "rank": legacy.rank_index(), "day": 1, "minute": 390, "grain": 8,
		"deadline": -1, "outcome": "", "cargo": legacy.carried_item(), "flags": [], "supporters": [],
		"records": [], "decisions": {}, "discoveries": legacy.discoveries, "checkpoint": []})
	if old_deed > 0 or legacy.step > 0:
		_flag("service_pris")
	for index: int in mini(old_deed, JOBS.size()):
		_flag(JOBS[index][2])
		_support(JOBS[index][3])
	if old_deed >= 4:
		_flag("message_remis")
	if old_deed >= 6:
		_support("garde")
	for id: String in discoveries:
		_flag("enquete_" + ROYAL_CLUES[id])
		_flag("enquete_" + ROYAL_EVIDENCE[id])
	if old_deed > 0:
		_record("Ton ancien registre de service a été repris.")
	return true


func _review_promotions() -> void:
	if rank == 0:
		var completed := 0
		for index in 3:
			completed += int(flags.has(JOBS[index][2]))
		if completed >= 2:
			_promote(1, "Deux services attestés te donnent accès au logis comme valet.")
	elif rank == 1 and flags.has("table_servie") and flags.has("message_remis"):
		_promote(2, "Ton service au logis et le message transmis te valent les clefs.")


func _resolve_crisis(result: String) -> void:
	outcome = result
	deadline = -1
	if cargo == "grain_sec":
		cargo = ""
	match result:
		"banquet":
			grain -= 4
			_record("Le banquet a lieu. Quatre mesures quittent les réserves.")
		"reduire":
			grain -= 1
			_support("meuniere")
			_record("Le repas est réduit. Les cuisines préservent les rations.")
		"reserve":
			grain += 1
			_record("Quatre mesures sortent de la réserve et trois sont servies. L’ouverture est consignée.")
		"perte":
			grain -= 3
			_record("La dernière cloche a sonné. Trois mesures sont perdues, le reste peut être réparti demain.")


func _witness_count() -> int:
	var count := 0
	for witness: String in TESTIMONY:
		count += int(flags.has(witness))
	return count


func _has_ration() -> bool:
	return flags.has("ration_rations") or flags.has("ration_dette") or flags.has("ration_deleguer")


func _promote(index: int, note: String) -> void:
	rank = index
	deed = THRESHOLDS[index]
	_record(note)


func _absolute() -> int:
	return (day - 1) * 1440 + minute


func _next_dawn() -> void:
	if minute >= 360:
		day = mini(day + 1, 9999)
	minute = 390


func _flag(id: String) -> bool:
	if flags.has(id):
		return false
	flags.append(id)
	return true


func _support(id: String) -> void:
	if not supporters.has(id):
		supporters.append(id)


func _record(line: String) -> void:
	records.append(line)
	if records.size() > 40:
		records.pop_front()


func _saved_checkpoint() -> Array:
	if not checkpoint.is_finite():
		return []
	var spot := [checkpoint.x, checkpoint.y, checkpoint.z]
	return spot if _valid_checkpoint(spot, is_king()) else []


func _valid_checkpoint(value: Variant, royal: bool) -> bool:
	if not value is Array:
		return false
	if value.is_empty():
		return true
	if value.size() != 3:
		return false
	for item: Variant in value:
		if not (item is float or item is int) or not is_finite(float(item)):
			return false
	if value[1] < -0.1 or value[1] > 4.5:
		return false
	if royal:
		return absf(value[0]) < 65 and value[2] > -42 and value[2] < 82
	return absf(value[0]) < 21.4 and absf(value[2]) < 21.4


func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and value >= low and value <= high and value == floorf(value)


func _list(value: Variant, allow: Array) -> bool:
	if not value is Array or value.size() > allow.size():
		return false
	var seen := {}
	for id: Variant in value:
		if not id is String or not allow.has(id) or seen.has(id):
			return false
		seen[id] = true
	return true
