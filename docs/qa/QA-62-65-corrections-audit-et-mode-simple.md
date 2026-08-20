# QA — STORY-62 à STORY-65 (corrections Audit Final + Mode Simple à équipe unique)

## Ce que j'ai lu avant de tester
`docs/code-review/STORY-62-65.md` (APPROUVÉ), les 4 fichiers `docs/stories/STORY-62-*.md` à `STORY-65-*.md`, `docs/arch/audit-corrections-et-mode-simple.md`, `docs/risks/audit-corrections-et-mode-simple.md`.

## Méthode
CDP avec vrais clics/dispatch d'événements, contre le vrai backend Supabase de production (mot de passe fourni par Romain). Un match de test à la fois, nommé explicitement ("QA TEST", "QA TEST 2"), supprimé (local **et** Supabase, vérifié) à la fin de chaque scénario. Testé volontairement des scénarios que le Developer n'avait pas déjà couverts pendant son propre passage (reset par `newMatch()`, annulation de la confirmation "Nouveau match ?", mise à jour d'un match repris via `loadMatchAsCurrent()`, bascule manuelle de possession, mode lecteur, paysage iPhone) plutôt que de répéter ce qu'il avait déjà vérifié.

## Critères d'acceptation vérifiés

**STORY-62 (sauvegarde idempotente)**
- [x] Sauvegarder deux fois la même session → toujours 1 seule entrée (`dbGetAll()` vérifié directement, "3 match(s) en mémoire" affiché deux fois de suite)
- [x] La 2e sauvegarde reflète l'état le plus récent (même `id`, événements/score à jour)
- [x] `newMatch()` réinitialise `S.savedMatchId=null` — la sauvegarde suivante crée une **nouvelle** entrée distincte ("4 match(s) en mémoire" après le nouveau match, confirmant que l'ancienne n'a pas été écrasée)
- [x] Annuler la confirmation "Nouveau match ?" laisse `S.savedMatchId` et `S.events` strictement inchangés
- [x] `loadMatchAsCurrent(id)` fixe `S.savedMatchId=id` — modifier ce match repris puis le sauvegarder met à jour la même entrée archivée (total resté à 4, pas 5, après ajout d'un événement + sauvegarde sur un match rechargé)

**STORY-63 (historique des alertes)**
- [x] Alertes critiques poussées dans `S.alertHistory`, horodatées, plus récente en premier
- [x] Plafond à 3 entrées respecté même après un 4e déclenchement
- [x] Bandeau "🔔 Dernières alertes" affiché, réductible en pastille `[🔔N]`, réouverture fonctionnelle
- [x] `newMatch()` réinitialise `alertHistory`/`alertHistoryCollapsed`/`alertHistoryDismissed`
- [x] `loadMatchAsCurrent()` réinitialise `S.alertHistory` (vérifié `[]` juste après chargement)
- [x] Mode lecteur : bandeau alertes non affecté par le verrouillage (aucune garde `readOnly` n'y a été ajoutée à tort)

**STORY-64 (garde-fou Analyse)**
- [x] Sous 10 tirs cumulés (testé à 8) : seuls résultat + efficacité brute affichés
- [x] À exactement 10 tirs cumulés : tous les insights qualitatifs réapparaissent d'un coup (comportement pile au seuil, pas approximatif)
- [x] Même comportement vérifié sur `matchAnalysis()` (Bilan, match archivé) que sur `autoAnalysis()` (match en cours)

**STORY-65 (Mode Simple à équipe unique)**
- [x] Un seul bloc de boutons visible, jamais deux
- [x] Libellé + couleur suivent `S.possession`, bascule automatique après une action
- [x] Bascule manuelle via "◉ POSSESSION" du scoreboard toujours fonctionnelle et répercutée immédiatement sur le bloc Mode Simple
- [x] Bon événement enregistré pour la bonne équipe juste après un changement de possession
- [x] Mode lecteur : bloc affiché mais non cliquable (0 événement ajouté sur clic testé)
- [x] Testé et lisible sur iPhone portrait (390×844), iPhone paysage (844×390) et iPad paysage (1024×768) — rangée unique de 5 boutons confortable dans les 3 cas, gain d'espace vertical net vs l'ancien double bloc
- [x] Nom d'équipe toujours visible au-dessus des boutons dans tous les cas testés

## Bugs trouvés

### Hors scope — pré-existant, sans lien avec STORY-62 à 65 (Majeur, à signaler pour une future story)
En rechargeant un match archivé via "📂 Charger" (`loadMatchAsCurrent()`) puis en continuant à saisir de nouveaux événements **sans relancer le match**, la synchronisation Supabase échoue en boucle (erreurs 409 répétées sur `match_events`, une toutes les ~15s). Root cause identifiée par lecture de code : `loadMatchAsCurrent()` remet `S.currentMatchId` à `null` (comportement voulu, P0 de STORY-36) ; le premier nouvel événement déclenche `queueEventForSync()` qui régénère un nouvel id **sans jamais appeler `upsertMatchSnapshot()`** pour créer la ligne `matches` correspondante — contrairement au bouton "▶ Lancer le match" qui le fait toujours. Un événement peut ainsi se retrouver synchronisé côté `match_events` sans ligne `matches` parente.
- **Confirmé sans lien avec ce cycle** : `loadMatchAsCurrent()` n'a été modifié par STORY-62 que pour deux lignes (`S.savedMatchId`, `S.alertHistory`), qui ne touchent ni `S.currentMatchId`, ni `queueEventForSync()`, ni `upsertMatchSnapshot()`. Le chemin "recharger un match archivé puis continuer à saisir" semble n'avoir jamais été testé auparavant dans les cycles précédents (les cas déjà couverts sont soit la reprise d'un match Supabase `in_progress` via `resumeMatch()` — un chemin différent —, soit le chargement pour consultation/PDF sans reprise de saisie, STORY-36).
- **Impact réel** : local jamais affecté (fail-open respecté, l'événement s'enregistre bien localement) ; mais l'événement ajouté après un rechargement ne se propage pas fiablement aux autres appareils tant que ce gap n'est pas corrigé.
- **Nettoyage effectué** : la ligne `match_events` orpheline créée pendant ce test a été supprimée manuellement de Supabase, vérifiée absente après coup ; aucune donnée réelle de Romain concernée.
- **Recommandation** : nouvelle story dédiée, hors du périmètre de ce cycle — `queueEventForSync()` (ou `loadMatchAsCurrent()`) devrait appeler `upsertMatchSnapshot()` avant de régénérer un `currentMatchId`, symétriquement au bouton de lancement.

Aucun autre bug trouvé dans le périmètre des 4 stories.

## Régressions détectées
Aucune. Les 4 stories fonctionnent correctement ensemble (testées dans un même scénario continu : lancement → Mode Simple → alertes → sauvegarde → nouveau match → rechargement → sauvegarde). Le point du Code Review (texte de confirmation `loadMatchAsCurrent()` pourrait mentionner le nouveau comportement de sauvegarde) reste Note, non re-testé ici pour cette raison — déjà classé non bloquant.

## Verdict
**PASSED** — le bug trouvé est hors du périmètre des 4 stories (pré-existant, sans lien de cause avec le code livré ici) et ne remet pas en cause leur correction ; signalé pour un futur cycle plutôt que traité maintenant.
