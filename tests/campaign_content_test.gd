extends SceneTree

const CONTENT_PATH := "res://scripts/campaign_content.gd"
const SCENE_CHOICES := {
	"horse": ["calmer", "mener"],
	"message": ["maison", "garnison"],
	"crise": ["accepter"],
	"jument": ["calmer", "galerie", "garde"],
	"banquet": ["banquet", "reduire", "reserve"],
	"lendemain": ["expliquer"],
	"ration": ["rations", "dette", "deleguer"],
	"conseil": ["temoigner"],
	"sacre": ["couronner"],
	"hameau": ["reparer", "verifier", "alleger"],
	"ruines": ["ouvrir", "enqueter", "peage"],
	"boisroyal": ["coupe", "proteger", "acheter"],
	"retour": ["conclure"],
	"garde_passage": ["autoriser"],
	"repos": ["dormir"],
	"services": ["accepter"],
	"veille": ["accepter"],
}
const ACTOR_IDS := [
	"cuisiniere", "palefrenier", "garde", "intendant", "scribe", "meuniere",
	"forestiere", "veilleur", "messager", "jardiniere", "charpentier", "chapelaine",
]

var failures := 0


func _initialize() -> void:
	check(FileAccess.file_exists(CONTENT_PATH), "La campagne fournit un catalogue de dialogues.")
	if failures > 0:
		quit(1)
		return

	var content := load(CONTENT_PATH) as Script
	check(content != null, "Le catalogue de dialogues est lisible.")
	if failures > 0:
		quit(1)
		return

	var actors: Dictionary = content.get_script_constant_map()["ACTORS"]
	for actor: String in ACTOR_IDS:
		check(not String(actors.get(actor, "")).is_empty(), "Le personnage %s est nommé." % actor)
		for phase in ["matin", "midi", "soir", "nuit"]:
			var conversation: Dictionary = content.call("resident", actor, phase, "", "")
			check_scene(conversation, ["fermer"], "%s %s" % [actor, phase])
			check(conversation.get("speaker") == actors.get(actor), "La réplique appartient à %s." % actor)

	for scene_id: String in SCENE_CHOICES:
		var conversation: Dictionary = content.call("scene", scene_id)
		check_scene(conversation, SCENE_CHOICES[scene_id], scene_id)

	var crisis: Dictionary = content.call("scene", "banquet")
	var original: String = crisis["choices"][0]["label"]
	crisis["choices"][0]["label"] = "Libellé temporaire"
	check(content.call("scene", "banquet")["choices"][0]["label"] == original,
		"Le filtrage du dialogue en cours ne modifie pas le catalogue.")

	var empty_scene: Dictionary = content.call("scene", "introuvable")
	check(empty_scene.is_empty(), "Un dialogue inconnu donne un résultat vide.")

	var banquet: Dictionary = content.call("resident", "cuisiniere", "soir", "banquet", "")
	var loss: Dictionary = content.call("resident", "cuisiniere", "soir", "perte", "")
	check(banquet["text"] != loss["text"], "Les cuisines distinguent le banquet et la perte de grain.")
	var repair: Dictionary = content.call("resident", "meuniere", "midi", "reduire", "reparer")
	var audit: Dictionary = content.call("resident", "meuniere", "midi", "reduire", "verifier")
	check(repair["text"] != audit["text"], "La meunière se souvient de la décision royale.")

	print("Dialogues de campagne · %d échec(s)" % failures)
	quit(int(failures > 0))


func check_scene(conversation: Dictionary, expected_choices: Array, context: String) -> void:
	for field in ["speaker", "title", "text"]:
		check(not String(conversation.get(field, "")).strip_edges().is_empty(),
			"%s possède un champ %s." % [context, field])
	var actual_choices: Array[String] = []
	for choice: Dictionary in conversation.get("choices", []):
		actual_choices.append(String(choice.get("id", "")))
		check(not String(choice.get("label", "")).strip_edges().is_empty(),
			"%s possède un choix lisible." % context)
		check(choice.get("detail") is String, "%s renseigne le détail du choix." % context)
	check(actual_choices == expected_choices, "%s propose exactement les choix attendus." % context)


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)
