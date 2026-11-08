# Campagne de Valbrume

## Objectif

Développer l’ascension de domestique à roi et une campagne royale fondée sur des décisions persistantes. Le château est l’unique espace accessible avant le sacre.

## Architecture

`campaign.gd` valide les transitions et expose l’état du journal et du monde. `campaign_content.gd` contient les dialogues écrits. `game.gd` relie les entrées, les points d’interaction, le HUD, les effets et la sauvegarde. Godot 4.7 et les ressources Blender existantes restent la base de cette version.

- [x] Vérifier le choix des services, les promotions, la crise à embranchements et l’expiration dans `tests/campaign_test.gd`.
- [x] Implémenter la campagne et la migration de la sauvegarde d’origine.
- [x] Relier le château, ses habitants, les dialogues, le journal et les paramètres aux projections de la campagne.
- [x] Vérifier les trajets, les sauvegardes intermédiaires et l’ouverture de la herse dans la scène principale.
- [x] Contrôler une version exportée sur macOS et vérifier sa signature locale.

## Cas de vérification

Dialogue annulé, choix indisponible ou répété, crise ratée avec suite jouable, sauvegarde pendant un transport, ancien joueur déjà couronné, reprise après enquête, alternatives de garde et de galerie, options après retour au château.
