# QA — STORY-26 : Mode lecteur (verrouillage de la saisie)

## Méthode de test
Tests réels via CDP (Chrome headless dédié, profil temporaire isolé, port 9512) — vrais clics (`Input.dispatchMouseEvent` à des coordonnées calculées via `getBoundingClientRect()`, pas de simple appel `.click()` pour les cas où une désaturation CSS `pointer-events:none` doit être vérifiée), lecture directe de l'état (`S.*`) et captures d'écran, sur viewport desktop 1024×768. Écran d'accès Supabase contourné via injection `S.authOk=true`, conformément à la consigne.

**Point méthodologique notable (sans rapport avec la story)** : l'app fait un vrai appel réseau à Supabase au chargement (`checkAuthSession()`), qui peut écraser le bypass `S.authOk=true` de façon asynchrone quelques secondes après. Un garde-fou (ré-assertion périodique + attente courte après chaque setup) a été ajouté au script de test pour neutraliser cette course. Vérification annexe faite au passage : les tentatives d'écriture Supabase envoyées pendant les tests (`recordEvent` en mode normal) sont toutes revenues en **401** (non authentifiées côté serveur, RLS bloque bien l'écriture sans session réelle) — aucune donnée de test n'a été écrite dans la base de production.

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Bouton dans le panneau Réglages bascule `S.readOnly` on/off | ✅ | Clic réel sur `#readonly-toggle-btn` : `readOnly` passe `false→true` puis `true→false`, libellé du bouton change en conséquence ("🔒 Activer" / "🔓 Désactiver"). |
| État mémorisé par appareil, persiste au rechargement | ✅ | Après activation puis **reload réel de la page** (`Page.navigate`), `S.readOnly` reste `true` (lu depuis `localStorage["hb2_readonly"]`) avant même tout re-setup applicatif. |
| Toute écriture locale sur le match en cours bloquée en mode lecteur | ✅ | Voir tableau détaillé ci-dessous — chaque catégorie testée par clic réel ou appel direct, aucune n'aboutit à une mutation d'état. |
| Réception distante (sync entrante) continue de fonctionner en mode lecteur | ✅ | `mergeRemoteEvent()` appelé explicitement pendant `S.readOnly=true` : l'événement distant est bien ajouté à `S.events` (fail-open confirmé, comportement central de la feature). |
| Bandeau visuel + désaturation des boutons d'écriture signalent l'état verrouillé | ✅ | Capture d'écran : bandeau jaune "👁 Mode lecteur — saisie verrouillée" affiché en continu, boutons d'action/TM/sanctions/chrono/Annuler/PD à `opacity:0.35;pointer-events:none` confirmé par `getComputedStyle`. Comparaison directe avec la capture en mode normal (voir Cas limites). |
| Panneau Réglages et son bouton de bascule restent accessibles en mode lecteur | ✅ | Ouverture du panneau (`#settings-btn`) et clic sur `#readonly-toggle-btn` tous deux fonctionnels par clic réel pendant `S.readOnly=true`, aucune auto-exclusion. |
| Hors scope : écran Équipes non verrouillé | ✅ | Vérifié explicitement (pas seulement supposé) : sur `S.view='setup'` avec `S.readOnly=true`, clic réel sur `+ Ajouter` (`[data-add-player="home"]`) après saisie d'un nom → le joueur est bien ajouté (`S.home.players` passe de 1 à 2). Comportement conforme au hors-scope documenté. |

## Détail des catégories de blocage testées en mode lecteur

| Catégorie | Mécanisme vérifié | Résultat |
|---|---|---|
| Workflow terrain complet (action → joueur → zone → position) | Clic réel sur `[data-act="GOAL"]` : `selectAction` bloque dès le 1er geste, `S.selectedAction` reste `null`. **Scénario exact du rejet initial rejoué** : action sélectionnée en mode normal, puis lecteur activé *pendant* que l'action est déjà en attente, puis clic joueur réel sur le terrain → `clickActionPlayer` bloque, `S.actionPanel` reste `null`, `S.events.length` reste à 0. | ✅ Aucune fuite, y compris sur le scénario qui avait motivé le 1er REJETÉ du Code Reviewer. |
| TM (temps mort) | `S.selectedAction` forcé à `"TM"` directement (contournement volontaire de la garde de `selectAction` pour isoler la garde de `clickTeam`), puis `clickTeam("home")` appelé : aucun événement TM créé, `tmUsed` inchangé. | ✅ |
| Sanctions 2min / Carton rouge | Clic réel sur `[data-badge="home|TWO_MIN"]` : le menu de sélection joueur ne s'ouvre pas (`S.selectedAction`/`S.playerSelect` restent `null`). | ✅ |
| Chrono (start/stop/reset) | Clic réel sur `#t-toggle` : `S.running` reste `false`. `S.time` forcé à 42 en mode normal puis lecteur activé, clic réel sur `#t-reset` : `S.time` reste à 42. | ✅ |
| Bascule mi-temps | Clic réel sur `#per-btn` : `S.period` reste à 1. | ✅ |
| Sélection gardien | Changement de valeur + événement `change` réel dispatché sur `[data-gk-sel="away"]` : `S.away.gkId` inchangé. | ✅ |
| Widget PD (passe décisive) | Après un but marqué (mode normal), lecteur réactivé, clic réel sur `#pd-btn` : `S.pdSelect` reste `false`, aucun assist attribué. | ✅ |
| Annuler / supprimer un événement | Clic réel sur `#undo-btn` (protégé par CSS `pointer-events:none` en plus de la garde JS) : `S.events.length` inchangé. Appel direct `undoLast()`/`deleteEvent(0)` : inchangé également. | ✅ |
| Sauvegarder le match | Appel direct `saveMatch()` : retour immédiat sur la garde, aucun `safeAlert` déclenché (donc aucun appel à `dbSaveMatch`/`markMatchFinished` — pas de passage du match en "finished" côté Supabase). | ✅ |
| Nouveau match | Appel direct `newMatch()` : retour immédiat sur la garde, **avant même** l'appel à `safeConfirm` — `S.events` inchangé. | ✅ |
| Import CSV | Appel direct `importMatchCSV()` : retour immédiat sur la garde, aucun `<input type="file">` créé dans le DOM. | ✅ |
| Charger un match depuis l'historique (`📂 Charger`) | Test renforcé : match factice inséré dans `S.matchHistory` (roster vide, 1 seul événement d'ID connu) ; clic réel sur `[data-load-match="999"]` en mode lecteur → l'ID du premier événement et le nombre de joueurs de l'équipe home **restent strictement identiques** à avant le clic (pas de remplacement par le match factice). | ✅ |
| Mode Simple (`data-simple`, sans garde JS propre sur le handler lui-même) | Clic réel sur un bouton BUT du mode Simple en lecture seule : `S.events.length` inchangé — protection assurée en cascade par la garde de `recordEvent()` elle-même, pas par le handler du bouton. | ✅ |

