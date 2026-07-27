# QA — STORY-03 (Layout Match adapté iPhone paysage)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

App relancée en local, mesures DOM précises (`getBoundingClientRect`) en plus des captures visuelles, à iPhone paysage (844×390) et iPad paysage (1024×768, non-régression). Roster réaliste (22 FENIX + 7 US Nantes).

## Critères d'acceptation

- ✅ **Corrige le chevauchement barre du bas/terrain + chrono tronqué** — **précision importante** : la mesure DOM montre qu'il n'y avait en réalité jamais de chevauchement de boîtes entre `.ml-bottom` et `.ml-court` (le Developer l'a corrigé dans son propre diagnostic). Le vrai problème — chrono quasi entièrement hors champ et terrain réduit à 2 rangées visibles — est bien corrigé : le chrono et les contrôles FENIX sont maintenant **pleinement visibles** (`docs/design/screenshots/19-story03-landscape-after.png`), le terrain gagne 27px de hauteur utile (168px→195px).
- ⚠️ **Terrain visible et utilisable sans scroll excessif** — amélioration réelle et mesurée, mais **partielle** : le terrain affiche désormais 3-4 rangées de joueurs au lieu de 2, sur un total de ~7 — un scroll reste nécessaire pour voir l'intégralité de l'effectif sur le terrain en paysage. Ce n'est pas un échec de la story (le gain est réel et démontré), mais je ne peux pas cocher ce critère comme intégralement satisfait au sens strict de "sans scroll excessif" — à mi-chemin entre corrigé et amélioré.
- ✅ **Colonne gauche affiche au minimum score/timer/contrôles TM/2min/carton** — confirmé, l'équipe FENIX (score, TM/2min/carton, possession) et le chrono complet (avec boutons Stop/reset) sont visibles sans scroll.
- ✅ **Layout iPad paysage non affecté** — `docs/design/screenshots/21-story03-ipad-landscape-noregress.png` visuellement identique à la référence ; mesures DOM identiques point par point (`.act-h` 71px, `.ml-actions` 85px, boutons de contrôle 34-37px — les mêmes valeurs qu'avant, aucun écart).
- ✅ **Bascule portrait↔paysage sans perte de données** — vérifié par construction : `app.js` non modifié, `S` ne dépend jamais de l'orientation ; la bascule ne peut pas faire perdre de données puisque rien ne réinitialise l'état au changement de media query.

## Cas limites

- Équipe adverse (2e bloc `.ml-team`) hors du cadre initial en paysage, atteignable uniquement par scroll dans `.ml-left` — vérifié fonctionnel (`docs/design/screenshots/20-story03-mlleft-scrolled.png` : GK, contrôles et possession de l'équipe adverse intacts après scroll). C'est un compromis assumé par le Developer et documenté, pas un bug — mais je recommande que Romain en soit informé avant son premier match en conditions réelles avec ce format, pour ne pas être surpris.

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun bloquant. **Mineur** : le terrain nécessite encore un scroll pour voir l'intégralité de l'effectif en paysage — amélioration significative mais pas une résolution complète du critère "sans scroll excessif". Recommandation : si Romain juge ça encore gênant à l'usage réel, une story de suivi pourrait explorer une hauteur de terrain encore optimisée (ex : masquer temporairement le bloc équipe adverse par défaut plutôt que juste le condenser) — pas nécessaire de bloquer cette livraison pour ça.

## Verdict

**PASSED WITH NOTES**
