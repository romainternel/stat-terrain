# Code Review — STORY-15 : Indicateur de statut de synchronisation

## Historique
Première passe : **REJETÉ — à reprendre** (voir détail ci-dessous, conservé pour traçabilité). Point bloquant : `R()` (re-render complet) déclenché inconditionnellement dans le `finally` de `flushOutbox()`, dans le listener `online` et dans le nouveau listener `offline` — donc à chaque tick du `setInterval(15000)` qui tourne en continu pendant tout le match, avec risque de perte de focus/fermeture du clavier virtuel iPad sur `team-name-input`, `add-name-${side}`, `coach-notes`, etc.

Cette passe : **re-revue du correctif appliqué en suivant le pattern déjà en place (`renderTimer()` → patch DOM ciblé).**

## Périmètre revu (correctif)
- `app.js` l.275-352 : `dequeueEventSync()`, `flushOutbox()`, listeners `online`/`offline`, nouvelle constante `SYNC_STATUS_CFG`, nouvelle fonction `patchSyncIndicator()`, `computeSyncStatus()` (inchangée), `renderSyncIndicator()` (inchangée dans son comportement, réécrite pour consommer `SYNC_STATUS_CFG`).
- Diff confirmé via `git diff HEAD~1 -- app.js` (travail non commité, au-dessus de `b1111ec`) : les trois points d'appel `R()` identifiés au tour précédent (`finally` de `flushOutbox`, listener `online`, listener `offline`) ainsi que `dequeueEventSync` sont désormais tous sur `patchSyncIndicator()`. Aucun `R()` ne subsiste dans ce chemin.

## Vérifications demandées

### 1. Le point bloquant est-il résolu ?
**Oui, confirmé.** Recherche exhaustive de tous les appels à `R()` dans `app.js` (une quarantaine d'occurrences) : chacun est déclenché par une action utilisateur explicite (`onclick`, réponse à une saisie validée, changement d'écran, undo, etc.). Aucun n'est atteignable depuis `flushOutbox()`, les listeners `online`/`offline`, `dequeueEventSync()`, ou le `setInterval(()=>flushOutbox(),15000)` (l.320) — ces quatre chemins appellent désormais exclusivement `patchSyncIndicator()` :
  - `flushOutbox()` `finally` (l.309-312) : `patchSyncIndicator()` seul, plus de `R()`.
  - listener `online` (l.314-318) : `flushOutbox(); ...; patchSyncIndicator();` — plus de `R()`.
  - listener `offline` (l.319) : `patchSyncIndicator()` seul.
  - `dequeueEventSync()` (l.277) : `await refreshSyncPendingCount(); patchSyncIndicator();` — plus de `.then(R)`.

  Le cycle périodique de 15s ne provoque donc plus aucun re-render complet, quel que soit l'état (rien à synchroniser, synchro en cours, ou passage online/offline). Le scénario de perte de focus décrit dans la première passe (frappe interrompue toutes les 15s sur `team-name-input`/`coach-notes`/`add-name-${side}`) n'est plus reproductible par ce mécanisme.

### 2. `patchSyncIndicator()` ne plante jamais si `.sync-indicator` n'existe pas
**Confirmé, RAS.** L.337-338 : `const el=document.querySelector(".sync-indicator"); if(!el) return;` — early-return en toute première instruction utile, avant tout accès à une propriété de `el`. Couvre les deux cas demandés :
  - Écran différent de Match (`renderSyncIndicator()` n'est appelée que dans `renderMatch()`, l.1763 — sur les autres écrans l'élément n'est simplement jamais monté).
  - Supabase non configuré : `computeSyncStatus()` retourne `null` dans ce cas (`if(!sbClient) return null;`), donc `renderSyncIndicator()` retourne `""` et l'élément n'existe jamais dans le DOM — `patchSyncIndicator()` sort au premier `if(!el) return;` sans même atteindre l'appel à `computeSyncStatus()`.
  Il y a même une seconde garde redondante mais saine : `const st=computeSyncStatus(); if(!st) return;` (l.339-340), pour le cas défensif où l'élément existerait mais que `computeSyncStatus()` renverrait `null` (ne devrait pas arriver en pratique puisque `sbClient` est fixé une fois à l'initialisation, mais ne coûte rien et suit le même réflexe que `renderTimer()`/`getElementById`).

### 3. Cohérence rendu initial / patch ciblé — pas de désynchronisation possible
**Confirmé, RAS.** `renderSyncIndicator()` (l.347-352) et `patchSyncIndicator()` (l.336-346) lisent toutes les deux `computeSyncStatus()` puis indexent la **même** table `SYNC_STATUS_CFG` (l.323-327, définie une seule fois) pour obtenir `icon`/`label`/`color` — aucune duplication de la correspondance état→apparence, donc aucune classe de bug "l'une des deux copies a été mise à jour, pas l'autre".
  Comparaison champ par champ :
  - `className` : `sync-indicator sync-${st}` des deux côtés (identique).
  - `color` : rendu initial le pose en inline `style="...color:${cfg.color};..."`, le patch fait `el.style.color=cfg.color` — modifie la même propriété CSS, sans toucher aux autres propriétés inline (`font-size`, `font-weight`, `white-space` restent celles posées au rendu initial, jamais écrasées par le patch).
  - `title` et `textContent` : formule identique (`Synchronisation : ${cfg.label}` / `${cfg.icon} ${cfg.label}`) des deux côtés.
  Le CSS `.sync-syncing{animation:sync-pulse ...}` (style.css l.359-362) continue de s'appliquer correctement puisque `className` est reposé en entier à chaque patch (jamais un simple `classList.add` partiel qui risquerait de laisser une classe `sync-*` obsolète).

## Recommandé (reporté, non-bloquant, déjà noté au tour précédent)
- Fenêtre de dérive mineure de `syncPendingCount` si un événement est mis en file pendant qu'un flush est déjà en cours (`flushInProgress`) : l'indicateur peut afficher "✓ sync" jusqu'à ~15s avant recomptage. Auto-corrigé, sans perte de donnée. Non traité dans ce correctif (hors scope du point bloquant), toujours valable comme piste d'amélioration future.

## Note
- `sw.js` toujours correctement incrémenté (v71), conforme à la procédure de déploiement.
- `new Function()` sur `app.js` complet : toujours aucune erreur de syntaxe après le correctif.
- Aucune régression de scope : le correctif touche exactement les 4 points signalés comme bloquants (plus la factorisation `SYNC_STATUS_CFG`, qui est une conséquence directe et souhaitable du correctif — éviter que `renderSyncIndicator()` et `patchSyncIndicator()` divergent avec deux tables séparées), rien d'autre n'a bougé dans le diff.
- Sécurité basique : RAS, inchangé par rapport au tour précédent.

## Verdict
**APPROUVÉ**

Le point bloquant de la première passe est résolu par le pattern exact demandé (patch DOM ciblé façon `renderTimer()`), sans effet de bord : le cycle périodique de synchronisation (15s, `online`/`offline`, undo) ne déclenche plus jamais de re-render complet, la fonction de patch est défensive (no-op propre si l'élément n'est pas monté), et la factorisation via `SYNC_STATUS_CFG` élimine tout risque de désynchronisation future entre rendu initial et mise à jour ciblée. Prêt pour le QA.
