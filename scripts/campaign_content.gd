extends RefCounted
## French narrative copy keyed by stable scene, choice and character identifiers.

const ACTORS := {
	"cuisiniere": "Aélis, cuisinière",
	"palefrenier": "Perrin, palefrenier",
	"garde": "Colin, garde",
	"intendant": "Ysabeau, intendante",
	"scribe": "Martin, scribe",
	"meuniere": "Agnès, meunière",
	"forestiere": "Maud, forestière",
	"veilleur": "Rémi, veilleur",
	"messager": "Jehan, messager",
	"jardiniere": "Héloïse, jardinière",
	"charpentier": "Gautier, charpentier",
	"chapelaine": "Sœur Alix, chapelaine",
}

const SCENES := {
	"services": {
		"speaker": ACTORS["intendant"],
		"title": "La première cloche",
		"text": "Perrin et Aélis sont déjà au travail. Choisis par où commencer entre la basse-cour, l’écurie et le potager. Quand tu auras rendu service à deux d’entre eux, reviens me dire comment tu t’y es pris.",
		"choices": [{"id": "accepter", "label": "Prendre le service", "detail": "Choisis l’ordre de tes premières tâches."}],
	},
	"horse": {
		"speaker": ACTORS["palefrenier"],
		"title": "À portée de voix",
		"text": "Il a senti le foin, mais le seau renversé l’a fait sursauter. Approche par le côté. Je peux aussi le tenir pendant que tu remplis son auge.",
		"choices": [
			{"id": "calmer", "label": "Calmer le cheval", "detail": "Perrin te montre comment approcher une bête effrayée."},
			{"id": "mener", "label": "Le mener avec Perrin", "detail": "Perrin tient la longe pendant que tu déposes le foin."},
		],
	},
	"message": {
		"speaker": ACTORS["messager"],
		"title": "Le pli du rempart",
		"text": "Le relevé des sacs et des accès est sous ce sceau. Quelqu’un doit en prendre connaissance avant la relève. Ysabeau peut faire vérifier les comptes. Colin peut faire vérifier le passage.",
		"choices": [
			{"id": "maison", "label": "Confier le pli à la maison", "detail": "Ysabeau reçoit le relevé pour contrôler les livraisons."},
			{"id": "garnison", "label": "Confier le pli à la garnison", "detail": "Colin reçoit le relevé avant la relève et retient ton aide."},
		],
	},
	"veille": {
		"speaker": ACTORS["garde"],
		"title": "La ronde du soir",
		"text": "Je connais les portes et tu connais les gens qui s’en servent. Pendant la ronde, on t’indiquera le passage de la réserve. Si la cloche sonne et que tu dois l’emprunter, viens me trouver.",
		"choices": [{"id": "accepter", "label": "Prendre part à la veille", "detail": "Colin t’explique comment demander l’accès au passage de la réserve."}],
	},
	"crise": {
		"speaker": ACTORS["intendant"],
		"title": "La nuit du grenier",
		"text": "Une tuile a cédé sous l’orage. L’eau tombe sur les sacs, et les représentants de la vallée sont attendus à table. Va voir le grenier et ce qu’il reste de sec. Aélis peut encore revoir le repas si elle est prévenue avant la prochaine cloche.",
		"choices": [{"id": "accepter", "label": "Inspecter le grenier", "detail": "La crise commence. Le temps compte dès que tu reprends la main."}],
	},
	"jument": {
		"speaker": ACTORS["palefrenier"],
		"title": "La jument dans le passage",
		"text": "L’orage l’a poussée en travers de la porte. Il y a trois chemins vers les cuisines. La porte de l’écurie, la galerie de service ou le passage que garde Colin.",
		"choices": [
			{"id": "calmer", "label": "Calmer la jument", "detail": "Reprends les gestes appris avec Perrin pour libérer le passage."},
			{"id": "galerie", "label": "Passer par la galerie", "detail": "Fais le détour par la galerie de service sans déranger la jument."},
			{"id": "garde", "label": "Demander le passage gardé", "detail": "Retrouve Colin et prends la responsabilité de l’ouverture."},
		],
	},
	"garde_passage": {
		"speaker": ACTORS["garde"],
		"title": "Sous ta responsabilité",
		"text": "D’accord, je te donne le passage. Si on me demande pourquoi cette porte a été ouverte, je dirai qui en a donné l’ordre. Va, Aélis attend.",
		"choices": [{"id": "autoriser", "label": "Assumer l’ouverture", "detail": "Tu obtiens l’accès avec l’accord de Colin."}],
	},
	"banquet": {
		"speaker": ACTORS["cuisiniere"],
		"title": "Ce qu’on met à table",
		"text": "J’ai encore du temps pour changer le repas. Quatre sacs suffisent à tenir le banquet. Avec un seul, je peux servir une soupe et du pain. Si tu ouvres la réserve d’urgence, je peux préparer un repas chaud et garder le reste au sec.",
		"choices": [
			{"id": "banquet", "label": "Maintenir le banquet", "detail": "Tu dépenses quatre sacs pour honorer le repas promis."},
			{"id": "reduire", "label": "Servir un repas réduit", "detail": "Tu dépenses un sac et expliques aux invités pourquoi le repas a changé."},
			{"id": "reserve", "label": "Puiser dans la réserve d’urgence", "detail": "Tu fais inscrire l’ouverture de la réserve et consacres trois sacs au repas."},
		],
	},
	"lendemain": {
		"speaker": ACTORS["intendant"],
		"title": "Les comptes du lendemain",
		"text": "Aélis m’a remis son état des vivres. Avant d’écrire le mien, je veux entendre comment la nuit s’est passée de ton côté. Ensuite, nous déciderons ensemble de ce qui revient aux cuisines et de ce qui reste pour demain.",
		"choices": [{"id": "expliquer", "label": "Raconter la nuit du grenier", "detail": "Ysabeau te confie la suite du service et l’état des réserves."}],
	},
	"ration": {
		"speaker": ACTORS["intendant"],
		"title": "La part de chacun",
		"text": "Les cuisines demandent de quoi passer la journée. Tu peux leur allouer un sac dès maintenant, emprunter deux sacs au hameau ou demander à Aélis de répartir elle-même ce qu’elle a déjà.",
		"choices": [
			{"id": "rations", "label": "Allouer un sac aux cuisines", "detail": "Les cuisines reçoivent un sac prélevé sur les réserves communes."},
			{"id": "dette", "label": "Emprunter deux sacs au hameau", "detail": "Tu gagnes deux sacs et inscris la dette au registre."},
			{"id": "deleguer", "label": "Confier la répartition à Aélis", "detail": "Aélis organise le service avec les moyens dont elle dispose déjà."},
		],
	},
	"conseil": {
		"speaker": ACTORS["scribe"],
		"title": "Devant le conseil",
		"text": "Le siège de Valbrume est vacant. En l’absence d’un héritier reconnu, la coutume permet à la maison, à la garnison et à la vallée d’entendre les témoins avant de désigner quelqu’un. Nous avons les comptes de la nuit du grenier. À toi de dire quels ordres tu as donnés et pourquoi.",
		"choices": [{"id": "temoigner", "label": "Témoigner devant le conseil", "detail": "Tu présentes les décisions que tu as prises et les engagements que tu as tenus."}],
	},
	"sacre": {
		"speaker": ACTORS["chapelaine"],
		"title": "La couronne de Valbrume",
		"text": "La maison et la garnison ont donné leur parole, et les représentants de la vallée attendent la tienne. Jure de les entendre comme tu as écouté ceux de la cour. Quand le serment sera prononcé, Colin fera lever la herse.",
		"choices": [{"id": "couronner", "label": "Prononcer le serment", "detail": "Tu deviens souverain de Valbrume et la vallée s’ouvre à toi."}],
	},
	"hameau": {
		"speaker": ACTORS["meuniere"],
		"title": "La mesure du moulin",
		"text": "Tu as vu le moulin. La roue peine et le boisseau du château contient plus que le nôtre. Les deux problèmes pèsent sur le pain des familles. Par lequel veux-tu commencer ?",
		"choices": [
			{"id": "reparer", "label": "Faire réparer le moulin", "detail": "Tu engages les ressources de la couronne pour remettre la roue en état."},
			{"id": "verifier", "label": "Faire vérifier les mesures", "detail": "Tu fais comparer publiquement les mesures du château et du hameau."},
			{"id": "alleger", "label": "Alléger les prélèvements", "detail": "Les familles conservent davantage de farine et le château réduit ses attentes."},
		],
	},
	"ruines": {
		"speaker": ACTORS["veilleur"],
		"title": "La route de Haute-Garde",
		"text": "La borne et la charte parlent toutes deux d’un passage. La charte est abîmée, et chaque famille lit le dernier mot à sa manière. Les charrettes font le tour en attendant ton ordre.",
		"choices": [
			{"id": "ouvrir", "label": "Rouvrir le passage", "detail": "Les deux familles peuvent emprunter la route sous la protection de la couronne."},
			{"id": "enqueter", "label": "Faire examiner la charte", "detail": "Le scribe compare les preuves. Le détour reste en vigueur pendant l’examen."},
			{"id": "peage", "label": "Autoriser un passage à péage", "detail": "Le passage rouvre. Une redevance sert à l’entretien de la route."},
		],
	},
	"boisroyal": {
		"speaker": ACTORS["forestiere"],
		"title": "Du bois pour l’hiver",
		"text": "Les souches que tu as vues se trouvent sur la terre de la couronne. Plusieurs foyers manquent de bois sec. Je peux leur désigner une coupe, borner une zone protégée ou faire livrer du bois d’ailleurs.",
		"choices": [
			{"id": "coupe", "label": "Accorder un droit de coupe", "detail": "Les habitants peuvent couper dans une zone définie sous la surveillance de Maud."},
			{"id": "proteger", "label": "Protéger la lisière", "detail": "La coupe s’arrête à la limite de la parcelle royale."},
			{"id": "acheter", "label": "Acheter du bois ailleurs", "detail": "La couronne prend en charge l’approvisionnement des familles."},
		],
	},
	"retour": {
		"speaker": ACTORS["cuisiniere"],
		"title": "Le retour à Valbrume",
		"text": "Je t’ai connu avec un seau à la main. Je peux encore te dire quand la farine est mauvaise. Raconte-moi ce que tu as vu au moulin, sur la route et au bois. Le conseil attend le même récit que nous.",
		"choices": [{"id": "conclure", "label": "Rendre compte de la tournée", "detail": "Tu inscris tes décisions dans les comptes du château et clos la première tournée."}],
	},
	"repos": {
		"speaker": "Dortoir du château",
		"title": "La fin du service",
		"text": "Le banc est libre près de la fenêtre. La première cloche annoncera le service du lendemain.",
		"choices": [{"id": "dormir", "label": "Attendre le matin", "detail": "Le jour suivant commence à la première cloche."}],
	},
}

