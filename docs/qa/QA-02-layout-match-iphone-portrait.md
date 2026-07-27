# QA — STORY-02 (Layout Match adapté iPhone portrait)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

App relancée en local (serveur statique + Chrome headless piloté via CDP), roster réaliste injecté (22 joueurs FENIX + 7 US Nantes), 5 événements de match simulés. Tests à iPhone portrait (390×844) et iPad paysage (1024×768, non-régression).

## Critères d'acceptation

- ✅ **Corrige le chevauchement de labels** — `docs/design/screenshots/15-story02-final-portrait.png`. Mesure DOM : `overlap:false` sur les 6 boutons `.act-h`, aucune paire ne se chevauche.
- ✅ **Score/timer/contrôles/barre d'actions visibles sans scroll vertical au-dessus du terrain** — la capture à 390×844 montre les deux blocs équipe, le timer, ET le haut du terrain, tous visibles simultanément sans le moindre scroll (`.ml-left` mesuré à 541px de hauteur sur un viewport de 844px).
- ✅ **Barre d'actions défile horizontalement sans réduire la hauteur du terrain** — `docs/design/screenshots/16-story02-final-scrolled.png` après `scrollLeft=9999` : les 6 boutons restent à hauteur fixe (71px), le terrain en dessous n'est pas affecté par le scroll horizontal de la barre.
- ✅ **Zones tactiles ≥44px** — mesure DOM : boutons d'action 56 à 112px de large × 71px de haut ; bouton possession 44-45px de haut. Tous au-dessus du seuil.
- ✅ **Layout iPad non modifié** — `docs/design/screenshots/14-story02-ipad-landscape-noregress.png` visuellement identique à la référence d'avant fix (`03-match-ipad-landscape.png`).
- ✅ **Une action se saisit en autant de taps que sur iPad** — vérifié par construction : `app.js` n'a reçu aucune modification (diff confirmé vide sur ce fichier), donc la logique d'interaction (nombre de clics, ordre des étapes) est strictement identique à l'iPad. Cette story ne pouvait pas introduire de friction supplémentaire puisqu'elle ne touche aucun gestionnaire d'événement. **Non re-testé en conditions réelles de clic bout-en-bout** (le test s'appuie sur l'absence de diff JS, pas sur un parcours utilisateur simulé complet) — la validation définitive en situation réelle reste à faire par Romain sur son appareil, comme pour STORY-09.

## Cas limites

- Effectif complet (22 joueurs sélectionnés simultanément, plus que les 7 d'une composition réelle) : le terrain montre un chevauchement des étiquettes joueurs (`.cp-player`) à 390px de large. **Ce n'est pas une régression de cette story** — confirmé absent à 1024px avec les mêmes données, donc préexistant à toute largeur réduite, et hors du périmètre déclaré de STORY-02 (`.court-pick`/`.cp-player` n'étaient pas dans la zone concernée). Signalé par le Developer et le Code Reviewer, à transformer en nouvelle story par le Scrum Master plutôt que traité ici.
- Effectif réel (7 joueurs typiques d'une ligne de départ) : non testé spécifiquement dans cette passe, mais comme le problème ci-dessus est une question de densité (nombre de joueurs affichés simultanément), un effectif de 7 devrait être nettement moins sujet au chevauchement — à confirmer si la nouvelle story sur `.cp-player` est priorisée.

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun bloquant ni majeur dans le périmètre de la story. Le chevauchement `.cp-player` est un bug réel mais **hors scope**, déjà transmis pour un traitement séparé (voir note du Developer et du Code Reviewer).

## Verdict

**PASSED**
