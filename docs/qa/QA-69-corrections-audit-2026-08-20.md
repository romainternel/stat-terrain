# QA — STORY-69 (corrections des 3 bugs Majeurs de l'audit du 2026-08-20)

## Contexte
Story de correction ciblée, née de `docs/regression/audit-complet-2026-08-20.md`. Code Reviewer : APPROUVÉ après une reprise (`docs/code-review/STORY-69-corrections-audit-2026-08-20.md`). Testé en conditions réelles contre le vrai backend Supabase de production, via un serveur local (`http-server` sur `localhost:8811` servant les fichiers du dépôt tels quels) — le site GitHub Pages n'a pas encore reçu ces correctifs, donc un test contre l'URL de production aurait encore exercé l'ancien code.

## Critères testés

### Fix 1 — effectif courant plus jamais écrasé par "📂 Charger"
- ✅ `localStorage.hb2_teams_cf` était `null` (effectif 22 pas encore persisté) avant tout chargement d'archive
- ✅ Après clic réel sur "📂 Charger" (match Rodez, 13 joueurs archivés, 14 événements) : `localStorage.hb2_teams_cf` reste `null` — non touché
- ✅ Non-régression : le match archivé s'affiche correctement pendant la session (13 joueurs en mémoire, onglet Équipes affiche "Effectif (13)", événements/score corrects)
- ✅ Après rechargement complet de la page (`F5` réel via `browser_navigate`) : l'effectif réel repart bien de 22 joueurs (`defaultFenixCfTeam()`), preuve que le localStorage n'a jamais été pollué

### Fix 2 — bouton PD gated sur les buts
- ✅ Après un Carton Rouge réel (clic réel, joueur sélectionné) : `document.getElementById('pd-btn')` absent
- ✅ Non-régression : après un vrai BUT (terrain + zone), le bouton PD réapparaît, son clic ouvre bien "🎯 Passe décisive — ⚽ But de [joueur] — Qui a fait la passe ?", et la sélection d'un passeur écrit correctement `assistId`/`assistName` sur l'événement GOAL

### Fix 3 — plus de course, plus de blocage réseau sur "Nouveau match"
Test le plus exigeant de la story, deux angles vérifiés séparément :
- ✅ **Fail-open** : réseau Supabase artificiellement ralenti à 3s (patch de `window.fetch`) → clic réel sur "🆕 Nouveau match" (confirmation acceptée) → l'état local (`S.currentMatchId=null`, `S.journee` incrémenté, `S.view="match"`) est déjà entièrement à jour dès l'appel suivant (round-trip < 3s) — **le reset local n'attend jamais le réseau**
- ✅ **Course corrigée** : 4s plus tard (le temps que l'écriture différée aboutisse), requête directe sur `matches` : `status:'finished'` (jamais resté coincé "in_progress" malgré le délai réseau artificiel)
- ✅ **Pas de fuite de métadonnées** : `journee` sur le match fini = `"J2"` (la valeur du match qui vient de se terminer), **pas** `"J3"` (la valeur déjà incrémentée pour le match suivant au moment où l'écriture différée s'exécute réellement) — vérifie le point le plus subtil du fix
- ✅ Répété une seconde fois avec le réseau normal (premier test de la session, match `bec97ff5`) : `status:'finished'`, `journee:'J1'` correct également — cohérent dans les deux conditions réseau

## Cas limites testés
- "Nouveau match" cliqué avec le chrono effectivement en cours (`S.running=true`) — cas réel le plus fréquent, celui qui déclenchait la course
- `matchId` capturé avant reset même quand la finalisation part après coup — vérifié qu'aucune régression n'affecte les autres appelants de `markMatchFinishedById` (`switchTeamProfile`, `saveMatch`, `discardResumableMatch` — non modifiés, signature rétrocompatible)

## Bugs trouvés
Aucun. Les 3 correctifs se comportent exactement comme documenté dans le Code Review.

## Régressions détectées
Aucune régression sur les parcours adjacents testés (workflow BUT complet, affichage d'un match archivé, effectifs, journée/saison).

## Nettoyage de fin de session
Tous les matchs de test créés pendant le QA (`bec97ff5-...`, `158e6c4b-...`) supprimés de Supabase (`matches` + `match_events`) après vérification de leur état final — 0 ligne restante. Au passage, le résidu "Yoshi" (`status:'finished'`, 0 événement, `c54d7572-...`) identifié dans l'audit du 2026-08-20 comme origine incertaine a été supprimé également (root cause désormais confirmée : condition de course de `newMatch()`, corrigée par cette story). Seuls les 2 vrais matchs de Romain (Rodez ×2, `status:'finished'`) subsistent sur Supabase, vérifié par requête directe.

## Verdict

**PASSED.**