const RESIDENT_LINES := {
	"cuisiniere": {
		"matin": "Il faut laisser la pâte lever avant de réchauffer le four. Je l’ai appris un matin où j’ai dû faire déjeuner toute la garnison avec des galettes.",
		"midi": "Les bols ébréchés sont pour nous. Si quelqu’un se plaint qu’il reste du pain, regarde d’abord si les gens de la relève ont mangé.",
		"soir": "Je compte ce qui reste avant d’éteindre les feux. Demain, je pourrai commencer sans réveiller tout le château.",
		"nuit": "Le feu est couvert. Si quelqu’un t’envoie chercher du pain, il en reste un peu près du four.",
	},
	"palefrenier": {
		"matin": "Je commence par le cheval qui tape du pied. C’est souvent la litière qu’il faut changer, ou un autre cheval qui l’empêche de manger.",
		"midi": "Tu peux passer près des auges. Annonce-toi avant de toucher une bête et laisse-lui la place de reculer.",
		"soir": "Je tends la main au cheval avant de défaire sa longe. Comme ça, il voit ce qui arrive, même dans la pénombre.",
		"nuit": "Si tu dois passer, évite de faire claquer le loquet. La jument sursaute au moindre bruit quand il pleut.",
	},
	"garde": {
		"matin": "Je regarde qui passe avant de regarder ce qu’on lui porte. Jehan est déjà revenu trois fois pour le même pli.",
		"midi": "Si tu cherches quelqu’un, demande d’abord où il travaille. À cette heure, la moitié des gens ont changé de cour.",
		"soir": "À la relève, je donne le compte des portes et des passages. Les accès ouverts sur ordre figurent dans le registre.",
		"nuit": "La grande herse ferme le château. La galerie de service longe les cuisines et revient dans la cour.",
	},
	"intendant": {
		"matin": "Si deux personnes te demandent la même chose, commence par celle qui doit finir à la prochaine cloche. Préviens l’autre.",
		"midi": "Un registre sert surtout à trouver ce qui manque. Pour savoir pourquoi cela manque, je descends voir les gens.",
		"soir": "Je garde une place pour les faits encore incertains. On peut corriger un compte demain si on écrit aujourd’hui ce qu’on a réellement vu.",
		"nuit": "Aélis connaît l’état du fournil. Perrin connaît celui de l’écurie. Si tu dois agir de nuit, appuie-toi sur eux.",
	},
	"scribe": {
		"matin": "La cire blanche est pour les plis qui restent ici. La rouge est pour ceux que quelqu’un devra pouvoir reconnaître.",
		"midi": "Une dette change selon qu’on la compte en sacs ou en farine. J’écris toujours la mesure à côté du chiffre.",
		"soir": "Les témoins s’accordent mieux quand je leur demande séparément à quelle cloche la porte s’est ouverte.",
		"nuit": "Je relis les signatures à la lanterne. Les doubles sont à portée de main si la cour doit vérifier un ordre.",
	},
	"meuniere": {
		"matin": "Je mesure le grain avant le lever du soleil. Quand la roue tourne mal, je sais déjà quelle famille risque d’attendre son pain.",
		"midi": "Apporte le boisseau du château et je poserai le nôtre à côté. Nous pourrons compter sans nous crier dessus.",
		"soir": "Les derniers sacs sont pour les familles qui travaillent loin du moulin. Elles n’arrivent qu’à la fin de la journée.",
		"nuit": "J’entends la roue depuis chez moi. Depuis qu’elle frotte, je me réveille avant l’aube.",
	},
	"forestiere": {
		"matin": "Je regarde les souches avant les arbres. On sait alors quels foyers ont déjà fait leur provision.",
		"midi": "Au bord du bois, je peux montrer où la coupe passe sans abîmer les jeunes pousses.",
		"soir": "Si les familles laissent une pile près du chemin, je sais combien de bois elles pourront ramener avant la nuit.",
		"nuit": "Je reconnais les bûcherons au bruit de leurs charrettes. À cette heure, ils devraient déjà être rentrés.",
	},
	"veilleur": {
		"matin": "De Haute-Garde, on voit les charrettes prendre le détour. Avant que cette route ferme, elles étaient au marché à la première cloche.",
		"midi": "Regarde la pierre près de l’ancien chemin. On y a gravé le signe du passage avant de recopier la charte.",
		"soir": "Je compte les charrettes qui rebroussent chemin. C’est le seul moyen que j’ai de mesurer ce que coûte la fermeture.",
		"nuit": "Quand le vent se lève dans les ruines, je me tiens près de la borne. Les gens savent où me trouver.",
	},
	"messager": {
		"matin": "Je porte les plis qu’on m’a confiés hier. On trouve plus facilement leur destinataire avant qu’il prenne son poste.",
		"midi": "Si tu prends un pli, dis-moi à qui tu comptes le remettre. Je pourrai répondre si son auteur vient me trouver.",
		"soir": "Le premier chemin que j’ai appris longe le fournil. Il sent toujours la fumée, même après la pluie.",
		"nuit": "Je garde les plis au sec jusqu’à la cloche. Pour le reste, je préfère confier le message à quelqu’un de réveillé.",
	},
	"jardiniere": {
		"matin": "Arrose près des racines. Si la surface brille, attends un peu avant de verser le reste.",
		"midi": "Les herbes fraîches sont pour Aélis. Laisse-lui les tiges, elle en fait un bouillon quand le repas doit être raccourci.",
		"soir": "Je regarde la terre au pied du mur. C’est là que je décide si demain on commence avec le seau.",
		"nuit": "Les feuilles bougent sous la pluie, et la terre reste sombre jusqu’au matin. On le voit mieux depuis le puits.",
	},
	"charpentier": {
		"matin": "Je vérifie les marches et les planches sur les chemins du service. Quand elles cèdent, c’est toujours avec quelqu’un qui porte une charge.",
		"midi": "J’ai mis le bois sec à part. Si les cuisines en manquent, dis-le-moi avant qu’on monte le reste à l’étage.",
		"soir": "Au premier signe de pluie, va voir le grenier. L’eau prend les fentes les plus fines, et la paille au pied du mur boit tout.",
		"nuit": "On répare mieux à la lumière du jour. Cette nuit, je peux déplacer les sacs qui sont encore à portée.",
	},
	"chapelaine": {
		"matin": "La première cloche est pour ceux qui commencent. Je la sonne assez tôt pour que les gens du fournil aient le temps de finir leur pain.",
		"midi": "Si tu as promis quelque chose, je peux t’aider à trouver la personne à qui tu l’as promis.",
		"soir": "Quand la cour se vide, on entend des gens se parler qu’on ne voit jamais ensemble à table.",
		"nuit": "Je tiens une lampe allumée pour la relève. Si tu viens chercher un endroit calme, tu peux rester un moment.",
	},
}

