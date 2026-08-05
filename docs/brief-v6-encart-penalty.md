# Brief — Encart Pénalty sur le terrain

## Contexte
Romain (responsable du centre de formation, utilisateur unique de la saisie) a formulé une gêne directement sous forme de solution : « Sur PO on se met en mode pénalty. Je préférerais un gros encart sur le terrain (une fois qu'on a sélectionné celui qui a créé le PO). Dans cet encart on a but/arrêt/hors cadre comme bouton à choisir et l'impact si on est en mode GB. »

Ce sujet arrive dans la continuité directe de deux corrections toutes fraîches (STORY-31, le jour même) sur ce même coin du code : la zone de but qui ne doit plus être demandée pour un tir non cadré, et une légende clarifiant le ratio affiché dans la heatmap de zones. Romain est donc en ce moment même en train d'affiner à l'usage réel le comportement du mode pénalty — ce Brief n'ouvre pas un chantier isolé, il poursuit un fil qu'il a déjà commencé à tirer aujourd'hui.

Contrairement au chantier Stats Gardiens (brief-v5, terminé/déployé — cf. STORY-30 "feuille gardien fusionnée" citée dans STORY-31), qui concernait la **lecture** a posteriori, ce sujet concerne la **saisie en direct pendant le match** — le geste le plus sensible au temps et à l'attention de toute l'app, puisqu'un penalty se tire en quelques secondes et que Romain doit garder les yeux sur le terrain, pas sur l'interface.

## Problème

Ce que Romain ne peut pas faire aujourd'hui : **enregistrer l'issue d'un penalty sans quitter des yeux le terrain**, et — découverte plus grave en creusant le code — **l'impact dans le but n'est actuellement jamais enregistré pour un penalty, même quand le suivi GB est actif.**

Déroulé actuel constaté dans le code (`app.js`) :
1. Romain sélectionne l'action **PO** dans la barre d'actions horizontale (`.ml-actions`, en haut de la colonne droite, au-dessus du terrain).
2. Il clique le joueur qui a obtenu le penalty sur le terrain (`clickActionPlayer()`, ligne ~659-686). Ce clic valide **immédiatement** l'événement PEN_OBT (`validateAndClose()`) et active `S.penMode=true`.
3. Le terrain revient alors en mode "sélection neutre" : `S.selectedAction` est redevenu `null`, donc un clic sur un joueur à cet instant ne fait rien (`clickActionPlayer` sort immédiatement si `!S.selectedAction`, ligne 663). Romain est donc obligé de **remonter le regard vers la barre d'actions tout en haut** et cliquer BUT, TIR ARRÊTÉ ou TIR NON CADRÉ, comme s'il commençait une action normale.
4. Il reclique un joueur sur le terrain — pas nécessairement le même qu'à l'étape 2 (le tireur du penalty n'est pas toujours celui qui a obtenu la faute). Ce clic est intercepté par la branche `S.penMode` (lignes 671-679) : le type est converti en PEN_GOAL/PEN_SAVE/PEN_OFF, la position est fixée à `mapX:50, mapY:85` (pas un vrai clic terrain, cohérent avec le fait qu'un tir de pénalty part toujours du même endroit), et **`validateAndClose()` est appelé sur-le-champ**.
5. Un badge « 🎯 MODE PENALTY » s'affiche dans `.ml-status` pendant toute la durée de `S.penMode` — mais c'est un simple `<span>`, sans handler de clic : il informe, il ne raccourcit rien.

**Découverte en creusant le point 4** : parce que `validateAndClose()` est appelé de façon synchrone dans la branche `S.penMode` (ligne 676), l'événement PEN_GOAL/PEN_SAVE/PEN_OFF est écrit et le panneau d'action est fermé (`S.actionPanel=null`) **avant** que `renderMatchPanel()` ait la moindre chance d'afficher l'overlay de sélection de zone de but (le "mode tir" / `shotMode`, lignes 1640-1659, celui qui affiche normalement la grille 3×3 après un BUT ou un TIR ARRÊTÉ). Autrement dit : **le sélecteur de zone d'impact dans le but n'apparaît jamais pour un penalty**, que `S.trackGK` soit activé ou non. Ce n'est pas une supposition — la story STORY-31, livrée le jour même, le confirme noir sur blanc : « But et Tir arrêté (et leurs variantes pénalty, **qui bypassaient déjà tout le workflow terrain/zone**) ». Romain demande explicitement « l'impact si on est en mode GB » dans son encart — ce qui suggère qu'il souhaite cet impact désormais capturé, alors que le code actuel ne le permet techniquement pas du tout, indépendamment du nombre de clics.

Le vrai besoin n'est donc pas seulement « réduire les allers-retours » — c'est double :
- **Réduire la rupture d'attention** : pendant un penalty, tout se joue en quelques secondes ; obliger Romain à quitter le terrain des yeux pour remonter vers la barre d'actions, au moment précis où l'attention devrait rester sur le tir, est le pire moment de l'app pour demander ce détour.
- **Combler un vide fonctionnel** : le suivi GB (zones d'impact dans le but), déjà en place pour les tirs normaux et présenté comme une donnée utile ailleurs dans l'app (heatmap, stats gardien), n'existe tout simplement pas pour les penaltys aujourd'hui.

Le pire résultat si mal fait : un bel encart visuel qui résout le problème d'attention mais qui, câblé sur le même court-circuit `validateAndClose()` immédiat, continue de ne jamais capturer la zone d'impact — ou un encart qui capture la zone mais introduit une incohérence de données (ex : deux joueurs différents enregistrés sur deux événements liés PEN_OBT/PEN_GOAL sans que ce soit visible dans l'encart).

## Utilisateurs
Un seul utilisateur : **Romain**, en saisie live, en bord de terrain, sur iPad, en mode Expert uniquement (le mode Simple n'a ni PO ni PEN détaillé — cf. `CLAUDE.md` : « Pas de PD, pas de PO/PEN détaillé » en mode Simple, donc ce sujet ne concerne que `renderMatchPanel()`/`renderMatchSimple()` n'est pas impacté).

Contexte d'usage précis : Romain suit le match en direct, débout ou en mouvement, pendant que l'action continue sur le terrain. Un penalty est un moment court et à forte charge (faute sifflée → tir → issue en quelques secondes) — c'est probablement le geste de saisie le plus sensible au temps de toute l'app, plus encore que la saisie d'un tir normal (où l'attention peut se permettre un aller-retour, le jeu continuant de toute façon). Pas d'aidant occasionnel concerné ici (contrairement au constat du brief-v5) : c'est toujours Romain seul qui saisit pendant le match.

## Vision
Permettre à Romain d'enregistrer l'issue d'un penalty — et sa zone d'impact dans le but quand le suivi GB est actif — sans quitter le terrain des yeux ni remonter vers la barre d'actions, dans la continuité du geste qui vient de désigner le joueur ayant obtenu le penalty.

## Scope

**Dedans (a priori, à confirmer par le PM) :**
- Remplacement du retour obligatoire vers `.ml-actions` par un encart affiché directement sur/au-dessus du terrain, apparaissant juste après l'obtention du PO, proposant BUT / TIR ARRÊTÉ / TIR NON CADRÉ.
- Câblage de cet encart pour qu'il propose ensuite le sélecteur de zone d'impact (grille 3×3) quand `S.trackGK` est actif et que le choix est BUT ou TIR ARRÊTÉ (jamais pour TIR NON CADRÉ, cohérent avec STORY-31) — ce qui comble le vide fonctionnel identifié ci-dessus, pas seulement un habillage visuel.
- Réutilisation probable du mécanisme d'overlay déjà existant (`shotMode` dans `renderMatchPanel()`, lignes 1640-1659) qui affiche déjà "un gros encart sur le terrain" pour les tirs normaux — la brique technique existe, il s'agit de l'adapter au cas pénalty (position fixe, donc pas d'étape de clic sur le terrain avant la zone de but). Point à confirmer par l'Architect, pas une décision de ce Brief.
- Réexamen du badge « 🎯 MODE PENALTY » : redondant si l'encart apparaît directement, à absorber ou conserver selon ce que décide le Designer.

**Dehors (a priori) :**
- Le mode Simple (pas de PO/PEN dans ce mode).
- Le workflow des tirs normaux hors pénalty (inchangé).
- Toute nouvelle donnée/calcul de stats gardien (`gkStats()` etc.) au-delà de rendre possible ce qui devrait déjà l'être (capturer `goalZone` pour les penaltys) — pas de nouvelle métrique.
- Rattrapage des penaltys déjà enregistrés sans zone d'impact dans les matchs passés (aucune zone n'a jamais été capturée pour eux ; pas de backfill prévu sauf décision explicite contraire).

