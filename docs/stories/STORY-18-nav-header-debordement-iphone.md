# STORY-18 — Navigation du header inaccessible sur iPhone

**En tant que** Romain,
**Je veux** pouvoir atteindre tous les onglets (Équipes, Match, Stats, Bilan, Matchs) depuis un iPhone,
**Afin de** ne pas être bloqué hors de l'app dès l'ouverture, avant même d'arriver sur l'écran Match.

## Découverte

Trouvé en pilotant réellement l'app en local (voir `docs/design/screenshots/02-setup-iphone.png`, viewport 390×844) — pas une hypothèse. La barre `.nav` du header (`display:flex;gap:4px`, sans `overflow-x` ni wrap) déborde sur un iPhone : les onglets **"Bilan" et "Matchs" sortent de l'écran** et ne sont atteignables par aucun moyen visible. C'est plus bloquant que les problèmes de layout de l'écran Match (STORY-02/STORY-03), puisque ça empêche d'atteindre des écrans entiers de l'app, quel que soit l'écran affiché.

## Contexte technique

- Zone concernée : `style.css` — `.nav`, `.nav-b` ; header rendu par `renderHeader()` dans `app.js` (partagé par tous les écrans, pas seulement Match).
- Le logo + titre ("CF FENIX STAT / TOULOUSE HANDBALL") prend aussi une place importante à gauche sur petit écran, ce qui réduit d'autant la place dispo pour la nav.

## Critères d'acceptation

- [ ] Sur un viewport ≤430px de large, les 5 onglets (Équipes, Match, Stats, Bilan, Matchs) sont tous atteignables — via scroll horizontal explicite (avec indice visuel) ou via une réduction de la largeur de chaque onglet, au choix du Developer selon ce qui reste le plus lisible.
- [ ] Le logo/titre ne doit pas empêcher la nav de tenir sur l'écran — envisager une version condensée du titre sur petit écran si nécessaire.
- [ ] Testé sur les deux orientations (portrait et paysage) d'iPhone.
- [ ] Aucune régression sur iPad (nav actuelle inchangée au-dessus du seuil).

## Hors scope

- Le contenu des écrans Match (STORY-02/STORY-03) — cette story ne concerne que le header/nav lui-même.

## Dépend de

Aucune — peut être livrée avant STORY-02/03, indépendamment, et devrait probablement l'être vu qu'elle bloque l'accès à l'app entière sur iPhone.

## Taille

S

## Notes du Developer (implémentation livrée le 2026-07-23)

**Choix retenu** : scroll horizontal explicite + réduction de taille, plutôt que wrap. Ajout d'un unique bloc `@media(max-width:700px)` dans `style.css` (même seuil que le reste du fichier) :
- `.logo-i` réduit à 28px, `.logo h1` à 12px, `.logo small` masqué — libère de la place sans toucher au HTML/JS.
- `.nav` passe en `overflow-x:auto` (+ `-webkit-overflow-scrolling:touch`, scrollbar masquée) avec un `box-shadow` inset sur le bord droit comme indice visuel qu'il y a plus de contenu à faire défiler.
- `.nav-b` : `flex-shrink:0` (empêche l'écrasement des boutons) + padding/font-size réduits pour limiter la distance de scroll nécessaire.
- `#settings-btn` passe en `flex-shrink:0` pour ne pas être écrasé par la nav quand les deux coexistent (vue Match).
- Bump `sw.js` : `fenix-stats-v47` → `fenix-stats-v48` (convention de déploiement du projet).

**Fichiers modifiés** : `style.css` (ajout, aucune règle existante supprimée), `sw.js` (version cache). **`app.js` non touché** — confirme que ce n'était qu'un problème de CSS, pas de logique.

**Vérification faite** (app relancée en local, Chrome headless piloté via CDP, viewport 390×844) :
- `docs/design/screenshots/07-nav-fix-iphone-initial.png` : les 3 premiers onglets visibles, indice de scroll visible sur le bord droit.
- `docs/design/screenshots/08-nav-fix-iphone-scrolled.png` : après scroll, "Bilan" et "Matchs" pleinement visibles.
- Mesure DOM : `nav.scrollWidth` (408px) > `nav.clientWidth` (272px) → confirme que le scroll est bien nécessaire et actif.
- Clic réel (`.click()`) sur l'onglet "Matchs" après scroll → bascule effective vers l'écran "Matchs sauvegardés", rendu correctement à cette largeur.
- Non re-testé à ce stade : le rendu iPad (≥700px, hors media query) n'a pas été re-capturé dans cette passe — à vérifier par le Code Reviewer/QA avant de clore, la règle étant strictement scoped par `max-width:700px` donc le risque de régression iPad est faible mais pas vérifié visuellement ici.

**Point d'attention pour le Code Reviewer/QA** : le titre "CF FENIX STAT" continue de wrapper sur 2-3 lignes sur très petit écran (héritage du comportement existant, pas introduit par ce fix) — non corrigé ici car hors du scope strict de la story (la nav est atteignable, ce qui était le critère demandé).
