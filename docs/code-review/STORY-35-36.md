# Code Review — STORY-35 : Onglet Analyse et notes coach éditables depuis Bilan / STORY-36 : Raccourci PDF depuis Bilan (avec correctif P0 Realtime)

## Second passage (2026-08-10) — vérification du correctif du point Bloquant

**Correctif appliqué et confirmé conforme.** `app.js`, handler `oninput` de `#bilan-coach-notes`, désormais l.4029-4042 (décalage de +4 lignes dû à l'ajout ; toujours dans `bind()`, même bloc) :

```js
const bcn=document.getElementById("bilan-coach-notes");
if(bcn) bcn.oninput=()=>{
  if(S.readOnly) return;
  S.bilanNotesDraft=bcn.value;
  const dirty = S.bilanNotesDraft !== (S.bilanMatch?.coachNotes||"");
  bcn.style.borderColor = dirty ? "rgba(240,199,94,.45)" : "var(--border)";
  const chip=document.querySelector(".bilan-dirty-chip");
  if(chip){
    chip.classList.toggle("saved", false);
    chip.style.display = dirty ? "" : "none";
    chip.querySelector("span:last-child").textContent="Non sauvegardé";
  }
};
```

La ligne ajoutée (`chip.querySelector("span:last-child").textContent="Non sauvegardé";`) réinitialise bien le libellé à chaque frappe, en plus de la classe `.saved` et du `display` déjà gérés avant. Vérifications faites :

- **Sélecteur `span:last-child` valide et sans ambiguïté.** Markup du chip (`renderBilanAnalyse()`, l.3602, inchangé) : `<span class="bilan-dirty-chip" ...><span class="dot"></span><span>Non sauvegardé</span></span>`. Le second `<span>` (le texte) est bien le dernier enfant du chip — `span:last-child` cible exactement ce nœud, jamais `.dot`. Même sélecteur déjà utilisé par le handler `onclick` du bouton Sauvegarder (l.4050) pour écrire `"✓ Sauvegardé"` — cohérence de style au sein du même bloc.
- **Cohérence avec le texte initial du markup.** `renderBilanAnalyse()` (l.3602) pose `"Non sauvegardé"` comme texte statique du chip au premier rendu (le chip n'est alors visible que si `dirty` est déjà vrai, ex. brouillon restauré depuis `S.bilanNotesDraft` après navigation). Le texte écrit par le correctif est **identique caractère pour caractère** à ce texte initial — aucune divergence possible entre l'état "post-`R()`" et l'état "post-frappe sans `R()`".
- **Cohérence avec le CSS.** `style.css` l.746-755 : `.bilan-dirty-chip` (sans `.saved`) est stylée jaune (`var(--yellow)`), `.bilan-dirty-chip.saved` est stylée verte (`var(--gk-goal)`). Le correctif retire `.saved` avant de réécrire le texte — couleur et libellé redeviennent synchrones (jaune + "Non sauvegardé"), plus de signal contradictoire.
- **Test réel confirmé** (rapporté par le Developer, CDP) : frappe → sauvegarde (chip vert "✓ Sauvegardé") → reprise de la frappe → chip repasse jaune "Non sauvegardé". Cohérent avec la lecture du code.
- **Aucune régression détectée sur le reste du bloc** : le handler `onclick` de sauvegarde (l.4043-4052), le sélecteur de match (l.4014-4028) et l'extraction/export (l.4053+) sont inchangés par ce correctif — décalage de lignes uniquement dû à l'insertion, aucune ligne existante modifiée par ailleurs (confirmé via `git diff -- app.js` : les 4 lignes ajoutées apparaissent comme un bloc `+` pur, sans `-` correspondant).

**Point additionnel trouvé en re-vérifiant ce même bloc** (ne remet pas en cause le correctif, classé Recommandé ci-dessous, section mise à jour) : le `setTimeout` de masquage automatique du chip après sauvegarde (l.4051) n'est pas annulé si l'utilisateur retape avant son échéance — voir point Recommandé 3.

## Périmètre revu

Diff `git diff` (working tree, non commité) sur `app.js` (+560/-92) et `style.css` (+135/-…) — dernier commit sur ces fichiers `8ff180b` (sans rapport avec ces deux stories).

**Point de contexte important** : ce diff working-tree contient **deux chantiers mélangés** — STORY-32/33/34 (encart pénalty) et STORY-35/36 (Analyse/notes coach Bilan + raccourci PDF). Le premier a déjà fait l'objet d'une revue séparée et approuvée (`docs/code-review/STORY-32-33-34.md`, verdict **APPROUVÉ**). Cette revue-ci ne traite que le second — j'ai isolé chaque hunk du diff pour confirmer qu'aucune ligne touchant STORY-35/36 ne déborde sur le périmètre pénalty et inversement (vérifié via `git diff -U0` + inspection des en-têtes `@@`, cf. détail plus bas). Zéro fichier hors périmètre (seuls `app.js`/`style.css` modifiés, conforme à la convention `CLAUDE.md`).

`new Function()` sur `app.js` complet : **aucune erreur de syntaxe** (vérifié via Node, `new Function(source)`).

Fonctions STORY-35/36 confirmées et leurs lignes actuelles dans le fichier :
- `loadMatchAsCurrent(id, opts)` — l.1464-1497
- `periodScoreOfMatch(m, side, per)` — l.3270-3272
- `matchAnalysis(m)` — l.3276-3367
- `matchExportText(m)` — l.3370-3410
- `saveBilanNotes()` — l.3415-3424
- `renderBilanMatchSelector()` — l.3426-3440
- `renderBilanArchivedBanner(m)` — l.3442-3444
- `renderBilanMatch(m)` — l.3446-3582
- `renderBilanAnalyse(m)` — l.3584-3616
- `renderBilanPdf(m)` — l.3618-3624
- `renderBilan()` — l.3859-3886
- `bind()` (ajouts Bilan) — l.4013-4056, l.4297-4302

---

## 1. Isolation stricte — critère le plus important de STORY-35

**Conforme.** Recherche textuelle explicite (`awk` sur les plages exactes des corps de fonction + `grep`) de `S.events`, `S.home`, `S.away`, `S.coachNotes` dans `periodScoreOfMatch` (l.3270-3272), `matchAnalysis` (l.3276-3367) et `matchExportText` (l.3370-3410) :

```
$ awk 'NR==3270,NR==3410' app.js | grep -nE 'S\.events|S\.home|S\.away|S\.coachNotes'
100:// Jumeau scoped-match de generateExportText() (STORY-35) — utilise m.coachNotes, jamais S.coachNotes
```

Seule occurrence : un commentaire (l.3369) qui *mentionne* `S.coachNotes` en toutes lettres pour documenter que la fonction ne l'utilise justement pas — zéro occurrence dans du code exécutable. Les trois fonctions lisent exclusivement `m.events`/`m.home`/`m.away`/`m.coachNotes`/`matchStats(m)`/`periodScoreOfMatch(m,...)`. Vérifié en bonus (non demandé mais nécessaire pour garantir la chaîne complète) que `matchStats(m)` elle-même (l.3243-3268, pré-existante, non modifiée) ne contient aucune occurrence de ces quatre tokens — la garantie d'isolation tient donc de bout en bout jusqu'aux données brutes.

## 2. Zéro ligne modifiée dans les fonctions protégées

**Conforme.** Recherché individuellement dans le diff (`git diff app.js | grep`) les signatures de `teamScore`, `teamStat`, `teamPoss`, `periodScore(`, `countType`, `gkStats(`, `gkStatsCombined`, `matchStats(`, `dbSaveMatch`, `autoAnalysis`, `generateExportText`, `renderAnalyse(` : aucune ne remonte de hunk de modification. La seule apparition est `matchStats(m){` comme ligne de **contexte** d'un en-tête de hunk (`@@ -3132,28 +3266,185 @@ function matchStats(m){`) — c'est-à-dire que git l'utilise comme repère de proximité pour le hunk suivant (l'ajout de `periodScoreOfMatch`/`matchAnalysis` juste après), pas une modification de son corps. Confirmé par lecture directe : le corps de `matchStats(m)` (l.3243-3268) est identique de part et d'autre du hunk.

Confirmé aussi via la liste complète des en-têtes de hunks (`git diff -U0 app.js | grep '^@@'`) : la zone `autoAnalysis()`/`generateExportText()`/`renderAnalyse()` (l.2674-2860 environ) ne reçoit **aucun** hunk — le diff saute directement de `renderMatch()` (~l.1973) à `renderGkSheet()` (~l.3172), laissant cette plage entièrement intacte.

## 3. Re-dérivation de `S.bilanMatch` dans `renderBilan()`

**Conforme.** `app.js` l.3876 :
```js
const m = S.bilanMatch = S.matchHistory.find(x=>x.id===S.bilanMatchId)||null;
```
Placée en tête de `renderBilan()`, avant toute lecture de `m`, exécutée à **chaque** appel de la fonction (donc à chaque `R()`, pas seulement au changement de sélection). Le nav header (`[data-v]`, l.3966-3969) confirmé faisant bien `S.matchHistory=await dbGetAll()` à chaque clic vers `"history"`/`"bilan"`, remplaçant les instances d'objets. Comme `bind()` ne touche jamais `S.bilanNotesDraft` lors de cette navigation, le scénario Bilan → (Matchs/Stats) → retour Bilan sans re-sélection restaure bien la bonne note (protège le risque #3 du Risk Analyst tel que documenté).

## 4. `saveBilanNotes()` — objet complet, jamais partiel

**Conforme.** `app.js` l.3415-3424 :
```js
async function saveBilanNotes(){
  if(S.readOnly) return;
  const m = S.bilanMatch; if(!m) return;
  m.coachNotes = S.bilanNotesDraft!==null ? S.bilanNotesDraft : (m.coachNotes||"");
  try{
    await dbSaveMatch(m);
    ...
```
`m` est la référence directe obtenue via `S.matchHistory.find(...)` (posée par `renderBilan()`, point 3) — un seul champ (`coachNotes`) est muté sur cet objet, puis l'objet **entier** est passé à `dbSaveMatch(m)`. Aucune reconstruction `{id:..., coachNotes:...}` nulle part. Confirmé que `dbSaveMatch()` (l.458-466, non modifiée) fait un `objectStore(STORE).put(match)` — remplacement intégral de l'enregistrement IndexedDB par clé `id` — donc la garantie "seul `coachNotes` change, tout le reste survit" est structurellement vraie, pas juste par convention.

## 5. Handler `oninput` de `#bilan-coach-notes` — jamais de `R()`

**Conforme pour la partie demandée.** `app.js` l.4030-4038 :
```js
const bcn=document.getElementById("bilan-coach-notes");
if(bcn) bcn.oninput=()=>{
  if(S.readOnly) return;
  S.bilanNotesDraft=bcn.value;
  const dirty = S.bilanNotesDraft !== (S.bilanMatch?.coachNotes||"");
  bcn.style.borderColor = dirty ? "rgba(240,199,94,.45)" : "var(--border)";
  const chip=document.querySelector(".bilan-dirty-chip");
  if(chip){ chip.classList.toggle("saved", false); chip.style.display = dirty ? "" : "none"; }
};
```
Aucun appel à `R()` — uniquement `S.bilanNotesDraft` (état) + manipulation DOM directe (bordure de la textarea, classe/`display` du chip). Focus/curseur préservés à chaque frappe. **Mais voir le point Bloquant ci-dessous** : cette manipulation DOM directe est incomplète (le texte du chip n'est pas remis à jour), un défaut découvert en creusant ce même bloc.

## 6. [P0] `loadMatchAsCurrent()` — ordre `S.currentMatchId=null`/`unsubscribeMatchEvents()` avant tout reset, pour les deux points d'entrée

**Conforme, vérifié à la ligne près.** `app.js` l.1464-1497 :
```js
function loadMatchAsCurrent(id, opts={}){
  if(S.readOnly) return false;
  const m=S.matchHistory.find(x=>x.id===id); if(!m) return false;
  let msg = ...
  if(!safeConfirm(msg)) return false;

  S.currentMatchId = null;        // l.1477
  unsubscribeMatchEvents();       // l.1478

  S.home={...m.home, ...};        // l.1480 — premier champ du match archivé écrit APRÈS
  S.away={...m.away, ...};
  S.events=(m.events||[]).map(...);
  ...
```
Les deux lignes P0 (l.1477-1478) précèdent bien toute écriture de `S.home`/`S.away`/`S.events` (l.1480+). Vérifié que `unsubscribeMatchEvents()` (l.429-434, non modifiée) fait un vrai `client.removeChannel(realtimeChannel)` — le canal Realtime est physiquement fermé, pas seulement marqué inactif, donc aucun callback `mergeRemoteEvent`/`mergeRemoteMatchSnapshot` ne peut plus jamais se déclencher pour l'ancien match après ce point. Vérifié aussi que `upsertMatchSnapshot()` (l.253-255) garde `if(!client||!S.currentMatchId) return;` en tête — avec `S.currentMatchId=null`, toute tentative de push Supabase pendant que le match archivé est affiché est un no-op immédiat, jusqu'à ce qu'un nouvel id soit régénéré à la volée par `queueEventForSync()` (l.271-274) sur un **nouvel** événement — jamais de collision avec l'ancien matchId du vrai match en cours.

Les deux points d'entrée (`bind()`, l.4297-4302) délèguent bien à la même fonction :
```js
document.querySelectorAll("[data-load-match]").forEach(el=>{
  el.onclick=()=>{ loadMatchAsCurrent(parseInt(el.dataset.loadMatch)); };
});
document.querySelectorAll("[data-load-match-pdf]").forEach(el=>{
  el.onclick=()=>{ loadMatchAsCurrent(parseInt(el.dataset.loadMatchPdf), {gotoView:"stats", gotoStatsTab:"pdf", confirmContext:"pdf-bilan"}); };
});
```
Confirmé dans le diff que l'ancien handler inline `[data-load-match]` (qui ne faisait ni l'un ni l'autre — vérifié dans les lignes supprimées du diff, aucune trace de `currentMatchId`/`unsubscribe` dans l'ancien code) a été intégralement remplacé par cette délégation — le bouton "📂 Charger" de l'Historique bénéficie donc bien du correctif, pas seulement le nouveau bouton PDF.

## 7. Texte de confirmation quantifié — seulement pour `confirmContext==="pdf-bilan"` avec événements

**Conforme.** `app.js` l.1468-1471 :
```js
let msg = `Charger ${m.home?.name} vs ${m.away?.name} (${m.journee||""}) ?\nLe match en cours sera remplacé.`;
if(opts.confirmContext==="pdf-bilan" && S.events.length>0){
  msg = `⚠️ Vous avez un match EN COURS avec ${S.events.length} événement(s) non sauvegardé(s)...`;
}
```
Le bouton "📂 Charger" de l'Historique (l.4298) appelle `loadMatchAsCurrent(parseInt(el.dataset.loadMatch))` **sans** second argument — `opts={}` par défaut, `opts.confirmContext` est `undefined`, jamais `"pdf-bilan"` — donc toujours le texte générique non quantifié, quel que soit `S.events.length`. Comportement UI strictement inchangé pour ce bouton, confirmé par le diff : l'ancien texte de confirmation inline était mot pour mot identique à celui produit par la branche par défaut de `loadMatchAsCurrent()`.

## 8. `generatePDF()` ni modifiée ni appelée par `loadMatchAsCurrent()`

**Conforme.** `git diff app.js | grep generatePDF` ne retourne aucune ligne — la fonction n'apparaît nulle part dans le diff, donc ni son corps ni ses appelants n'ont changé. `loadMatchAsCurrent()` se contente de `S.view = opts.gotoView || "match"; if(opts.gotoStatsTab) S.statsTab = opts.gotoStatsTab;` (l.1493-1494) — navigation pure, aucun appel direct à `generatePDF()`. L'utilisateur atterrit sur Stats → PDF déjà existant et doit cliquer sur le bouton de génération lui-même (`#gen-pdf-btn`, binding inchangé l.4010-4011).

## 9. Mode lecteur — garde `if(S.readOnly) return;` en tête

**Conforme aux 3 emplacements demandés :**
- `saveBilanNotes()` l.3416 : `if(S.readOnly) return;` — première ligne.
- Handler `oninput` de `#bilan-coach-notes` l.4032 : `if(S.readOnly) return;` — première ligne du callback (bloque bien la mise à jour de `S.bilanNotesDraft`, pas seulement la persistance, conforme à l'AC16).
- `loadMatchAsCurrent()` l.1465 : `if(S.readOnly) return false;` — première ligne, couvre donc aussi le bouton PDF de Bilan (AC13 STORY-36) sans garde dupliquée.

`.is-disabled` appliquée conditionnellement sur la textarea (l.3604) et le bouton Sauvegarder (l.3608) via `class="${S.readOnly?"is-disabled":""}"` — première application réelle de cette classe existante, conforme à la spec.

---

## Vérifications complémentaires (hors les 9 points, jugées nécessaires)

- **Ordre des onglets Bilan** (`renderBilan()`, l.3860) : `Match/Analyse/PDF/Saison` — conforme à STORY-35 (Analyse insérée entre Match et Saison) puis STORY-36 (PDF inséré entre Analyse et Saison).
- **Bandeau "MATCH ARCHIVÉ" partagé** : posé une seule fois (l.3881) avant les branches `match`/`analyse`/`pdf`, jamais sur `saison` (return anticipé l.3865) ni sur le placeholder vide (return anticipé l.3878) — conforme AC18/AC10(36).
- **Sélecteur `renderBilanMatchSelector()`** : diff confirme que la boucle `${matches.map(...)}` générant les `<option>` est **strictement identique** avant/après extraction (seule différence : ajout de `class="bilan-match-select"` sur le `<select>`, explicitement demandé par AC19) — pas de régression sur le binding existant.
- **`matchExportText(m)` bien câblée au bouton d'export** (`#export-bilan-analyse`, l.4049-4056) : utilise `matchExportText(m)` où `m=S.bilanMatch`, jamais le match en cours.
- **`choosePenOutcome`/`closePenPanel`/`renderShotCourt`/`renderPenaltyPanel`/etc.** (hunks pénalty STORY-32/33/34 mélangés dans le même diff) : confirmés hors du périmètre de cette revue et déjà couverts par `docs/code-review/STORY-32-33-34.md` (APPROUVÉ) — aucun chevauchement avec les fonctions/fichiers listés aux points 1 et 2 ci-dessus.

---

## Bloquant

*(Aucun point bloquant restant — voir "Second passage" en tête de document. Le point 1 ci-dessous est conservé tel quel à titre d'historique, avec son statut mis à jour.)*

### 1. [RÉSOLU — 2026-08-10] Le texte du chip `.bilan-dirty-chip` reste bloqué sur "✓ Sauvegardé" si l'utilisateur retape après une sauvegarde — état visuel incohérent

**Fichier** : `app.js`, handlers `bind()` l.4030-4048.

Le handler `oninput` (l.4031-4038) ne fait que basculer la classe `.saved` et le `display` du chip :
```js
if(chip){ chip.classList.toggle("saved", false); chip.style.display = dirty ? "" : "none"; }
```
Il ne touche **jamais** au texte du chip. Or le handler `onclick` du bouton Sauvegarder (l.4046) réécrit ce texte en dur :
```js
chip.querySelector("span:last-child").textContent="✓ Sauvegardé";
```
et rien nulle part ne le remet à `"Non sauvegardé"` en dehors d'un `R()` complet (qui régénère le template statique de `renderBilanAnalyse()`).

**Scénario concret** :
1. Le coach tape une note → chip "● Non sauvegardé" (jaune), correct.
2. Il clique "💾 Sauvegarder notes" → sauvegarde réelle OK, chip passe à "✓ Sauvegardé" (vert), texte réécrit en dur par le handler.
3. Avant (ou après) la disparition du chip au bout de 1.4s, il continue à taper dans la textarea (cas très plausible : sauvegarder un brouillon puis continuer à rédiger).
4. `oninput` se déclenche : `dirty` redevient `true`, la classe `.saved` est retirée (le chip repasse à son style par défaut jaune/"non sauvegardé"), le chip redevient visible — **mais son texte affiche toujours "✓ Sauvegardé"**, jamais remis à "Non sauvegardé".
5. Résultat affiché à l'écran : un chip à la coloration "non sauvegardé" (jaune) portant le texte "✓ Sauvegardé" — signal contradictoire, exactement le genre d'indicateur d'état que l'AC13 vise à rendre fiable ("L'indicateur non sauvegardé... apparaît dès la première frappe qui rend la note différente de m.coachNotes"). Ici il apparaît bien, mais avec le mauvais libellé.

Persiste jusqu'au prochain `R()` complet (changement de match, d'onglet, etc.).

**Correctif suggéré** (minimal, cohérent avec le style existant) : dans le handler `oninput`, quand on retire la classe `.saved`, réinitialiser aussi le texte :
```js
if(chip){
  chip.classList.toggle("saved", false);
  chip.style.display = dirty ? "" : "none";
  const lbl=chip.querySelector("span:last-child"); if(lbl) lbl.textContent="Non sauvegardé";
}
```

---

## Recommandé (non-bloquant)

1. **Commentaire d'état `bilanTab` incomplet.** `app.js` l.71 : `bilanTab:"match", // match | analyse | saison` — la liste ne mentionne pas `"pdf"`, ajouté par STORY-36. Purement documentaire, sans impact fonctionnel, mais un futur lecteur du code pourrait croire que `"pdf"` n'est pas une valeur valide. **Toujours présent** (revérifié au second passage, l.71 inchangée).
2. **`sw.js` pas encore incrémenté pour ce lot.** `CACHE_NAME` est toujours à `fenix-stats-v78` — conforme à l'étape 2 du processus de déploiement (`CLAUDE.md`), à faire avant le commit/push final de l'ensemble du lot actuellement non commité (STORY-32/33/34 + STORY-35/36 réunis). Rien à corriger dans le code lui-même, simple rappel de checklist avant mise en production. **Toujours présent** (revérifié au second passage, `sw.js` l.1 inchangée).
3. **[Nouveau, trouvé au second passage] Course entre le `setTimeout` de masquage auto du chip et une reprise de frappe rapide après sauvegarde.** `app.js`, handler `onclick` de `#save-bilan-coach-notes`, l.4051 :
   ```js
   setTimeout(()=>{ const c=document.querySelector(".bilan-dirty-chip"); if(c) c.style.display="none"; }, 1400);
   ```
   Ce timer masque le chip **inconditionnellement** 1.4s après un clic sur "Sauvegarder", sans vérifier l'état `dirty` au moment où il se déclenche, et sans être annulé si un nouvel événement `oninput` survient entre-temps.

   **Scénario concret** : le coach sauvegarde (chip vert "✓ Sauvegardé"), puis reprend la frappe dans la foulée (cas plausible : sauvegarder un brouillon puis continuer à rédiger). `oninput` remet immédiatement le chip en jaune "Non sauvegardé" (correctif du point 1 ci-dessus, qui fonctionne bien à cet instant précis) — mais si l'utilisateur n'appuie plus aucune touche après cela, le `setTimeout` posé au clic sauvegarde arrive quand même à échéance à T+1.4s et force `display:"none"`, faisant **disparaître** l'indicateur alors que la note est réellement non sauvegardée. Le chip ne réapparaît qu'à la prochaine frappe (ou jamais, si l'utilisateur change d'onglet/de match sans retaper) — c'est justement cet indicateur qui est censé prévenir la perte de données non sauvegardées.

   Ce n'est pas une régression introduite par le correctif du point 1 (le `setTimeout` existait déjà tel quel avant, à l'identique) et ce n'est pas ce qui était demandé à corriger ici — mais la story entière est encore non commitée à ce stade, donc signalé maintenant plutôt que de laisser passer une seconde fois. Correctif suggéré (à la discrétion du Developer, pas urgent au point de bloquer ce passage) : conserver l'id retourné par `setTimeout` dans une variable accessible aux deux handlers et faire un `clearTimeout` en tête de `oninput`, ou faire vérifier au callback du timer l'état `dirty` courant avant de masquer.

## Sécurité basique

RAS. Aucune clé/secret en dur, aucune nouvelle surface d'entrée non filtrée. `matchAnalysis`/`matchExportText`/`saveBilanNotes`/`loadMatchAsCurrent` opèrent exclusivement sur des données déjà locales (IndexedDB `S.matchHistory`) déjà couvertes par le modèle de sync existant (STORY-12/13/27) — pas de nouvelle table, pas de nouvel appel réseau introduit par ces deux stories. Rien à signaler au Security Auditor.

## Verdict

~~**REJETÉ — à reprendre**~~ *(verdict du premier passage, superseded — voir ci-dessous)*

**APPROUVÉ AVEC RÉSERVES** *(mise à jour 2026-08-10, second passage)*

Les 9 points de vérification demandés restent conformes (inchangé depuis le premier passage), y compris le plus critique (isolation stricte de `matchAnalysis`/`matchExportText`, vérifiée par recherche textuelle réelle — zéro occurrence de `S.events`/`S.home`/`S.away`/`S.coachNotes`) et le correctif P0 Realtime de STORY-36 (`S.currentMatchId=null; unsubscribeMatchEvents();` avant tout reset, pour les deux points d'entrée). Zéro ligne modifiée dans les fonctions protégées, zéro fichier hors périmètre.

Le point Bloquant unique du premier passage (texte du chip `.bilan-dirty-chip` figé sur "✓ Sauvegardé" après reprise de la frappe) est **corrigé et vérifié conforme** : la ligne ajoutée dans le handler `oninput` (`app.js` l.4040) réinitialise le libellé à "Non sauvegardé" en cohérence avec le markup initial (`renderBilanAnalyse()`, l.3602) et le CSS (`style.css` l.746-755). Confirmé par lecture de code (sélecteur, cohérence texte/couleur, absence de régression sur le reste du bloc via `git diff`) et par le test réel CDP rapporté par le Developer. Aucune régression introduite.

En creusant à nouveau ce même bloc pour cette vérification, un second défaut de la même famille (indicateur "non sauvegardé" qui peut disparaître à tort) a été trouvé — voir Recommandé point 3 : le `setTimeout` de masquage auto du chip après sauvegarde n'est pas annulé si l'utilisateur reprend la frappe dans les 1.4s suivant le clic Sauvegarder. Ce défaut est **pré-existant** (présent avant le correctif d'aujourd'hui, non introduit par lui) et n'était pas demandé à corriger dans ce passage — il ne bloque donc pas ce verdict, mais mérite un correctif rapide avant mise en production puisqu'il touche à la même garantie fonctionnelle (fiabilité de l'indicateur de non-sauvegarde) que le point déjà corrigé. Les deux autres Recommandé du premier passage (commentaire `bilanTab` incomplet, `sw.js` non incrémenté) restent également non traités — sans impact bloquant, rappel de checklist avant commit/push final du lot.

**Prêt pour le passage QA.**