## Cas limites testés
- **Scénario du rejet initial rejoué à l'identique** (action déjà sélectionnée au moment de l'activation du mode lecteur) : plus aucune fuite, conforme aux corrections de la 2e passe de code review.
- **Bascule Simple ↔ mode lecteur combinés** : le handler `[data-simple]` n'a pas de garde explicite mais reste protégé par la garde de `recordEvent()` en cascade — vérifié empiriquement, pas juste déduit du code.
- **Persistance après reload réel du navigateur** (pas juste relecture de variable) : confirmée.
- **Comparaison visuelle directe** normal vs lecteur (2 captures d'écran, mêmes données de match) : contraste net — boutons pleinement saturés en mode normal, nettement grisés + bandeau jaune en mode lecteur.
- **Non-régression mode normal, Expert** : workflow BUT complet rejoué par vrais clics (action → joueur → position terrain → zone de but) → événement correctement créé (`type:GOAL`, `playerId:p1`, `goalZone:MC`, score à jour).
- **Non-régression mode normal, Simple** : clic réel sur bouton ARRÊT → événement `SAVE` auto-validé correctement créé.
- **Non-régression écran Équipes** en lecture seule : ajout de joueur toujours fonctionnel (hors scope confirmé, pas juste supposé).

## Bugs trouvés
Aucun. Les deux points Bloquants de la 1ère passe de code review (workflow terrain non gardé, actions destructrices du panneau Réglages non gardées) sont confirmés corrigés à l'usage réel, y compris sur le scénario exact qui avait motivé le rejet initial.

## Régressions détectées
Aucune :
- Le workflow de saisie complet en mode Expert (terrain, zone, position) fonctionne à l'identique en mode normal.
- Le mode Simple fonctionne à l'identique en mode normal.
- L'écran Équipes n'est pas affecté par le mode lecteur (hors scope respecté).
- La réception d'événements distants (sync Supabase) n'est pas affectée par le mode lecteur — vérifié en appelant directement `mergeRemoteEvent()` pendant `S.readOnly=true`.

## Point cosmétique non-bloquant (déjà identifié et accepté par le Code Reviewer)
Confirmé visuellement sur la capture d'écran : les éléments du terrain (joueurs, lignes, zones) ne sont pas désaturés en CSS sous `.match-layout.is-readonly`, contrairement aux boutons d'action. Fonctionnellement inoffensif (les clics sur le terrain ne font plus rien, vérifié dans le tableau ci-dessus), mais un aidant peut ne pas percevoir immédiatement que le terrain est lui aussi verrouillé. Déjà noté comme "Recommandé, non-bloquant" par le Code Reviewer — ne remet pas en cause le verdict QA, mentionné ici pour traçabilité en cas de story de polish ultérieure.

## Verdict
**PASSED**

Tous les critères d'acceptation de la story sont satisfaits, y compris le scénario exact qui avait motivé le rejet initial du Code Reviewer (workflow terrain avec action pré-sélectionnée avant activation du mode lecteur) et le hors-scope volontaire (écran Équipes). Aucune régression détectée sur les workflows Expert, Simple, ou la synchronisation temps réel. Feu vert pour la suite du pipeline.
