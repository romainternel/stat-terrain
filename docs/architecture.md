# Architecture — iPhone + polish visuel

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd.md` et `docs/design/`*

## Décision technique globale

Tout se fait **en CSS + JS existant, sans nouvelle dépendance, sans changement de stack**. Le projet reste 3 fichiers (`index.html`, `style.css`, `app.js`) + `sw.js`/`manifest.json`, conformément au CLAUDE.md. Aucune des features F1–F5 ne justifie d'introduire un framework, un bundler, ou un découpage en modules JS séparés — l'app.js reste un seul fichier (~3700 lignes, en dessous du seuil qui justifierait un découpage, cf. critère de bascule plus bas).

## F1 — Responsive iPhone

**Comment on implémente :**
- Ajout d'une media query dédiée sur `.match-layout` pour `max-width:700px` (le seuil existe déjà ailleurs dans `style.css` pour `.setup-grid`/`.stat-courts` — on reste cohérent avec ce même seuil plutôt que d'en inventer un nouveau).
- Bascule `grid-template-columns:240px 1fr` → `1fr` (empilement vertical) en dessous de ce seuil, avec réordonnancement via `order` CSS (grid/flex) plutôt que de dupliquer le HTML : `.ml-left` passe en flux compact (score + timer + contrôles), `.ml-right` garde la priorité d'espace vertical pour le terrain.
- La barre d'actions (`.ml-actions`) reçoit `overflow-x:auto;flex-wrap:nowrap` sous le même breakpoint, au lieu de wrapper — évite de manger la hauteur disponible pour le terrain.
- **Aucun changement JS nécessaire** : le rendu (`R()`, `renderMatchPanel()`, etc.) ne connaît pas la taille d'écran, tout est piloté par CSS/media queries — cohérent avec la philosophie actuelle (pas de logique responsive en JS dans le projet).

**Pourquoi cette approche plutôt qu'une autre :**
- Alternative rejetée : dupliquer un `renderMatchMobile()` en JS. Rejeté car ça double la surface de maintenance (deux rendus à synchroniser à chaque évolution du workflow de saisie) alors que le problème est purement une question de disposition, pas de logique.
- Alternative rejetée : librairie CSS de grid responsive. Rejeté car inutile — une media query suffit, et ça introduirait une dépendance externe sur un projet volontairement 100% vanilla.

**Impact sur l'existant :**
- Le layout iPad actuel n'est pas touché (la media query ne s'applique qu'en dessous de 700px) — zéro régression attendue sur iPad.
- `.act-h` (boutons d'action) doit perdre son `flex-wrap` implicite au profit d'un scroll horizontal sous le breakpoint mobile — vérifier que ça ne casse pas le rendu iPad en mode portrait étroit (rare, iPad fait ≥768px en portrait donc hors seuil).

## F2 — Polish visuel

**Comment on implémente :**
- Ajout des tokens d'ombre (`--shadow-card`, `--shadow-card-hover`, `--shadow-accent`) dans `:root` de `style.css`, réutilisés sur les cartes Stats/Bilan/Setup qui n'en ont pas aujourd'hui.
- Généralisation des classes d'état déjà existantes (`:active` scale, focus visible) — pur CSS, aucune structure de données ni fonction JS à créer.

**Impact sur l'existant :** aucun — additif uniquement (nouvelles règles CSS, pas de suppression de comportement).

## F3 — Filet de sécurité data

**Comment on implémente :**
- Nouveau petit état non persistant en mémoire (`S.lastExportAt` ou variable locale au rendu du Bilan) pour afficher "à l'instant" après un export réussi dans la session en cours.
- Si on veut persister au-delà d'un rafraîchissement de page, utiliser `localStorage` (déjà utilisé pour `saveTeams`/`saveMatches`) — **décision : persister via localStorage** (`localStorage.setItem("hb2_lastExport", Date.now())`) car sinon le rappel redevient "jamais" à chaque réouverture de l'app, ce qui casse l'utilité du filet de sécurité.
- Réutilisation stricte de `exportAllMatches()` existant — le bandeau n'est qu'un appel à une fonction déjà là.

**Nouvelles structures de données :** une seule clé `localStorage` supplémentaire (`hb2_lastExport`), aucun changement de schéma IndexedDB.

**Impact sur l'existant :** aucun changement de `exportAllMatches()` lui-même, uniquement l'ajout de l'affichage dans `renderBilan`/équivalent et de l'écriture du timestamp après succès.

## F4 — Audit frictions saisie

**Pas de décision d'architecture à prendre en amont** — c'est une investigation (revue manuelle du workflow par Romain + relecture du code de `validateActionPanel`/`clickActionPlayer`/`clickGoalZone`). Si des frictions concrètes sont identifiées, elles redeviendront des stories avec leur propre décision technique au moment où elles seront cadrées.

## F5 — Polish PWA iPhone

**Comment on implémente :**
- Vérifier/ajuster `manifest.json` (icônes, `display`, `name`/`short_name`) et les meta tags Apple déjà présents dans `index.html` (`apple-mobile-web-app-title`, `theme-color`).
- Changement de config pure, aucun impact sur `app.js`.

## Risques (vue technique)

- **Régression iPad** si le breakpoint choisi (700px) chevauche un mode d'usage iPad existant non prévu (ex : iPad mini en portrait serré). À vérifier explicitement en test avant livraison — repris en détail par le Risk Analyst.
- **Scroll horizontal de la barre d'actions** peut masquer un bouton important (ex : TM) si mal indiqué visuellement — nécessite un indice visuel de scroll (ombre de bord) pour ne pas donner l'impression que la liste s'arrête.

## Critère de bascule (quand une refonte structurelle deviendrait nécessaire)

Le fichier `app.js` (actuellement ~3700 lignes) reste gérable en un seul fichier tant qu'on ajoute des features de disposition/visuel. Le jour où une feature nécessiterait une **vraie logique différente selon l'appareil** (pas juste une disposition différente — ex : un mode de saisie simplifié spécifique iPhone avec moins d'étapes), ce serait le signal pour introduire une séparation de rendu (pas un framework, mais au minimum des fonctions de rendu dédiées par contexte). Ce n'est pas nécessaire pour F1–F5.
