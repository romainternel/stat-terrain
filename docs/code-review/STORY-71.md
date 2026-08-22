# Code Review — STORY-71 : confirmation et garde-fous au changement de mi-temps

*Produit par le Code Reviewer — squad de contrôle BMAD*
*Diff revu : `app.js` — nouvelle fonction `switchPeriod()` (app.js:825-848), binding `per-btn` simplifié (app.js:5015)*

## Diff revu
```diff
+function switchPeriod(){
+  if(S.readOnly) return;
+  const wasP1=S.period===1;
+  if(wasP1){
+    if(!safeConfirm("La mi-temps 1 est-elle terminée ?\n\n...")) return;
+    stopTimer(); S.period=2; S.time=0; S.tmLastAlert=0; S.halfTimeLastAlert=0;
+    startTimer();
+    showToast("🧤 Pense à vérifier les gardiens pour la 2e mi-temps !", true);
+  } else {
+    const lastP1Evt=S.events.find(e=>(e.period||1)===1);
+    const restoreTime=lastP1Evt?lastP1Evt.rawTime:1800;
+    if(!safeConfirm(`Revenir à la mi-temps 1 ?\n\n...`)) return;
+    stopTimer(); S.period=1; S.time=restoreTime; S.tmLastAlert=0; S.halfTimeLastAlert=0;
+    upsertMatchSnapshot();
+    showToast(`↩ Retour à la mi-temps 1 — chrono en pause à ${fmtTime(restoreTime)}`);
+    R();
+  }
+}
...
- const pb=document.getElementById("per-btn"); if(pb) pb.onclick=()=>{if(S.readOnly)return;const wasP1=...};
+ const pb=document.getElementById("per-btn"); if(pb) pb.onclick=switchPeriod;
```

## Conformité Architecture
Correspond au détail donné dans `docs/architecture/chrono-mi-temps.md` section F2+F3+F4+F5 — les deux branches, l'ordre des opérations (`stopTimer()` avant mutation, cf. justification de l'Architect sur le double-upsert déjà présent dans le code d'origine) et le fallback `1800` sont implémentés exactement comme spécifié.

## Conventions de nommage et de style
Conforme. `S.events.find(e=>(e.period||1)===1)` réutilise le pattern défensif `(e.period||1)` déjà présent ailleurs dans le fichier (ex: filtrage par période dans les fonctions de stats) plutôt que d'inventer une nouvelle façon de gérer un `period` potentiellement absent sur un événement legacy — bon réflexe de cohérence.

## Réutilisation vs duplication
`startTimer()`/`stopTimer()`/`safeConfirm()`/`showToast()`/`upsertMatchSnapshot()` tous réutilisés tels quels, aucune logique dupliquée. La fonction remplace un handler anonyme inline par une fonction nommée — cohérent avec le reste du fichier (`recordTM`, `startTimer`, etc. sont toutes nommées).

## Scope
Deux points de code touchés, tous deux dans le périmètre exact de la story. Aucun débordement.

## Point notable — écart entre la maquette et la contrainte technique réelle (à signaler pour le QA, pas bloquant)
`docs/design/chrono-mi-temps.md` maquette les deux dialogues avec des **boutons** libellés "Annuler"/"Oui, MT2" et "Annuler"/"Oui, MT1". `docs/risks/zones-tir-distance.md`... pardon, `docs/risks/chrono-mi-temps.md` (risque #1) prescrit explicitement : *"le texte des deux boutons doit nommer explicitement la destination... jamais 'OK'/'Confirmer' générique"*. **Ceci n'est techniquement pas réalisable** : `safeConfirm()` s'appuie sur `window.confirm()`, dont les deux boutons sont toujours ceux du navigateur/OS ("OK"/"Annuler" ou équivalent localisé) — impossible à personnaliser, quel que soit le texte passé en paramètre. Le Visual Crafter avait déjà noté que les boutons ne sont "pas stylables" mais sans expliciter que leur **texte** lui-même est également figé, pas seulement leur apparence.

L'implémentation actuelle gère cette contrainte correctement — elle ne tente aucune personnalisation impossible des boutons et place toute la distinction dans le **corps du message** (`"La mi-temps 1 est-elle terminée ?..."` vs `"Revenir à la mi-temps 1 ?..."`, avec le temps de retour calculé explicitement affiché). C'est la seule approche possible avec `window.confirm()`. Mais cela signifie que le risque #1 tel que formulé n'est mitigé qu'**en partie** : la distinction repose sur la lecture du message, pas sur un survol rapide des boutons comme le risque le supposait.

**Recommandation pour le QA** : vérifier explicitement que le corps du message (pas les boutons) suffit à distinguer les deux sens sans ambiguïté sur un vrai iPad, en conditions de lecture rapide. Pas bloquant pour le Code Review (l'implémentation est correcte compte tenu de la contrainte réelle), mais le texte exact des deux dialogues mérite une vérification humaine ciblée plutôt qu'une simple confirmation que le code s'exécute.

## Point notable — comportement légèrement plus correct que l'original (positif, pas une remarque)
Dans l'ancien code, `S.tmLastAlert=0;S.halfTimeLastAlert=0;` s'exécutait inconditionnellement à chaque clic (il n'y avait pas de confirmation, donc chaque clic était de facto un vrai changement). Dans la nouvelle version, ce reset ne se produit que **si la confirmation est acceptée** — sémantiquement plus correct (annuler ne doit rien réinitialiser), sans être un changement de comportement observable puisque l'ancien code n'avait de toute façon aucun chemin "annulé".

## Gestion d'erreurs
N/A — aucun nouvel appel externe, réutilise des fonctions déjà robustes.

## Sécurité basique
N/A.

## Verdict
**APPROUVÉ AVEC RÉSERVES**

Aucun point bloquant sur le code lui-même — il est conforme à l'architecture et correctement construit compte tenu des contraintes réelles de `window.confirm()`. La réserve porte sur un écart entre la maquette (boutons personnalisés, irréalisable) et l'implémentation (distinction par le texte du message, seule option technique) : à faire vérifier explicitement par le QA/E2E plutôt que supposé équivalent.
