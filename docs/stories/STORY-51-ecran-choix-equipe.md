# STORY-51 — Écran de choix d'équipe (deux encarts -18 / CF)

**En tant que** Romain,
**Je veux** un écran d'accueil avec deux grandes cartes "-18" et "CF" au premier lancement de l'appli sur un appareil,
**Afin de** choisir simplement quelle équipe cet appareil va servir, avant d'entrer dans l'appli.

Dépend de STORY-50 (fondation — `S.teamProfile`, `chooseTeamProfile()`, point d'insertion dans le rendu déjà spécifiés). Romain a fourni son visuel de référence (`fenix-stat-badge.png`, badge "FENIX STAT" — croix occitane, Capitole, terrain, "WE ARE TOULOUSE") pendant le développement — design finalisé sur cette base, plus provisoire.

## Contexte technique
`renderTeamPicker()` créée, branchée au point déjà identifié par l'Architecture de STORY-50 (`if(S.authOk && !S.teamProfile){ ...renderTeamPicker()... }`). Fonction `chooseTeamProfile(profile)` déjà spécifiée par STORY-50. Séquence en 2 temps : le badge (`fenix-stat-badge.png`, ajouté aux assets du service worker pour le hors-ligne) entre depuis un coin, tient au centre, ressort vers le coin opposé et disparaît (`@keyframes team-badge-seq`, 2.4s) ; les deux cartes se révèlent ensuite (`@keyframes team-cards-in`, démarre à 2s), non cliquables tant que la séquence n'est pas achevée (`pointer-events` verrouillé côté CSS jusqu'à la fin de l'animation).

## Critères d'acceptation
- [x] Badge FENIX STAT anime depuis un coin, tient, ressort vers le coin opposé, disparaît — puis deux cartes cliquables "-18" et "CF" en grand (`clamp(48px, 12vw, 96px)`) se révèlent
- [x] Tap sur une carte → `chooseTeamProfile("u18"|"cf")` → écran disparaît, effectif du profil chargé, app normale affichée — vérifié par clic réel **après la fin de la séquence d'animation**, `pointer-events` bien passé à `auto`
- [x] Aucun bouton retour/annuler sur cet écran (choix structurant, pas une action réversible d'un clic)
- [x] N'apparaît **jamais** si `S.teamProfile` est déjà défini — vérifié par vrai rechargement complet de page
- [x] Réapparaît correctement après un changement d'équipe volontaire depuis les réglages (STORY-50, `switchTeamProfile()`)
- [ ] Fonctionne sur iPad (portrait/paysage) et iPhone réels — vérifié en résolution CDP simulée (1024×768 desktop), **pas encore confirmé sur un vrai appareil tactile** par Romain

## Cas limites testés
- Premier lancement absolu (aucun `localStorage` du tout) : écran s'affiche correctement, aucune erreur si `hb2_teams`/`hb2_team_profile` sont totalement absents
- Cartes non cliquables tant que la séquence d'animation n'est pas achevée (`pointer-events:none` jusqu'à la fin de `team-cards-in`), clic réel confirmé fonctionnel une fois la séquence terminée
- `prefers-reduced-motion:reduce` : bascule sur un affichage statique (badge en haut, cartes immédiatement visibles), sans la séquence animée

## Hors scope
Toute la logique de scoping des données (déjà couverte par STORY-50) — cette story est purement le rendu et l'interaction de l'écran lui-même.

## Dépend de
STORY-50.

## Taille
S — un nouvel écran de rendu + binding, aucune nouvelle logique de données.

## Note
**Révisée après retour direct de Romain sur le 1er rendu** : badge doublé de taille (`min(82vw,560px)`), animation remplacée (trajet coin-à-coin jugé faible → "pop" central avec rebond élastique + mise au point flou/net, `@keyframes team-badge-pop`). Un bug de mise en page (cartes poussées hors écran par un changement de `position` sur le badge) trouvé et corrigé dans la foulée, cf. `docs/code-review/STORY-48-50-51.md` addendum 2.

Poids de `fenix-stat-badge.png` (~2,2 Mo) non optimisé — mis en cache par le service worker dès le premier chargement (coût une seule fois), à compresser si Romain le juge utile.

**Ajouts hors périmètre initial, ajoutés sur retour direct de Romain** :
- Logo du header cliquable (`#home-logo-btn`) — retour rapide à l'écran de choix d'équipe, réutilise `switchTeamProfile()`
- `chooseTeamProfile()` n'appelle plus `checkForResumableMatch()` — le clic sur -18/CF n'est plus jamais interrompu par une proposition de reprise de match
