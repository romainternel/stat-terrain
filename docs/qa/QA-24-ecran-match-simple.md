# QA — STORY-24 : Écran Match en mode Simple

## Méthode de test
Tests réels via CDP — vrais clics (`Input.dispatchMouseEvent`), lecture directe de l'état (`S.events`, `S.mode`) et des fonctions d'agrégation (`teamScore`, `teamStat`, `gkStats`), sur iPad (1024×768) et iPhone portrait réel (390×844).

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Pas de terrain/zone/PD/PO/PEN détaillé en mode Simple | ✅ | Vérifié : `.ml-actions`, `.court-pick`, `#pd-btn` tous absents du DOM quand `S.mode==='simple'`. |
| Tap BUT/ARRÊT/NON CADRÉ auto-valide sans étape intermédiaire | ✅ | 3 boutons testés individuellement par équipe (6 au total) — chaque clic crée immédiatement un événement complet. |
| Score correct (`teamScore()`) | ✅ | Vérifié après un BUT : `teamScore('home')===1`. |
| Stats Gardiens (`gkStats()`) correctes | ✅ | Vérifié après un ARRÊT adverse : `gkStats(home GK)` reflète `saves:1, total:1, pct:"100%"` — `gkId` bien renseigné automatiquement. |
| Feed d'événements fonctionnel | ✅ | Compteur du feed reflète `S.events.length`, bouton Annuler présent et fonctionnel (testé : suppression du dernier événement). |
| 2min/Carton Rouge/TM accessibles en Simple | ✅ | Vivent dans `.ml-left`, non touchés par le branchement conditionnel — présents dans toutes les captures Simple. |
| Badge de mode actif visible en permanence | ✅ | "⚡ MODE SIMPLE ACTIF" affiché en continu au-dessus des boutons, pas seulement au changement de mode. |
| Table Joueurs sous-comptant sur match mixte — accepté | ✅ | Comportement confirmé par lecture de code (`recordEvent` avec `playerId` null/undefined) — non testé visuellement sur l'écran Stats lui-même, mais la logique sous-jacente est celle documentée et acceptée par le PRD. |
| Aucune régression du mode Expert | ✅ | Parcours complet rejoué par vrais clics : BUT (terrain+zone), SAVE (terrain+zone), OFF (terrain+zone), PB (auto-validation directe), PO→PEN_GOAL (mode pénalty), PD (assist attaché correctement au bon événement), 2min (badge → sélection joueur → stat incrémentée), Annuler. Tous corrects. |

## Cas limites testés
- Bascule Simple → Expert **en cours de match** (événements déjà saisis en Simple) : le score et le feed restent corrects après bascule, l'écran Match Expert s'affiche normalement pour la suite (terrain, actions, PD).
- iPhone portrait réel (390×844) : l'écran Simple ne nécessite quasiment aucun scroll (31px, contre plusieurs centaines de pixels en Expert) — objectif de la feature atteint concrètement, pas juste supposé.

## Bugs trouvés
Aucun dans le code livré.

Une fausse alerte a été détectée et corrigée en cours de vérification (pas un bug de l'app) : un premier test automatisé du parcours Expert (OFF/tir non cadré) supposait à tort que cette action ne nécessitait pas de clic sur une zone de but — en réalité BUT/SAVE/OFF nécessitent tous les trois le terrain ET la zone (cf. `CLAUDE.md`). Une fois le test corrigé pour inclure ce clic, le comportement était parfaitement correct.

## Régressions détectées
Aucune — confirmé par un rejeu exhaustif du parcours Expert complet (cf. tableau ci-dessus), pas seulement un test de fumée, conformément au risque P0 identifié par le Risk Analyst.

## Verdict
**PASSED**

Tous les critères d'acceptation sont satisfaits, y compris le critère P0 de non-régression du mode Expert.
