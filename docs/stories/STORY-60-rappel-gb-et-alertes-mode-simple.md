# STORY-60 — Rappel GB fiable + alertes TM/changez de GB en Mode Simple

**En tant que** Romain,
**Je veux** un vrai rappel si je n'ai pas choisi mon gardien, et retrouver les alertes "TM conseillé"/"changez de GB" quel que soit le mode,
**Afin de** ne pas découvrir en plein match qu'une info manquait ou qu'une alerte ne s'est jamais déclenchée.

Deux demandes dans le même message : "Mets un message de rappel sur n'oublie pas de choisir ton GB" (sur l'écran de lancement, STORY-54) + "Est-ce que les messages qu'on avait faits sur prend temps mort, change de GB [...] sont toujours présents ?"

## 1. Rappel GB — root cause trouvée, pas juste "à ajouter"
Le rappel existait déjà (`launchWarnings()`, STORY-53) mais ne se déclenchait quasiment plus jamais côté FENIX CF : `defaultFenixCfTeam()` (STORY-56) pré-assignait `gkId` au premier gardien de la liste **dès le chargement**, avant même qu'aucun joueur ne soit sélectionné pour le match. `launchWarnings()` ne vérifiait que `!S.home.gkId` (non-null), jamais si ce gardien était réellement retenu pour le match — le rappel restait donc toujours "silencieux" avec une référence fantôme.

**3 corrections coordonnées :**
1. `defaultFenixCfTeam()` : `gkId` laissé à `null` au chargement (aucun joueur n'est encore sélectionné à ce stade, le pré-remplir était une donnée fausse dès le départ).
2. `launchWarnings()` : nouvelle fonction `hasValidGk(side)` — vérifie que `gkId` est non-null **ET** que ce joueur est bien `selected:true` actuellement, pas seulement que le champ n'est pas vide.
3. `[data-sel-player]` (toggle de sélection) : désélectionner le joueur actuellement assigné comme GB réinitialise `gkId` à `null` — évite qu'un gardien retiré du match reste silencieusement crédité des arrêts/buts encaissés pendant la partie (pas seulement un problème d'affichage du rappel, une question d'intégrité des stats GB en jeu).

## 2. Alertes TM conseillé / changez de GB — toujours présentes, mais Mode Simple seulement
`checkTimeoutAdvisor()`/`checkGkConsecutiveAlert()` existent intactes et fonctionnent en Mode Expert (`validateAndClose()`, `validateActionPanel()`, `recordTM()`) — **mais n'avaient jamais été branchées dans `recordEvent()`** (Mode Simple), un gap de parité du même type que celui déjà trouvé pour la possession auto-switch (STORY-52/M3). Ajoutées à `recordEvent()`.

## Vérifié par CDP
- Profil CF neuf, aucune sélection : rappel GB affiché sur l'écran de lancement (capture d'écran).
- Joueurs sélectionnés (dont un GB) mais GB pas explicitement choisi via le sélecteur : rappel toujours affiché.
- GB explicitement choisi : rappel disparaît.
- Ce même GB désélectionné via un vrai clic : `gkId` repasse à `null`, rappel réapparaît.
- Mode Simple, 5 buts adverses consécutifs contre le même GB : toast "🚨 5 buts encaissés de suite ! Changez de GB !" déclenché (capture d'écran) — ne se déclenchait jamais avant ce correctif.

## Taille
S — 3 points coordonnés pour le rappel GB (même risque de cohérence qu'un mini-STORY-53), + 1 ligne pour le branchement Mode Simple des alertes.
