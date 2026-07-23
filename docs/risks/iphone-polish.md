# Risques — iPhone + polish visuel

*Produit par le Risk Analyst — squad build BMAD*
*S'appuie sur `docs/architecture.md`*

## Tableau des risques

| # | Risque | Probabilité | Impact | Recommandation |
|---|---|---|---|---|
| 1 | **Aucune sauvegarde continue du match en cours** — `S.events` ne vit qu'en mémoire JS jusqu'à `saveMatch()` en fin de match (confirmé en lisant `app.js` : rien n'écrit l'état courant en localStorage/IndexedDB pendant la saisie). Un reload accidentel (Safari iOS qui décharge un onglet en arrière-plan sous pression mémoire, batterie faible, fermeture accidentelle) fait perdre **l'intégralité** du match en cours. | Moyenne | Critique | Ajouter un autosave périodique (ou à chaque événement) de l'état du match en cours vers localStorage/IndexedDB, avec détection au chargement d'un "match en cours" à proposer de restaurer. Ce risque existe **indépendamment** du travail iPhone/polish — c'est le risque le plus important trouvé dans cet audit. |
| 2 | **Régression du layout iPad** en touchant `.match-layout` pour absorber le cas iPhone — c'est l'écran le plus critique de l'app (saisie en direct pendant un match officiel de N1). **Mise à jour du 2026-07-23** : le test réel en local confirme que ce n'est pas qu'un risque théorique — le format iPhone est déjà cassé aujourd'hui (chevauchement de boutons en portrait, recouvrement terrain/barre du bas en paysage, nav header inaccessible), voir `docs/design/screenshots/` et STORY-02/STORY-03/STORY-18. | Moyenne | Critique | Aucune story F1 ne doit être considérée "terminée" sans un test explicite sur iPad **et** iPhone avant livraison. À inscrire comme critère d'acceptation transverse, pas seulement une bonne pratique. |
| 3 | **Purge du stockage navigateur iOS** sans export préalable — Safari peut libérer l'espace de stockage d'un site si l'app n'est pas installée à l'écran d'accueil ou si l'espace disque est faible, effaçant les matchs déjà sauvegardés en IndexedDB. | Faible à Moyenne | Critique | F3 (filet de sécurité data) ne devrait pas rester "Should Have" — proposer au PM de le remonter en Must Have, ou a minima de proposer l'export juste après chaque match sauvegardé plutôt qu'un bandeau passif dans Bilan uniquement. |
| 4 | **Bascule d'appareil en cours de match** (ex : Romain commence sur iPad, bascule sur iPhone si batterie faible) — aucune synchronisation entre appareils, chaque device a son propre stockage local. | Faible | Critique si ça arrive | Hors scope de correction (pas de sync prévue — décision produit assumée), mais **doit être communiqué clairement à Romain** pour qu'il ne soit pas surpris en plein match. Recommandation : message explicite quelque part dans l'app (ex : écran d'accueil) rappelant qu'un match se joue sur un seul appareil du début à la fin. |
| 5 | **Bouton d'action masqué par le scroll horizontal** sur petit écran (ex : TM ou Carton Rouge qui sortent du cadre visible) → décision manquée en plein direct. | Moyenne | Moyen | Ajouter un indice visuel de scroll (fondu de bord) et garantir que BUT/TIR (actions les plus fréquentes) restent toujours visibles sans scroll, quel que soit l'ordre des boutons. |
| 6 | **Lisibilité en plein soleil** — l'usage se fait en extérieur, en bord de terrain ; le thème dark actuel utilise des textes secondaires à faible contraste (`--t3` ~3.3:1) qui peuvent devenir illisibles sous forte luminosité ambiante, un problème que l'écran d'un iPhone (plus petit, souvent tenu plus près du corps) rend encore plus sensible que sur iPad. | Moyenne | Faible à Moyen | Ne pas étendre l'usage de `--t3` à des informations utiles en direct (déjà une bonne pratique actuelle à documenter/renforcer) ; envisager de tester la lisibilité en extérieur en plein jour avant de considérer F2 "terminé". |

## Classement

- **P0 (à traiter avant tout dev de F1/F2)** : #1 (autosave match en cours) — c'est un risque de perte de données totale qui touche exactement le même code (`app.js`, gestion du rendu match) que celui qui va être modifié pour F1. Le corriger en même temps évite de rouvrir cette zone de code deux fois.
- **P1 (critère d'acceptation obligatoire, pas bloquant pour démarrer)** : #2 (gate de test iPad+iPhone), #3 (reclassement F3 à discuter avec le PM), #4 (documentation de la limite multi-appareils).
- **P2 (à garder à l'œil, non bloquant)** : #5 (scroll actions), #6 (contraste plein soleil).

## Stories de mitigation recommandées

- **#1 → nouvelle story dédiée** (à ajouter par le Scrum Master, hors F1 initial mais dans le même cycle) : "Autosave du match en cours" — priorité haute vu l'impact, indépendante de l'ordre F1/F2.
- **#2 → critère d'acceptation ajouté à chaque story F1**, pas une story séparée.
- **#3 → question à retrancher au PM** avant le découpage en stories : F3 doit-il monter en Must Have ?
- **#4 → critère d'acceptation léger** (un message dans l'UI), rattachable à F5 ou une story à part très petite (taille S).
- **#5 et #6 → critères d'acceptation** dans les stories F1/F2 concernées, pas des stories séparées.
