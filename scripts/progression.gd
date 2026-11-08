extends RefCounted

const RANKS := ["Domestique", "Valet", "Maître des clefs", "Intendant", "Régent", "Roi"]
const THRESHOLDS := [0, 2, 4, 6, 7, 8]
const LANDMARKS := {
	"hameau": "Le hameau des Aulnes",
	"ruines": "Les ruines de Haute-Garde",
	"boisroyal": "Le bois du Cerf",
}
const DEEDS := [
	{"title": "La basse-cour", "steps": [
		["grain", "Prendre le grain", "Les sacs attendent dans la cour, près des tonneaux."],
		["poules", "Nourrir les poules", "Dépose le grain dans l’auge du poulailler."],
	], "done": "Les poules accourent vers l’auge."},
	{"title": "L’écurie", "steps": [
		["foin", "Prendre une botte de foin", "Cherche les bottes devant l’écurie."],
		["cheval", "Nourrir le cheval", "Apporte le foin à la mangeoire."],
	], "done": "Le cheval s’approche pour manger."},
	{"title": "L’eau du potager", "steps": [
		["puits", "Puiser de l’eau", "Remplis le seau au puits de la cour."],
		["jardin", "Arroser les légumes", "Verse l’eau au pied des légumes du potager."],
	], "done": "La terre du potager est bien humide."},
	{"title": "Le feu des cuisines", "steps": [
		["bois", "Ramasser des bûches", "Prends du bois au bord du chemin des cuisines."],
		["cuisine", "Raviver le foyer", "Rapporte les bûches sous l’auvent des cuisines."],
	], "done": "Le foyer reprend. Le pain va pouvoir cuire."},
	{"title": "La table du conseil", "steps": [
		["pain", "Prendre le pain chaud", "La miche sort du four des cuisines."],
		["table", "Servir le conseil", "Porte le pain à la table du logis."],
	], "done": "Le conseil est servi. Les membres te remercient."},
	{"title": "La ronde du rempart", "steps": [
		["garde", "Parler au garde", "Retrouve le garde près de la herse et fais le point avec lui."],
	], "done": "Le garde confirme que la herse est sûre."},
	{"title": "Le sceau de Valbrume", "steps": [
		["sceau", "Récupérer le sceau", "Prends le sceau royal devant les archives, à l’est du logis."],
		["intendant", "Remettre le sceau", "Confie le sceau à l’intendant dans la salle du trône."],
	], "done": "L’intendant te transmet les clefs et te nomme régent."},
	{"title": "Le couronnement", "steps": [
		["trone", "Recevoir la couronne", "Avance jusqu’au trône pour recevoir la couronne de Valbrume."],
	], "done": "Tu es roi de Valbrume. La herse se lève et la vallée t’est ouverte."},
]

var deed := 0
var step := 0
var discoveries: Array[String] = []


func rank_index() -> int:
	for index in range(THRESHOLDS.size() - 1, -1, -1):
		if deed >= THRESHOLDS[index]:
			return index
	return 0


func rank_title() -> String:
	return RANKS[rank_index()]


func is_king() -> bool:
	return deed == DEEDS.size()


func target() -> String:
	return "" if is_king() else DEEDS[deed]["steps"][step][0]


func carried_item() -> String:
	return DEEDS[deed]["steps"][0][0] if step > 0 and not is_king() else ""


func action() -> String:
	return "" if is_king() else DEEDS[deed]["steps"][step][1]


func hint() -> String:
	return "" if is_king() else DEEDS[deed]["steps"][step][2]


func interact(id: String) -> bool:
	if is_king() or id != target():
		return false
	step += 1
	if step == DEEDS[deed]["steps"].size():
		deed += 1
		step = 0
	return true


func discover(id: String) -> bool:
	if not is_king() or not LANDMARKS.has(id) or discoveries.has(id):
		return false
	discoveries.append(id)
	return true


func snapshot() -> Dictionary:
	return {"version": 1, "deed": deed, "step": step, "discoveries": discoveries.duplicate()}


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1:
		return false
	var saved_deed: Variant = data.get("deed")
	var saved_step: Variant = data.get("step")
	var saved_places: Variant = data.get("discoveries")
	if not _index_in(saved_deed, DEEDS.size()) or not saved_places is Array:
		return false
	var last_step: int = 0 if saved_deed == DEEDS.size() else DEEDS[int(saved_deed)]["steps"].size() - 1
	if not _index_in(saved_step, last_step) or (saved_deed < DEEDS.size() and not saved_places.is_empty()):
		return false
	var places: Array[String] = []
	for place: Variant in saved_places:
		if not place is String or not LANDMARKS.has(place) or places.has(place):
			return false
		places.append(place)
	deed = int(saved_deed)
	step = int(saved_step)
	discoveries = places
	return true


func _index_in(value: Variant, last: int) -> bool:
	return (value is int or value is float) and value >= 0 and value <= last and value == floorf(value)
