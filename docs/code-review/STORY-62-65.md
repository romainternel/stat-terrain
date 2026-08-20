# Code Review — STORY-62 à STORY-65 (corrections Audit Final + Mode Simple à équipe unique)

## Portée revue
Diff complet du commit `85a3ecb` (`app.js` +121/-65 lignes réparties, `style.css` -3, `sw.js` v109→v110). Comparé systématiquement aux décisions actées dans `docs/arch/audit-corrections-et-mode-simple.md` et aux critères d'acceptation des 4 stories.

## Développeur
Code déjà implémenté et déployé (poussé sur `main`, service worker en v110, vérifié en navigateur réel contre le vrai Supabase de production par le Developer lui-même avant ce passage). Cette revue porte sur le code tel que livré.

## Conformité et cohérence

**STORY-62 (sauvegarde idempotente)** — `S.savedMatchId` correctement propagé aux 3 points prévus par l'architecture : lu dans `saveMatch()` (`match.id=S.savedMatchId||Date.now()`), écrit après succès (`S.savedMatchId=match.id`), réinitialisé à `null` dans `newMatch()`, fixé à `m.id` dans `loadMatchAsCurrent()`. `dbSaveMatch()` fait bien un `put()` sur un store `keyPath:"id"` (vérifié, non modifié par cette story) — la stratégie "réutiliser le même id = upsert" est correcte et ne nécessite aucune migration de schéma. Le reset dans `newMatch()` intervient bien **après** le `safeConfirm()` — annuler la confirmation laisse `S.savedMatchId` intact (critère d'acceptation R2 du Risk Analyst respecté par construction, pas seulement par accident).

**STORY-63 (historique des alertes)** — Centralisation dans `showToast()` conforme à la décision d'architecture (un seul point de modification plutôt que chaque site d'appel individuel). Vérifié par recherche exhaustive : aucun autre point d'écriture de `S.alertHistory` n'existe, aucun risque d'oubli futur. `newMatch()` **et** `loadMatchAsCurrent()` réinitialisent bien `S.alertHistory`/`alertHistoryCollapsed`/`alertHistoryDismissed` (couvre le risque R3 identifié par le Risk Analyst — le match archivé chargé n'hérite jamais de l'historique du précédent). Le bandeau et la pastille réutilisent à l'identique les classes CSS déjà établies (`launch-warning-banner`, `lwb-btn`, `launch-warning-dot`) — aucune duplication de style.

**STORY-64 (garde-fou Analyse)** — `MIN_EVENTS_FOR_INSIGHTS` appliqué de façon strictement symétrique aux deux jumeaux `autoAnalysis()`/`matchAnalysis()`, avec le même calcul `hTotal+aTotal` (tirs cumulés des deux équipes, pas seulement l'équipe FENIX) — cohérent avec l'intention documentée. Résultat et efficacité brute jamais gatés, conforme au PRD. Point noté sans être bloquant : le calcul des blocs de 10 minutes (`blocks.forEach(...)`) continue de s'exécuter même quand `enoughData` est faux — seul l'insight qui en découle est masqué, pas le calcul lui-même. Aucun impact fonctionnel (le calcul est bon marché, pas de re-render supplémentaire), simple travail inutile négligeable — pas la peine d'y toucher.

**STORY-65 (Mode Simple à équipe unique)** — `renderMatchSimple()` n'émet plus qu'un bloc, réutilise bien `.ml-actions`/`.act-h` (classe partagée avec la barre Mode Expert, confirmé par lecture du CSS — aucune nouvelle règle de disposition ajoutée). `data-simple` simplifié en `type` seul ; recherche exhaustive confirmée : aucun autre point du code ne dépendait de l'ancien format `team|type`. Le garde `team!==S.possession` (STORY-59) est bien retiré du binding, cohérent avec le fait qu'il est devenu structurellement inatteignable (un seul bloc de boutons existe désormais). La classe CSS `.act-h.simple-inactive` associée est supprimée proprement dans `style.css`, sans laisser de règle orpheline. Le nom d'équipe reste sur sa propre ligne au-dessus de `.ml-actions`, conforme à l'exigence explicite de Romain.

## Finding — Note (non bloquant, aucune action requise)
Le texte de confirmation de `loadMatchAsCurrent()` ("Le match en cours sera remplacé") ne mentionne pas explicitement que resauvegarder ce match repris mettra désormais à jour l'entrée archivée plutôt que d'en créer une nouvelle (nouveau comportement introduit par STORY-62). Ce n'est pas trompeur — juste une clarification qui pourrait être ajoutée un jour si un coach s'interroge sur le sujet. Pas la peine d'y toucher maintenant, le comportement lui-même est correct et c'est celui explicitement voulu par l'architecture.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- Calcul des blocs de 10 minutes non court-circuité par `enoughData` dans `autoAnalysis()`/`matchAnalysis()` (voir ci-dessus) — travail négligeable, aucune action requise.
- Texte de confirmation `loadMatchAsCurrent()` pourrait à terme mentionner le nouveau comportement de sauvegarde idempotente — amélioration future possible, pas un défaut.

## Verdict
**APPROUVÉ**