## Critères de succès
- Romain enregistre un penalty du début à la fin (obtention → résultat → impact si GB actif) sans que son regard/doigt ait besoin de quitter la zone du terrain pour remonter vers la barre d'actions du haut.
- La zone d'impact dans le but est bien enregistrée pour un PEN_GOAL ou un PEN_SAVE quand `S.trackGK` est actif — ce qui n'est le cas pour aucun penalty aujourd'hui.
- Le nombre d'allers-retours visuels entre terrain et barre d'actions diminue par rapport au comportement actuel (aujourd'hui : 1 aller-retour complet obligatoire).
- Aucune régression sur le workflow normal (non-pénalty) de BUT/TIR ARRÊTÉ/TIR NON CADRÉ, ni sur le comportement correctif de STORY-31 (pas de zone de but demandée pour un tir non cadré).
- Romain confirme, en conditions réelles de match, que l'enchaînement est plus rapide et plus confortable qu'aujourd'hui.

## Questions en suspens

- **Le tireur du penalty est-il toujours le même joueur que celui qui l'a obtenu ?** La phrase de Romain (« une fois qu'on a sélectionné celui qui a créé le PO ») suggère qu'un seul clic joueur suffirait désormais, l'encart apparaissant directement après — ce qui reviendrait à supposer que le tireur est le même joueur que celui qui a obtenu la faute. Or dans la réalité du handball ce n'est pas systématique. Le PM doit trancher : (a) un seul clic joueur, le même sert pour PEN_OBT et PEN_GOAL/SAVE/OFF ; (b) l'encart permet quand même de désigner un tireur différent sans quitter le terrain (par exemple en gardant le terrain cliquable derrière/à côté de l'encart) ; (c) on accepte un compromis explicite documenté.
- **Que devient le badge « 🎯 MODE PENALTY » ?** Redondant si l'encart s'affiche directement à la place, mais pourrait rester comme rappel textuel discret pendant que l'encart est ouvert. À trancher par le Designer.
- **Comportement quand `S.trackGK` est désactivé** : l'encart doit-il valider directement après BUT/ARRÊT/HORS CADRE (comme le fait déjà `showGZ` pour les tirs normaux quand le suivi GB est coupé), sans jamais montrer la grille de zone ? Probablement oui par cohérence, à confirmer.
- **Sortie du mode pénalty sans supprimer l'événement** : aujourd'hui, la seule façon de sortir de `S.penMode` sans aller au bout est d'annuler (`undoLast()`) le PEN_OBT tout juste enregistré, ce qui supprime l'événement. Faut-il une sortie explicite de l'encart (ex. si une vidéo/arbitre invalide le penalty après coup, ou en cas de mauvaise manipulation) qui laisse le PEN_OBT enregistré mais referme juste l'encart ? À clarifier avec le PM.
- **La zone d'impact des penaltys, une fois capturée, doit-elle apparaître dans les stats/heatmaps existantes** (feuille gardien fusionnée STORY-30, `goalZoneHeatmap()`) au même titre que les tirs normaux, ou séparément ? Cette question dépasse ce Brief (c'est une question de présentation, pas de saisie) mais elle doit être signalée au PM/Designer puisque la donnée n'existant pas aujourd'hui, son apparition soudaine dans les stats mérite une décision explicite plutôt qu'un effet de bord silencieux.
- **Hypothèse technique à vérifier par l'Architect** : le mécanisme d'overlay déjà utilisé pour les tirs normaux (`shotMode`/`renderMatchPanel()` lignes 1640-1659) est-il directement réutilisable pour ce nouvel encart pénalty (même composant, juste sans l'étape de clic de position puisqu'elle est fixe), ou faut-il un composant dédié ? Ce Brief ne tranche pas l'implémentation, mais il est utile de noter que la brique visuelle "gros encart sur le terrain" que demande Romain existe déjà ailleurs dans le code pour un cas voisin.
