# QA — STORY-55 à STORY-61 (rosters par défaut, tag terrain PB/Jet franc, possession, rappels)

## Ce que j'ai lu avant de tester
`docs/code-review/STORY-55-61.md` (APPROUVÉ), les 7 fichiers `docs/stories/STORY-55-*.md` à `STORY-61-*.md`, `docs/regression/checklist.md` (entrées déjà posées lors du développement initial de chaque story).

## Méthode
Infrastructure de test relancée (serveur statique + Chrome headless étaient tombés entre les sessions). CDP avec **vrais clics/taps** (`Input.dispatchMouseEvent`), pas de simulation d'état pure sur les interactions critiques. Différence volontaire avec la vérification faite au moment du développement de chacune de ces 7 stories : ici, un **seul scénario continu** enchaîne les 7 stories dans l'ordre où elles s'utiliseraient réellement (profil neuf → sélection → lancement → saisie Expert → bascule Simple → boutons manuels → retour Équipes), pour vérifier les interactions entre elles, pas seulement chaque story isolée.

## Critères d'acceptation vérifiés (scénario continu, 14 assertions)

**STORY-56 + STORY-54 + STORY-60** (profil CF neuf)
- [x] 22 joueurs FENIX CF chargés automatiquement, non sélectionnés, `gkId:null`
- [x] Écran de lancement dédié affiché (aucun match actif)
- [x] Rappel GB présent tant qu'aucun gardien n'est choisi parmi les joueurs sélectionnés
- [x] Rappel GB disparaît dès qu'un gardien réellement sélectionné est assigné

**STORY-54/M1 + STORY-58** (lancement + Mode Expert)
- [x] Clic sur "Lancer le match" démarre le chrono et bascule sur l'interface complète
- [x] PB : tap joueur → panneau reste ouvert avec surface de tag terrain (pas de validation instantanée)
- [x] PB enregistré avec `x`/`y` réels après le tap sur le terrain (jamais `null`)
- [x] Possession bascule après le PB (règle préexistante, non régressée par les changements de ce cycle)

**STORY-59 + STORY-60** (Mode Simple)
- [x] Bouton de l'équipe sans possession visuellement grisé (`.simple-inactive`)
- [x] Clic sur ce bouton grisé bloqué : **aucun événement ajouté**
- [x] 5 buts adverses consécutifs → alerte "🚨 Changez de GB !" déclenchée en Mode Simple (confirme le branchement STORY-60, absent avant ce cycle)

**STORY-61** (boutons manuels)
- [x] "⚡ FENIX CF" recharge les 22 joueurs officiels (vérifié après un renommage manuel préalable, pour confirmer que ça écrase bien l'état modifié)
- [x] "⚡ Modèle" (Adversaire) recharge les 7 postes **sans toucher le nom d'équipe** déjà saisi ("Ivry" préservé)

**STORY-57** (scroll)
- [x] **Premier essai invalidé par moi-même** : testé initialement dans le même viewport que le reste du scénario (820×1180, portrait) — `#app` n'y est pas le vrai conteneur de scroll (seulement en paysage ≥700px), le test passait donc pour la mauvaise raison (0≈0, aucun scroll réel exercé). Refait isolément en paysage 1024×700 (layout confirmé : `body{overflow:hidden}`, `#app{overflow-y:auto}`) : scrollé à 1108px, reste à 1108px après clic sur le dernier joueur — fix confirmé toujours valide combiné au reste du code de ce cycle.

## Vérification visuelle
Capture d'écran du scénario Mode Expert : surbrillance de possession (STORY-58) nettement visible sur la carte équipe ET la bordure du terrain, boutons PB/Jet franc/PO bien présents dans la barre d'actions, badge "🎯 PD" déjà géré correctement à côté. Rendu cohérent, aucun chevauchement ni régression visuelle détectée en combinant tous les changements du cycle.

## Bugs trouvés
Aucun dans le code livré. Un bug trouvé **dans mon propre scénario de test** (viewport portrait utilisé par erreur pour la vérification du scroll) — corrigé avant de valider, pas un problème du produit.

## Régressions détectées
Aucune — les 7 stories fonctionnent correctement ensemble, pas seulement isolément. Le point du Code Review (boutons STORY-61 n'appelant pas `upsertMatchSnapshot()`) n'a pas d'impact fonctionnel testable en local (dépend d'une synchronisation Supabase multi-appareil réelle) — déjà noté comme non-bloquant, pas re-testé ici pour cette raison.

## Verdict
**PASSED**