const CRISIS_REACTIONS := {
	"cuisiniere": {
		"banquet": "Les invités ont mangé comme prévu. J’ai marqué quatre sacs sur mon relevé. Demain, je ferai l’inventaire avec toi.",
		"reduire": "Ils ont eu de la soupe et du pain. Un invité a demandé ce qui se passait, alors je lui ai parlé du grenier. Il a fini son bol.",
		"reserve": "On a gardé le repas chaud et le grain sec. J’ai donné à Ysabeau le nom de la personne qui a autorisé l’ouverture.",
		"perte": "J’ai fait écarter les sacs mouillés. Je peux encore cuire demain avec ce qui reste, si on décide des rations ce soir.",
	},
	"intendant": {
		"banquet": "Le banquet a été servi. Je peux l’écrire dans mon rapport et je dois aussi y écrire ce qu’il a coûté.",
		"reduire": "Les réserves ont tenu. Nous devrons expliquer aux invités pourquoi le repas a changé si la question revient au conseil.",
		"reserve": "L’ouverture de la réserve est au registre. Nous savons ce qui a été sorti et qui en répond.",
		"perte": "Le grain perdu est compté. Les équipes attendent une décision sur les prochains repas.",
	},
	"meuniere": {
		"banquet": "Nous avons appris que le banquet avait été servi malgré l’orage. Au hameau, on se demande quelle part de la farine restera ici cet hiver.",
		"reduire": "Tu as réduit le repas au château quand les sacs ont pris l’eau. Les familles d’ici ont entendu ce que tu leur as épargné.",
		"reserve": "J’ai entendu dire que la réserve d’urgence avait fourni le repas. Au moulin, je voudrais qu’on sache aussi quand elle sera remplie.",
		"perte": "L’orage a touché le grenier. Si le château vient chercher de la farine ici, j’aimerais que les mesures soient claires.",
	},
}

