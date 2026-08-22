# Architecture — Chrono : temps mort et changement de mi-temps

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v17-chrono-mi-temps.md` et `docs/design/chrono-mi-temps.md`*

## Décision technique
Deux points de code isolés dans `app.js`, aucune nouvelle structure de données, aucun nouveau fichier. On modifie une fonction existante (`recordTM`) et on remplace le handler inline de `per-btn` par une fonction nommée `switchPeriod()`, sur le modèle des fonctions déjà nommées du fichier (`recordTM`, `startTimer`, `stopTimer`).

### F1 — `recordTM(team)` (app.js:963-980)
Vérifié dans le code : ce chemin (celui réellement câblé sur `.mlt-btn-tm`, cf. ligne 2246/2464) ne contient aujourd'hui aucun appel à `stopTimer()`, contrairement à l'autre chemin de TM historique `clickTeam()` (ligne 867) qui le fait déjà. Correctif : ajouter `stopTimer();` juste avant le `R();` final de `recordTM`, en dehors du bloc `if(team==="home"){...}` pour s'appliquer aussi bien à un TM adverse qu'à un TM FENIX.

```javascript
function recordTM(team){
  if(S.readOnly) return;
  if(team==="home"){
    const mtKey=S.period===1?"mt1":"mt2";
    if(S.tmUsed[mtKey]>=2||S.tmUsed.mt1+S.tmUsed.mt2>=3){
      showToast("Plus de temps mort disponible !", true); return;
    }
    S.tmUsed[mtKey]++;
  }
  S.events.unshift({ /* inchangé */ });
  queueEventForSync(S.events[0]);
  checkGkConsecutiveAlert(); checkTimeoutAdvisor();
  stopTimer();       // ← ajout : le TM arrête réellement le chrono, comme clickTeam() le fait déjà pour l'autre chemin
  R();                // stopTimer() appelle déjà R() en interne — double render redondant mais harmless, même pattern déjà accepté dans clickTeam() (ligne 867-870)
}
```

### F2+F3+F4+F5 — `switchPeriod()`, remplace le handler inline de `per-btn` (app.js:4981)

```javascript
function switchPeriod(){
  if(S.readOnly) return;
  const wasP1 = S.period===1;
  if(wasP1){
    if(!safeConfirm("La mi-temps 1 est-elle terminée ?\n\nLe chrono va repasser à 0:00 et redémarrer automatiquement en mi-temps 2.")) return;
    stopTimer();                 // coupe proprement l'interval en cours avant de le relancer (évite tout double-interval)
    S.period=2;
    S.time=0;
    S.tmLastAlert=0; S.halfTimeLastAlert=0;
    startTimer();                 // running=true, nouvel interval, upsertMatchSnapshot()+R() déjà inclus
    showToast("🧤 Pense à vérifier les gardiens pour la 2e mi-temps !", true);
  } else {
    const lastP1Evt = S.events.find(e => (e.period||1)===1);   // S.events est unshift-ordonné : le premier match = le plus récent tag de MT1
    const restoreTime = lastP1Evt ? lastP1Evt.rawTime : 1800;   // 1800s = 30min, même référence que checkHalfTimeReminder()
    if(!safeConfirm(`Revenir à la mi-temps 1 ?\n\nLe chrono va reprendre à ${fmtTime(restoreTime)} et rester en pause.`)) return;
    stopTimer();                 // running=false, garanti avant de fixer le temps restauré
    S.period=1;
    S.time=restoreTime;
    S.tmLastAlert=0; S.halfTimeLastAlert=0;
    upsertMatchSnapshot();
    showToast(`↩ Retour à la mi-temps 1 — chrono en pause à ${fmtTime(restoreTime)}`);
    R();
  }
}
```

Binding (remplace la ligne 4981) :
```javascript
const pb=document.getElementById("per-btn"); if(pb) pb.onclick=switchPeriod;
```
Aucun changement ailleurs : les deux emplacements de rendu de `per-btn` (ligne 2343 et ligne 2470, desktop/paysage vs vue compacte) partagent déjà le même `id="per-btn"` et sont re-bindés après chaque `R()` par la même fonction de bind — `switchPeriod()` s'applique donc uniformément aux deux, sans duplication.

## Pourquoi (alternatives considérées et rejetées)
- **Stocker un `S.mt1EndTime` dédié, mis à jour à chaque tag** (rejeté) : ajoute un point d'écriture supplémentaire à synchroniser sur chaque événement (local + Supabase), pour un résultat strictement équivalent à relire simplement le dernier événement `period===1` déjà présent dans `S.events` au moment du switch. `S.events` est déjà la source de vérité pour "le dernier tag" ailleurs dans le code (ex. `S.events[0]` utilisé directement à plusieurs endroits) — pas besoin d'un nouveau champ dérivé qui pourrait diverger.
- **Redémarrer automatiquement le chrono après un retour confirmé vers MT1** (rejeté, cf. question en suspens du Brief) : Romain n'a explicitement demandé le redémarrage automatique que pour le sens MT1→MT2 ("se met en route"). Le sens MT2→MT1 est par nature une correction d'un clic accidentel — redémarrer automatiquement le chrono à ce moment-là risquerait de faire courir le temps de jeu pendant que l'utilisateur réoriente son geste suivant (reprendre le TM ? re-sélectionner une action ?). Laisser le chrono en pause et redonner la main au bouton ▶ existant est plus sûr et strictement suffisant par rapport à la demande.
- **`window.confirm()` unique avec un message paramétré selon le sens** (rejeté au profit de deux blocs `if/else` distincts) : les deux messages ont un contenu, un temps affiché et des effets de bord différents (reset+start vs restore+stop+alerte gardien) ; une fonction générique paramétrée serait plus courte mais moins lisible, alors que cette fonction n'est appelée qu'à un seul endroit (pas de bénéfice de factorisation réel).
- **Détection automatique du changement de gardien (comparer `gkId` avant/après)** (rejeté, cf. PRD Hors scope) : nécessiterait de capturer un snapshot des `gkId` au moment du switch et de le comparer après une éventuelle ré-sélection manuelle — complexité disproportionnée par rapport à la demande réelle de Romain, qui est un simple rappel humain, pas une vérification technique.

## Impact sur l'existant — vérifié dans le code, pas supposé
- `recordTM()` : seul changement, l'ajout d'un `stopTimer()`. Les deux blocs de garde existants (`S.readOnly`, limite de TM pour l'équipe `home`) restent identiques et s'exécutent avant — un TM refusé (plus de TM dispo) ne touche jamais le chrono, comportement inchangé.
- `per-btn` : le handler actuel fait déjà `S.tmLastAlert=0;S.halfTimeLastAlert=0;upsertMatchSnapshot();` de façon inconditionnelle — `switchPeriod()` conserve ce même reset des deux compteurs anti-spam dans les deux branches, rien ne change sur ce point précis.
- `S.tmUsed` (compteur de temps morts par mi-temps) : jamais touché par `switchPeriod()` — un aller-retour MT1↔MT2 ne remet à zéro ni ne recompte les temps morts déjà consommés, cf. critère d'acceptation du PRD.
- Synchronisation Supabase (`upsertMatchSnapshot()`) : chaque branche pousse l'état final (period+time) vers `matches`, exactement comme le faisait déjà le handler d'origine — aucun nouveau risque de désynchronisation multi-appareil introduit, le mécanisme réutilisé est celui déjà en production depuis STORY-10/13.
- Mode Simple **et** Expert : le timer et `per-btn` vivent tous deux dans `.ml-left`, partagé sans variation entre les deux modes (confirmé dans `CLAUDE.md`, section Mode Simple : ".ml-left ... est entièrement réutilisé sans changement") — `switchPeriod()` s'applique donc identiquement aux deux modes sans code conditionnel supplémentaire.
- Mode lecteur (`S.readOnly`) : les deux fonctions modifiées commencent déjà par `if(S.readOnly) return;` — convention documentée dans `CLAUDE.md` ("Conventions de code"), respectée sans changement.

## Nouvelles structures de données
Aucune. `S.period`, `S.time`, `S.running`, `S.events`, `S.tmUsed`, `S.tmLastAlert`, `S.halfTimeLastAlert` existent tous déjà.

## Nouvelles fonctions/modules
- `switchPeriod()` — remplace le handler anonyme inline de `per-btn`, seule nouvelle fonction nommée de cette feature.
- Aucune autre — `recordTM()` est modifiée en place, pas remplacée.

## Risques
Détaillés par le Risk Analyst (`docs/risks/chrono-mi-temps.md`).

## Critère de bascule
Si une future demande ajoute un 3e état de mi-temps (ex : prolongations) ou une logique de restauration différente par sens, le `if(wasP1){...}else{...}` de `switchPeriod()` devra être remplacé par une machine à états explicite (table de transitions period→period avec message/effet par transition) plutôt qu'un branchement binaire. Pas nécessaire aujourd'hui — le handball se joue en 2 mi-temps, pas de 3e cas d'usage réel à anticiper.
