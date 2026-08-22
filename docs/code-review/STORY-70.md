# Code Review — STORY-70 : le temps mort arrête le chrono

*Produit par le Code Reviewer — squad de contrôle BMAD*
*Diff revu : `app.js`, fonction `recordTM()` (une ligne ajoutée, un commentaire)*

## Diff revu
```diff
   queueEventForSync(S.events[0]);
-  checkGkConsecutiveAlert(); checkTimeoutAdvisor(); R();
+  checkGkConsecutiveAlert(); checkTimeoutAdvisor();
+  stopTimer(); // le temps mort arrete reellement le chrono (STORY-70) — ce chemin (bouton timer) ne le faisait pas, contrairement a clickTeam()
+  R();
 }
```

## Conformité Architecture
Correspond exactement à `docs/architecture/chrono-mi-temps.md` section F1 : `stopTimer()` ajouté en dehors du bloc `if(team==="home")`, donc appliqué aussi bien au TM adverse qu'au TM FENIX, comme spécifié.

## Conventions de nommage et de style
Conforme. Le commentaire ajouté explique un "pourquoi" non évident (pourquoi ce chemin précis avait besoin du correctif, par contraste avec `clickTeam()`) — respecte la règle du projet ("pas de commentaires évidents, seulement si le pourquoi n'est pas clair").

## Réutilisation vs duplication
Réutilise `stopTimer()` existant, aucune logique dupliquée.

## Scope
Une seule fonction touchée, rien d'autre dans le fichier. Aucun débordement hors du périmètre de la story.

## Lisibilité et maintenabilité
Triviale à relire, aucune ambiguïté.

## Gestion d'erreurs
N/A — aucun nouvel appel externe introduit.

## Sécurité basique
N/A — aucune donnée sensible, aucune requête introduite.

## Point notable (pas bloquant, à signaler pour le QA)
`stopTimer()` appelle `upsertMatchSnapshot()`, que `recordTM()` n'appelait jamais directement auparavant. Effet de bord positif et cohérent avec l'intention de la story : l'état "chrono en pause" se propage désormais aussi aux **autres appareils connectés** en temps réel (`app.js:592-599`, l'abonnement `matches` applique déjà `S.running`/`clearInterval` reçu à distance) — avant ce correctif, un TM pris sur un appareil laissait le chrono continuer à tourner sur les autres appareils connectés au même match, une variante du même bug. À vérifier explicitement par le QA si un contexte multi-appareil est disponible, sinon accepter le raisonnement basé sur le code déjà en production pour cette propagation (`upsertMatchSnapshot`/abonnement Realtime, STORY-10/13).

## Note mineure (pas bloquant)
`stopTimer()` appelle déjà `R()` en interne ; le `R()` explicite en fin de fonction devient redondant. Double-render harmless, déjà le pattern accepté ailleurs dans le fichier pour le même type de flux (`clickTeam()`, TM via l'ancien chemin action-bar, lignes 867-870) — cohérence avec l'existant, pas une nouvelle dette.

## Verdict
**APPROUVÉ**

Aucune remarque bloquante. Le correctif est minimal, conforme à l'architecture, et n'introduit aucun scope creep.