const ROYAL_REACTIONS := {
	"meuniere": {
		"reparer": "On a de quoi remettre la roue en état. Je garde les premiers sacs pour les familles qui ont attendu le plus longtemps.",
		"verifier": "J’ai posé les deux boisseaux côte à côte. Maintenant, quand quelqu’un dit « une mesure », tout le monde sait de laquelle il parle.",
		"alleger": "Il nous reste davantage de farine après le prélèvement. Le premier sac qui reste ici ira au four commun.",
	},
	"veilleur": {
		"ouvrir": "Les charrettes passent à nouveau. Ce matin, les deux familles ont utilisé la route sans avoir à se mettre d’accord sur le dernier mot de la charte.",
		"enqueter": "La charte est partie à l’examen. J’explique aux voyageurs pourquoi le détour tient encore et qui regarde les preuves.",
		"peage": "Les gens paient pour passer. Je note ce qu’on prend à chaque charrette pour que la réparation de la route figure dans les comptes.",
	},
	"forestiere": {
		"coupe": "Les foyers ont un endroit où couper. Je leur montre quels troncs prendre et où s’arrête le droit.",
		"proteger": "La lisière est protégée. Quand une famille vient chercher du bois, je lui indique où se termine la parcelle royale.",
		"acheter": "Les familles attendent la livraison de bois. J’ai mis par écrit ce dont chaque foyer a besoin avant l’arrivée des charrettes.",
	},
}


static func scene(id: String) -> Dictionary:
	var entry: Dictionary = SCENES.get(id, {})
	return entry.duplicate(true)


static func resident(id: String, phase: String, outcome: String, decision: String) -> Dictionary:
	if not ACTORS.has(id):
		return {}
	var daily_lines: Dictionary = RESIDENT_LINES[id]
	var crisis_lines: Dictionary = CRISIS_REACTIONS.get(id, {})
	var royal_lines: Dictionary = ROYAL_REACTIONS.get(id, {})
	var line: String = daily_lines.get(phase, daily_lines["matin"])
	if royal_lines.has(decision):
		line = royal_lines[decision]
	elif crisis_lines.has(outcome):
		line = crisis_lines[outcome]
	return {
		"speaker": ACTORS[id],
		"title": "Un mot en passant",
		"text": line,
		"choices": [{"id": "fermer", "label": "Prendre congé", "detail": ""}],
	}
