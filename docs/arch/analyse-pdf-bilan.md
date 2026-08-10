# Architecture — Analyse / Notes coach / PDF accessibles depuis Bilan

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v7-analyse-pdf-bilan.md`, `docs/visual/analyse-pdf-bilan.md`*
*Concerne `teamScore`/`teamStat`/`teamPoss` (`app.js` 1007-1015), `periodScore`/`countType` (1890-1893), `gkStats`/`gkStatsCombined` (1016-1052), `matchStats(m)` (3109-3133), `autoAnalysis()` (2540-2632), `generateExportText()` (2634-2672), `renderAnalyse()` (2674-2700), `renderPdfTab()` (2702-2710), `renderBilan()` (3526-3536), `renderBilanMatch()` (3135-3291), `dbSaveMatch()` (448-456), le flux `[data-load-match]` (3901-3924), `generatePDF()` (4025-4429), `R()` (1457-1510), et `bind()` (zones 3626-3672)*

## Décision technique globale

**Jumeau scoped-match, pas de généralisation des helpers existants.** Deux nouvelles fonctions `matchAnalysis(m)` et `matchExportText(m)` sont écrites à côté d'`autoAnalysis()`/`generateExportText()`, sur le modèle exact de `matchStats(m)` — jamais de paramètre `eventsSource` optionnel ajouté à `teamScore`/`teamStat`/`teamPoss`/`periodScore`/`countType`. Deux raisons convergentes, l'une de risque, l'autre de coût :

**1. Le risque de régression sur le match en cours est réel et large, pas théorique.** Ces 5 helpers ne sont pas des fonctions isolées à 2 call sites : ils sont appelés depuis **9 fonctions distinctes** aujourd'hui, dont plusieurs sont au cœur de l'écran Match utilisé en direct pendant un vrai match Starligue :

| Fonction appelante | Ligne | Helpers utilisés | Criticité |
|---|---|---|---|
| `exportMatchCSV()` | ~1169 | `teamScore` | Export CSV, historique |
| `saveMatch()` | ~1351 | `teamScore` | **Sauvegarde du match** — si cassée, plus rien ne se sauvegarde |
| `renderMatch()` | ~1707-1714 | `teamScore`, `periodScore`, `countType`, `gkStats` | **Écran Match en direct** — rendu à chaque frappe |
| `renderScoreboard()` | ~1896-1903 | `periodScore`, `countType`, `gkStats` | Scoreboard (bloc dupliqué de `renderMatch()`, cf. note ci-dessous) |
| `renderStatCompare()` | ~2775-2798 | `teamScore`, `teamStat`, `teamPoss` | Stats → Comparaison, live |
| `autoAnalysis()` | ~2542-2573 | `teamScore`, `teamStat`, `periodScore` | Stats → Analyse, live |
| `generateExportText()` | ~2635-2648 | `teamScore`, `periodScore`, `teamPoss`, `teamStat`, `countType` | Export texte, live |
| `renderGkDetailTables()` | ~2975 | `gkStats` | Stats → Gardiens, live |
| `renderGkSheet()` | ~3002 | `gkStats`, `gkStatsCombined` | Stats → Gardiens, live |
| `generatePDF()` | ~4033-4347 | `teamScore`, `teamStat`, `teamPoss`, `countType`, `periodScore`, `gkStats` | PDF, live |

Toucher la signature de `teamScore`/`teamStat`/`teamPoss`/`periodScore`/`countType` — même avec un paramètre optionnel qui *default* proprement sur `S.events` — veut dire modifier une fonction lue par ces 9 call sites simultanément. Une seule valeur par défaut mal posée (ex. un paramètre placé au mauvais endroit dans la signature, un appel existant qui passe accidentellement un argument supplémentaire réutilisé comme `eventsSource`) casserait silencieusement le scoreboard ou la sauvegarde d'un vrai match en cours de saisie sur le terrain — le pire scénario possible pour cette app. Un jumeau scoped-match, lui, est un **fichier additif** : zéro ligne existante modifiée dans `teamScore`/`teamStat`/`teamPoss`/`periodScore`/`countType`/`gkStats`, donc zéro surface de régression sur les 9 call sites ci-dessus.

**2. Le coût réel du jumeau est plus petit qu'il n'y paraît, une fois `matchStats(m)` pris en compte.** `matchStats(m)` (3109-3133, déjà existant) calcule déjà, par équipe, `goals`/`saves`/`offs`/`turnovers`/`assists`/`freekick`/`twoMin`/`red`/`total`/`poss`/`eff` — et vérification faite ligne par ligne, ces formules sont **identiques** à celles produites par `teamScore`+`teamStat`+`teamPoss`+`countType` pour les besoins du Must Have :
- `ms.home.goals` ≡ `teamScore("home")`
- `ms.home.total`/`ms.home.eff` ≡ exactement le calcul fait inline dans `autoAnalysis()` (`hTotal`/`hEff`)
- `ms.home.turnovers` ≡ `teamStat("home","TURNOVER")`
- `ms.home.assists` ≡ `S.events.filter(e=>e.team==="home"&&e.assistId).length` (formule utilisée telle quelle dans `autoAnalysis()`/`generateExportText()`)
- `ms.home.twoMin`/`ms.home.red` ≡ `countType("home","TWO_MIN")`/`countType("home","RED")`
- `ms.home.poss` ≡ `teamPoss("home")` (même formule : but+arrêt+HC+PB)

Autrement dit : **`matchStats(m)` couvre déjà tout ce dont `matchAnalysis(m)`/`matchExportText(m)` ont besoin en substituts de `teamScore`/`teamStat`/`teamPoss`/`countType`.** Il ne manque qu'une seule chose que `matchStats(m)` ne fournit pas : le score par mi-temps (équivalent de `periodScore(side,per)`). Le jumeau à écrire est donc plus petit que les ~90+40 lignes brutes d'`autoAnalysis()`/`generateExportText()` ne le suggèrent : il s'agit surtout de rebrancher des lectures déjà résolues par `matchStats(m)`, plus **un seul petit helper neuf** pour le score par mi-temps, plus la ré-écriture directe (S→m) des blocs qui lisaient déjà `S.events` en filtre brut (séries de buts encaissés, blocs de 10 minutes, top/flop joueur — ces parties n'appelaient déjà aucun des 5 helpers, donc aucune "généralisation" n'aurait de toute façon aidé pour elles).

`gkStats`/`gkStatsCombined` ne sont **pas concernés** par ce cycle : vérifié dans le code, ni `autoAnalysis()` ni `generateExportText()` ne les appellent (les stats GB détaillées n'apparaissent que dans Stats → Gardiens et dans `generatePDF()`, tous deux hors scope de ce PRD — cf. Nice to Have #12). Aucune fonction gardien n'a besoin d'être dupliquée ni généralisée cette version.

## 1. Nouvelles fonctions de calcul scopées

### 1.a `periodScoreOfMatch(m, side, per)` — le seul petit helper vraiment neuf

```javascript
function periodScoreOfMatch(m, side, per){
  return (m.events||[]).filter(e=>e.team===side && e.period===per && ACTIONS[e.type]?.isGoal).length;
}
```
Miroir exact de `periodScore(side,per)` (1890-1892), avec `m.events` à la place de `S.events`. Point notable : `renderBilanMatch()` calcule déjà ce même score par mi-temps **inline** pour son propre scoreboard (lignes 3162-3165, `const hMT1=(evts.filter(e=>e.team==="home"&&e.period===1&&ACTIONS[e.type]?.isGoal)).length;`). Ce nouveau helper crée donc une 3e occurrence de cette formule (les deux autres : `renderBilanMatch()` inline, et l'usage neuf dans `matchAnalysis(m)`/`matchExportText(m)`). **Recommandation, pas obligation** : le Developer peut, s'il le souhaite, faire pointer les 4 lignes de `renderBilanMatch()` vers `periodScoreOfMatch(m,...)` au lieu de son calcul inline — comportement et sortie strictement identiques, aucun risque, mais je ne le rends pas obligatoire car `renderBilanMatch()` est explicitement protégée par le Hors Scope du PRD ("le comparatif déjà affiché... déjà fonctionnel, non concerné") : je préfère laisser cette petite déduplication au jugement du Developer plutôt que de mandater une modification d'une fonction que le PRD dit explicitement de ne pas retoucher.

### 1.b `matchAnalysis(m)` — jumeau de `autoAnalysis()`

Nom choisi en miroir de `matchStats(m)` (nom+paramètre, pas de suffixe verbeux type `autoAnalysisFor`) — cohérence de nommage avec le seul précédent déjà établi dans ce fichier pour exactement ce genre de dualité.

Structure : copie du corps d'`autoAnalysis()` (2540-2632) avec les substitutions suivantes, ligne par ligne :
- `const ms = matchStats(m);` en tête — remplace tous les couples `teamScore`/`teamStat` par `ms.home.X`/`ms.away.X` (goals, total, eff, turnovers déjà calculés).
- `S.events` → `m.events` **partout où c'est un filtre brut** (série de buts encaissés consécutifs, blocs de 10 minutes, comptage top/flop joueur, PD) — ces blocs n'appelaient déjà aucun des 5 helpers, la substitution est mécanique, pas structurelle.
- `periodScore("home",1)` → `periodScoreOfMatch(m,"home",1)` (§1.a) pour les 4 usages mi-temps.
- Aucune lecture de `S` ne doit subsister dans le corps de cette fonction — **critère de revue explicite** pour le Code Reviewer (cf. Risques), puisque c'est exactement le risque central identifié par le PRD ("confusion silencieuse S vs m").
- Signature : `function matchAnalysis(m){ ... return insights; }` — retourne exactement la même forme (`[{icon,text}]`) qu'`autoAnalysis()`, pour que le rendu (§1.d) soit trivial à écrire par simple substitution d'appel.

`autoAnalysis()` elle-même n'est touchée **d'aucune façon** — zéro ligne modifiée, zéro renommage, aucun risque de régression sur Stats → Analyse (Must Have #9).

### 1.c `matchExportText(m)` — jumeau de `generateExportText()`

Même principe : copie de `generateExportText()` (2634-2672), avec `matchAnalysis(m)` appelée en interne (au lieu d'`autoAnalysis()`), `ms=matchStats(m)` réutilisée pour `teamPoss`/`teamStat`/`countType`, `periodScoreOfMatch(m,...)` pour les scores de mi-temps, et **`m.coachNotes`** à la toute fin (pas `S.coachNotes`) — c'est la seule ligne où la différence de source de données a un effet visible dans le texte produit (les notes du match archivé, pas celles du match en cours). Signature : `function matchExportText(m){ ... return txt; }`.

### 1.d `renderBilanAnalyse(m)` — nouvelle fonction de rendu, nom en miroir de `renderBilanMatch()`

```javascript
function renderBilanAnalyse(m){
  const insights = matchAnalysis(m);
  const dirty = S.bilanNotesDraft !== null && S.bilanNotesDraft !== (m.coachNotes||"");
  return `
    <div class="card" style="max-width:600px;margin:10px auto;">
      <div class="card-t">🧠 Analyse automatique</div>
      <div style="display:flex;flex-direction:column;gap:6px;padding:4px 0;">
        ${insights.map(i=>`<div style="...">${i.icon} ${i.text}</div>`).join("")}
      </div>
    </div>
    <div class="card" style="max-width:600px;margin:10px auto;">
      <div class="card-t" style="display:flex;justify-content:space-between;align-items:center;">
        <span>📝 Notes du coach</span>
        ${dirty?`<span class="bilan-dirty-chip"><span class="dot"></span>Non sauvegardé</span>`:`<span class="bilan-dirty-chip saved" id="bilan-dirty-chip" style="display:none;"><span class="dot"></span>Sauvegardé</span>`}
      </div>
      <textarea id="bilan-coach-notes" class="${S.readOnly?"is-disabled":""}"
        style="...; border-color:${dirty?"rgba(240,199,94,.45)":"var(--border)"};">${S.bilanNotesDraft!==null?S.bilanNotesDraft:(m.coachNotes||"")}</textarea>
      <div style="margin-top:8px;text-align:center;">
        <button id="save-bilan-coach-notes" class="btn btn-g ${S.readOnly?"is-disabled":""}">💾 Sauvegarder notes</button>
      </div>
    </div>
    <div class="card" style="max-width:600px;margin:10px auto;">
      <div class="card-t">📤 Exporter pour analyse</div>
      <button id="export-bilan-analyse" class="btn btn-g" style="width:100%;">📋 Copier le résumé d'analyse</button>
    </div>`;
}
```
`renderAnalyse()` (2674-2700) n'est **touchée d'aucune façon** — c'est une fonction sœur nouvelle, pas une modification en place, exactement comme `renderBilanMatch()` est déjà une fonction sœur de l'affichage live. Style de carte/textarea/bouton strictement identique à `renderAnalyse()` (conforme au Visual Crafter §5 — "réutilisation stricte, la distinction se joue ailleurs").

### 1.e `renderBilanPdf(m)` — nouvelle fonction, miroir de `renderPdfTab()`

Carte "zone à risque" avec le bouton `⚠️ Charger ce match & générer son PDF` (`data-load-match-pdf="${m.id}"`, cf. §3), texture/note d'avertissement du Visual Crafter §6. Ne construit **aucune logique PDF** — c'est un pur déclencheur de navigation (§3), pas un jumeau de `generatePDF()`. Conforme au Hors Scope explicite du PRD.

## 2. Isolation stricte — pourquoi passer `m` en paramètre partout, jamais relire `S.bilanMatch` en interne

Décision transversale à toutes les fonctions ci-dessus : **`matchAnalysis(m)`, `matchExportText(m)`, `renderBilanAnalyse(m)`, `renderBilanPdf(m)` et `renderBilanMatch(m)` (modifiée, §3) reçoivent toutes `m` en paramètre explicite — aucune ne relit `S.bilanMatch` elle-même.** C'est plus fort qu'une simple convention de nommage : c'est ce qui rend le risque central du PRD ("confusion silencieuse S vs m") **auditable par simple lecture du code**, pas seulement par test. Un relecteur (Code Reviewer, QA) peut vérifier en quelques secondes qu'aucune de ces 5 fonctions ne contient la chaîne `S.events`, `S.home`, `S.away` ou `S.coachNotes` dans son corps — une garantie structurelle, pas seulement comportementale. `renderBilan()` (§3) est la **seule** fonction qui lit `S.bilanMatch`/`S.bilanMatchId`, et elle le fait une fois, puis transmet `m` explicitement à ses enfants.

## 3. Extension de `renderBilan()` / `renderBilanMatch()` — le sélecteur remonte sans duplication

**Décision : le sélecteur de match, le bandeau "MATCH ARCHIVÉ" et le placeholder "aucun match sélectionné" montent au niveau de `renderBilan()`**, qui les construit une seule fois et les partage entre les 3 onglets Match/Analyse/PDF (jamais sur Saison). `renderBilanMatch()` perd ces trois responsabilités — elle devient une fonction plus courte qui ne fait plus que le corps comparatif (scoreboard + barres + tableaux joueurs + fil du match), reçoit `m` en paramètre au lieu de le lire elle-même sur `S.bilanMatch`.

```javascript
function renderBilan(){
  const tabs=[{id:"match",l:"🔍 Match"},{id:"analyse",l:"🧠 Analyse"},{id:"pdf",l:"📄 PDF"},{id:"saison",l:"🏆 Saison"}];
  let html = `<div class="stats-tabs">${tabs.map(t=>
    `<button class="st-tab ${S.bilanTab===t.id?"on":""}" data-btab="${t.id}">${t.l}</button>`
  ).join("")}</div>`;

  if(S.bilanTab==="saison") return html + renderBilanSaison();

  if(S.matchHistory.length===0){
    return html + `<div class="card"><div class="empty" style="padding:20px;text-align:center;color:var(--t3);">Aucun match sauvegardé</div></div>`;
  }

  html += renderBilanMatchSelector();   // extraction du <select> déjà existant (3141-3151), inchangé visuellement

  const m = S.bilanMatch;
  if(!m){
    return html + `<div class="card"><div class="empty" style="padding:20px;text-align:center;color:var(--t3);">↑ Sélectionne un match pour le revoir</div></div>`;
  }

  html += renderBilanArchivedBanner(m);   // NOUVEAU, Visual Crafter §4 — affiché sur les 3 onglets non-Saison dès qu'un match est sélectionné
  if(S.bilanTab==="match")   html += renderBilanMatch(m);      // signature modifiée : reçoit m, ne construit plus ni sélecteur ni placeholder
  if(S.bilanTab==="analyse") html += renderBilanAnalyse(m);
  if(S.bilanTab==="pdf")     html += renderBilanPdf(m);
  return html;
}
```

**Pourquoi ce découpage évite la duplication à 3 endroits** : avant ce changement, "aucun match dans l'historique" et "aucun match sélectionné" n'existaient que dans `renderBilanMatch()`. Si chacune des 3 fonctions d'onglet (`renderBilanMatch`, `renderBilanAnalyse`, `renderBilanPdf`) réimplémentait ces deux gardes indépendamment, on aurait 3 copies quasi identiques du même texte de placeholder — exactement le genre de divergence que le projet évite déjà ailleurs (`renderShotCourt()` dans `docs/arch/encart-penalty.md` est justifiée par le même principe). En les centralisant dans `renderBilan()`, une seule source de vérité décide "y a-t-il un match sélectionné ?" avant même d'appeler la fonction d'onglet — les 3 fonctions d'onglet peuvent donc supposer `m` toujours non-null en entrée, ce qui simplifie aussi leur code (pas de `if(!m) return ...` à répéter 3 fois).

`renderBilanMatchSelector()` est une extraction pure du `<select id="bilan-match-sel">` déjà existant (3144-3150) — markup byte-pour-byte identique, seule sa position dans le flux change (avant la barre d'onglets visuellement, au niveau de `renderBilan()` structurellement). Le binding existant (`bind()`, 3665-3671, `document.getElementById("bilan-match-sel")`) **fonctionne sans modification** puisqu'il résout l'élément par `id`, pas par position dans l'arbre — seul ajout nécessaire dans ce handler : réinitialiser `S.bilanNotesDraft` au changement de match (§6).

`renderBilanArchivedBanner(m)` est une fonction neuve et courte, pur habillage (Visual Crafter §4) — aucune logique de calcul.

## 4. Persistance des notes — appel exact à `dbSaveMatch(m)`

**Décision : muter `m.coachNotes` en place sur l'objet retourné par `S.bilanMatch` (qui est la même référence que l'entrée correspondante dans `S.matchHistory`), puis appeler `dbSaveMatch(m)` avec cet objet complet — jamais un objet partiel reconstruit à la main.**

```javascript
async function saveBilanNotes(){
  if(S.readOnly) return;
  const m = S.bilanMatch; if(!m) return;
  m.coachNotes = S.bilanNotesDraft!==null ? S.bilanNotesDraft : (m.coachNotes||"");
  try{
    await dbSaveMatch(m);
    showToast("💾 Notes sauvegardées !");
    S.bilanNotesDraft = null;   // repasse "propre" : la valeur affichée retombe sur m.coachNotes, désormais identique
    // mise à jour DOM directe du chip (§6) — pas de R() ici, cf. §6 pour la justification complète
  }catch(e){ safeAlert("Erreur de sauvegarde: "+e.message); }
}
```

**Pourquoi passer `m` tel quel, et pas `{...m, coachNotes:...}` ou un sous-ensemble de champs** : `dbSaveMatch(match)` (448-456) fait un `tx.objectStore(STORE).put(match)` — `put()` d'IndexedDB **remplace l'enregistrement entier** keyé sur `match.id`, ce n'est pas un patch partiel. Vérifié dans `saveMatch()` (1344-1354), l'objet match archivé porte au minimum `id, date, season, journee, home, away, events, time, period, scoreH, scoreA, coachNotes, supabaseMatchId`. Si l'implémentation appelait `dbSaveMatch({id:m.id, coachNotes:newText})` par erreur, **tous les autres champs de ce match seraient silencieusement effacés en base** (l'historique, les événements, les scores — tout, sauf `id` et `coachNotes`) — un risque de perte de données largement pire que le risque de note perdue déjà documenté par le PRD. Muter la propriété `coachNotes` sur l'objet `m` existant (obtenu via `S.matchHistory.find(...)`, jamais une copie) puis le repasser intégralement à `dbSaveMatch(m)` élimine structurellement ce risque : il n'y a qu'un seul objet, jamais reconstruit, donc aucun champ ne peut être oublié.

**Effet de bord positif attendu et voulu** : puisque `S.bilanMatch` et l'entrée dans `S.matchHistory` sont la **même référence objet**, muter `m.coachNotes` met aussi à jour `S.matchHistory` en mémoire immédiatement — c'est exactement ce qui satisfait Must Have #6 ("la note éditée reste visible si on change de match puis revient sur le même, sans re-sélection nécessaire dans la session") sans code supplémentaire : re-sélectionner le même match via le `<select>` refait un `S.matchHistory.find(m=>m.id===id)` qui retrouve le même objet, déjà à jour.

**Aucune évolution de schéma** : `coachNotes` existe déjà sur tout objet match sauvegardé via `saveMatch()` depuis le début (`m.coachNotes||""` déjà utilisé ailleurs, ex. 3912) — confirmé par la Dépendance #8 du PRD.

## 5. Le raccourci PDF — extraction de `loadMatchAsCurrent()`, zéro duplication du flux de chargement

**Décision : extraire le corps du handler `[data-load-match]` (3901-3924) dans une fonction nommée `loadMatchAsCurrent(id, opts)`, appelée par les deux boutons** — l'historique existant ("📂 Charger", inchangé) et le nouveau bouton PDF de Bilan. Pas une simple réutilisation du même attribut `data-load-match` avec un flag caché : le handler actuel se termine par `S.view="match"` codé en dur (3921), or le PRD exige que le raccourci Bilan atterrisse sur `S.view="stats"` + `S.statsTab="pdf"`. Il faut donc un point de variation, proprement paramétré plutôt que dupliqué.

```javascript
function loadMatchAsCurrent(id, opts={}){
  if(S.readOnly) return false;
  const m=S.matchHistory.find(x=>x.id===id); if(!m) return false;
  if(!safeConfirm(`Charger ${m.home?.name} vs ${m.away?.name} (${m.journee||""}) ?\nLe match en cours sera remplacé.`)) return false;
  S.home={...m.home,players:(m.home?.players||[]).map(p=>({...p}))};
  S.away={...m.away,players:(m.away?.players||[]).map(p=>({...p}))};
  S.events=(m.events||[]).map(e=>({...e}));
  S.time=m.time||0; S.period=m.period||1;
  S.season=m.season||S.season; S.journee=m.journee||S.journee;
  S.coachNotes=m.coachNotes||"";
  S.selectedAction=null; S.shotOverlay=null; S.playerSelect=null;
  S.penResultSelect=null; S.pdSelect=false; S.actionPanel=null; S.penMode=false;
  S.gkFilter={home:"all",away:"all"}; S.gkShotFilter={goals:true,saves:true,offs:true};
  S.tmUsed={mt1:0,mt2:0};
  S.events.filter(e=>e.type==="TM"&&e.team==="home").forEach(e=>{
    if((e.period||1)===1) S.tmUsed.mt1++; else S.tmUsed.mt2++;
  });
  S.view = opts.gotoView || "match";
  if(opts.gotoStatsTab) S.statsTab = opts.gotoStatsTab;
  saveTeams(); R();
  return true;
}
```
```javascript
// bind() — inchangé dans son esprit, juste rebranché sur la fonction extraite
document.querySelectorAll("[data-load-match]").forEach(el=>{
  el.onclick=()=>{ loadMatchAsCurrent(parseInt(el.dataset.loadMatch)); };
});
document.querySelectorAll("[data-load-match-pdf]").forEach(el=>{
  el.onclick=()=>{ loadMatchAsCurrent(parseInt(el.dataset.loadMatchPdf), {gotoView:"stats", gotoStatsTab:"pdf"}); };
});
```
Bouton Bilan PDF (§1.e) : `<button class="btn-pdf-warn" data-load-match-pdf="${m.id}">⚠️ Charger ce match & générer son PDF</button>`.

**Garanties** : le bouton "📂 Charger" de l'historique (`data-load-match`) a un comportement **strictement identique** à aujourd'hui — même texte de confirmation, même séquence de reset, même navigation finale vers `"match"` (puisque `opts` est vide pour cet appel, `opts.gotoView||"match"` retombe sur `"match"`). Aucune duplication de la logique de reset (15 lignes) entre les deux boutons — un seul endroit à corriger si un futur champ doit être ajouté au reset. Zéro duplication de `generatePDF()` (exigence explicite du PRD) et, bonus non demandé, zéro duplication du flux de chargement non plus.

## 6. Indicateur "dirty" et confirmation bloquante — `S.bilanNotesDraft`, jamais de `R()` sur la frappe

**Contrainte technique dure, vérifiée dans `R()` (1457-1510)** : chaque appel à `R()` fait un `app.cloneNode(false)` + `replaceChild` — un remplacement complet du DOM de `#app`. Une frappe dans une `<textarea>` qui déclencherait `R()` **perdrait le focus et la position du curseur** à chaque caractère tapé. C'est exactement pourquoi le textarea live de Stats → Analyse ne le fait déjà pas : `cnEl.oninput=()=>{S.coachNotes=cnEl.value;};` (ligne 3640) — **aucun `R()` dans ce handler**. La même contrainte s'applique à l'identique pour la textarea de Bilan : son `oninput` ne doit jamais appeler `R()`.

**Décision : nouvelle clé d'état `S.bilanNotesDraft` (string|null), jamais persistée (ni IndexedDB, ni Supabase), réinitialisée à chaque changement de match sélectionné.**

Pourquoi une clé d'état neuve et pas juste une variable locale au DOM : un second risque, concret et déjà vérifié dans le code, existe indépendamment de la frappe elle-même — l'abonnement Supabase Realtime (`subscribeMatchEvents()`, 401-419) écoute `match_events`/`matches` **indépendamment de la vue actuellement affichée** et déclenche son propre `R()` sur réception. Si Romain édite une note Bilan pendant qu'un événement du match en cours arrive d'un autre appareil (scénario explicitement mentionné par le PRD, Must Have #7 : "un match activement en cours de saisie en parallèle... sur un autre appareil"), un `R()` externe reconstruit tout `#app` — si le contenu tapé n'existait que dans le DOM (valeur de la `<textarea>`), il serait perdu à la prochaine frappe... perdu tout court, en fait, dès ce `R()` externe, puisque la reconstruction HTML relit forcément une source de vérité JS pour remplir `<textarea>...</textarea>`. Stocker le brouillon dans `S.bilanNotesDraft` garantit qu'il survit à n'importe quel `R()` déclenché par un événement extérieur, exactement comme `S.coachNotes` le fait déjà pour le cas live.

```javascript
// bind() — sélecteur de match (3665-3671), un ajout
const bms=document.getElementById("bilan-match-sel");
if(bms) bms.onchange=()=>{
  const newId=parseInt(bms.value)||null;
  const savedNote=S.bilanMatch?.coachNotes||"";
  if(S.bilanNotesDraft!==null && S.bilanNotesDraft!==savedNote){
    if(!safeConfirm("Notes non sauvegardées. Changer de match quand même ?\nVos modifications seront perdues.")){
      bms.value=String(S.bilanMatchId||""); return;   // revert visuel du <select>, aucun changement d'état
    }
  }
  S.bilanMatchId=newId;
  S.bilanMatch=S.matchHistory.find(m=>m.id===newId)||null;
  S.bilanNotesDraft=null;   // reset : la prochaine ouverture de l'onglet Analyse repart de m.coachNotes
  R();
};

// bind() — nouveau, textarea + bouton de l'onglet Analyse Bilan
const bcn=document.getElementById("bilan-coach-notes");
if(bcn) bcn.oninput=()=>{
  if(S.readOnly) return;
  S.bilanNotesDraft=bcn.value;
  const dirty = S.bilanNotesDraft !== (S.bilanMatch?.coachNotes||"");
  bcn.style.borderColor = dirty ? "rgba(240,199,94,.45)" : "var(--border)";
  const chip=document.querySelector(".bilan-dirty-chip");
  if(chip){ chip.classList.toggle("saved", false); chip.style.display = dirty ? "" : "none"; }
  // PAS de R() ici — voir contrainte ci-dessus
};
const sbcn=document.getElementById("save-bilan-coach-notes");
if(sbcn) sbcn.onclick=async()=>{
  if(S.readOnly) return;
  await saveBilanNotes();   // §4
  const bcn2=document.getElementById("bilan-coach-notes");
  if(bcn2) bcn2.style.borderColor="var(--border)";
  const chip=document.querySelector(".bilan-dirty-chip");
  if(chip){ chip.classList.add("saved"); chip.style.display=""; chip.querySelector("span:last-child").textContent="✓ Sauvegardé"; }
  setTimeout(()=>{ const c=document.querySelector(".bilan-dirty-chip"); if(c) c.style.display="none"; }, 1400);
};
```

**Le bouton de sauvegarde, lui, peut se permettre une manipulation DOM directe post-sauvegarde sans `R()` non plus** — cohérent avec le principe "un update DOM ciblé suffit" : la confirmation visuelle (chip "✓ Sauvegardé" pendant 1.4s, cf. Visual Crafter §7.1) n'a pas besoin d'un rendu complet, et l'éviter préserve le focus si Romain retape immédiatement après avoir sauvegardé. Un `R()` complet resterait fonctionnellement correct ici (la sauvegarde n'est pas suivie d'une frappe immédiate dans le même geste), mais la manipulation DOM directe est strictement moins risquée et gratuite à écrire une fois le pattern posé pour `oninput`.

**La popup `safeConfirm()` est native et bloquante** — elle interrompt déjà l'exécution JS le temps que Romain réponde, donc aucun risque de race condition entre le changement de match et la vérification du brouillon : `bms.onchange` s'exécute entièrement (y compris l'attente de la réponse à `safeConfirm`) avant que quoi que ce soit d'autre ne se produise.

## 7. Mode lecteur

Convention du projet (`CLAUDE.md` : "Toute fonction/handler d'écriture... commence par `if(S.readOnly) return;`") appliquée à trois points d'entrée neufs :
- `saveBilanNotes()` (§4) : garde en tête de fonction.
- `bcn.oninput` (§6) : garde en tête de handler — bloque la mise à jour de `S.bilanNotesDraft` elle-même, pas seulement la sauvegarde (cohérent avec Must Have #8 : "l'édition des notes... est bloquée", pas seulement la persistance).
- Markup : `class="${S.readOnly?"is-disabled":""}"` sur la `<textarea>` et le bouton, réutilisant `.is-disabled` (`style.css` ligne 36, `opacity:.35;pointer-events:none`) — **première utilisation réelle de cette classe dans `app.js`** (elle existait déjà, formalisée par STORY-05, mais jamais appliquée faute de cas concret — celui-ci en est un). `pointer-events:none` rend la garde JS redondante en pratique pour cette textarea précise, mais elle reste requise par la convention (robustesse si le CSS venait à changer).

`loadMatchAsCurrent()` (§5) a déjà sa garde `if(S.readOnly) return false;` en tête, héritée telle quelle du handler existant.

## Impact sur l'existant

- `teamScore`, `teamStat`, `teamPoss`, `periodScore`, `countType`, `gkStats`, `gkStatsCombined` : **aucune modification, aucun nouveau paramètre**. Zéro risque sur les 9 call sites recensés en Décision technique globale.
- `autoAnalysis()`, `generateExportText()`, `renderAnalyse()` : **aucune modification**. Stats → Analyse pour le match en cours reste identique en tout point (Must Have #9).
- `matchStats(m)` : **aucune modification** — réutilisée telle quelle par `matchAnalysis(m)`/`matchExportText(m)` comme source de la plupart des agrégats.
- `renderBilanMatch()` : **restructurée**, pas juste retouchée — perd la construction du sélecteur et le double placeholder ("aucun match sauvegardé" / "sélectionne un match"), remontés dans `renderBilan()` (§3). Signature change de `renderBilanMatch()` à `renderBilanMatch(m)`. Le corps comparatif (scoreboard, barres, tableaux joueurs, fil du match) est **inchangé** — conforme au Hors Scope explicite du PRD.
- `renderBilan()` : étendue de 2 à 4 onglets, orchestre désormais le sélecteur/bandeau/placeholder partagés (§3).
- `bind()` : un handler modifié (sélecteur de match, ajout de la vérification dirty-state, §6), deux handlers neufs ajoutés à la suite du bloc "Analyse tab bindings" existant (~3638-3649) et du bloc "History: load/delete" existant (~3901), un handler existant (`[data-load-match]`) rebranché sur la fonction extraite `loadMatchAsCurrent()` sans changement de comportement observable.
- `dbSaveMatch()` : **aucune modification** — appelée telle quelle, avec l'objet match complet (§4).
- `generatePDF()` : **aucune modification, aucun appel depuis Bilan** — le raccourci (§5) navigue vers l'écran PDF existant après chargement, il ne l'invoque ni ne le généralise.
- `style.css` : ajout des classes déjà entièrement spécifiées par le Visual Crafter (`.bilan-match-select`, `.bilan-archived-banner`, `.bilan-dirty-chip`, `.bilan-pdf-card`, `.btn-pdf-warn`, `.bilan-pdf-warning-note`) — uniquement additif, aucune règle existante modifiée. Première application réelle de `.is-disabled` (§7).

## Nouvelles structures de données

- **`S.bilanNotesDraft`** (string|null, défaut `null`) — brouillon de la note en cours d'édition dans Bilan, jamais persisté (ni IndexedDB, ni Supabase, ni `localStorage`). Réinitialisé à `null` à chaque changement de match sélectionné (§6). C'est la seule nouvelle clé d'état de tout ce cycle.
- Aucune évolution de schéma IndexedDB ni Supabase — `coachNotes` existe déjà sur tout match archivé (Dépendance #8 du PRD, confirmé dans le code).

## Nouvelles fonctions / modules

- `periodScoreOfMatch(m, side, per)` — mini-helper scoped-match, seul complément nécessaire à `matchStats(m)` pour couvrir les besoins de `matchAnalysis`/`matchExportText` (§1.a).
- `matchAnalysis(m)` — jumeau scoped-match d'`autoAnalysis()`, réutilise `matchStats(m)` (§1.b).
- `matchExportText(m)` — jumeau scoped-match de `generateExportText()`, appelle `matchAnalysis(m)` en interne (§1.c).
- `renderBilanAnalyse(m)` — rendu de l'onglet Analyse de Bilan (§1.d).
- `renderBilanPdf(m)` — rendu de l'onglet PDF de Bilan, pur déclencheur de navigation (§1.e).
- `renderBilanMatchSelector()` — extraction du `<select>` déjà existant, position seule changée (§3).
- `renderBilanArchivedBanner(m)` — bandeau sticky "MATCH ARCHIVÉ" (§3, Visual Crafter §4).
- `saveBilanNotes()` — écriture réelle via `dbSaveMatch(m)` (§4).
- `loadMatchAsCurrent(id, opts)` — extraction du handler `[data-load-match]` existant, paramétrée pour supporter la navigation post-chargement du raccourci PDF (§5).
- Pas de nouveau fichier JS, pas de découpage d'`app.js` — hors de proportion avec l'ampleur du changement (cf. Critère de bascule).

## Risques (vue technique)

- **Confusion silencieuse S vs m si `matchAnalysis(m)`/`matchExportText(m)` sont écrites par copier-coller sans substitution complète** : le risque central déjà identifié par le PRD/Brief. Le point de vigilance précis pour le Code Reviewer : ces deux fonctions ne doivent contenir **aucune** occurrence de `S.events`, `S.home`, `S.away`, `S.coachNotes` dans leur corps — une simple recherche textuelle suffit à le vérifier, contrairement à un test fonctionnel qui pourrait passer par coïncidence si les deux matchs (en cours et archivé) ont des données similaires au moment du test. **Test QA explicite à prévoir** : match en cours ET match archivé avec des scores différents affichés simultanément (un sur Stats, un sur Bilan, potentiellement sur deux appareils), vérifier que les chiffres ne se mélangent jamais.
- **Perte du brouillon si `S.bilanNotesDraft` n'est pas consulté par le rendu de la textarea** : si `renderBilanAnalyse(m)` affiche `m.coachNotes||""` au lieu de `S.bilanNotesDraft!==null?S.bilanNotesDraft:(m.coachNotes||"")`, un `R()` externe (sync Realtime du match en cours, §6) effacerait silencieusement la frappe en cours. Risque symétrique à celui déjà résolu pour `S.coachNotes` côté live — mais neuf ici, donc à vérifier explicitement en test (taper une note, déclencher un événement sur un autre appareil pendant la frappe, vérifier que le texte tapé ne disparaît pas).
- **`R()` appelé par erreur dans le handler `oninput` de la textarea Bilan** : casserait le focus/curseur à chaque frappe, régression d'usabilité silencieuse (pas une exception, juste un texte qui "saute" visuellement) — à vérifier en test manuel réel (taper une phrase complète sans interruption), pas seulement en lisant le code.
- **`dbSaveMatch(m)` appelé avec un objet reconstruit partiellement plutôt que `m` en entier** (§4) : effacerait silencieusement les autres champs du match en base (événements, effectifs, score) — risque de perte de données réelle, plus grave que la simple "perte d'édition" déjà documentée par le PRD. **Test explicite recommandé au Code Reviewer** : après un `saveBilanNotes()`, relire le match via `dbGetAll()` et vérifier que `events.length` et `scoreH`/`scoreA` sont inchangés, pas seulement que `coachNotes` a la bonne valeur.
- **Confirmation bloquante contournée si le `<select>` change de valeur par un autre chemin que `onchange`** (ex. un futur code qui ferait `bms.value=...` directement puis appellerait `R()` sans repasser par le handler) : aujourd'hui aucun autre chemin n'existe, donc ce risque est théorique — signalé pour un futur mainteneur, pas une lacune actuelle.
- **Divergence multi-appareil des notes** : risque déjà accepté et documenté par le PRD (Décision actée #7) — aucune mitigation technique nouvelle apportée par cette architecture, conforme au scope.
- Aucun risque identifié côté `generatePDF()`/schéma Supabase — ni l'un ni l'autre ne sont touchés par ce cycle.

## Critère de bascule

`app.js` reste un fichier unique. Ce cycle ajoute 8 fonctions (dont 2 très courtes — `periodScoreOfMatch`, `saveBilanNotes` — et 2 extractions pures de code déjà existant — `renderBilanMatchSelector`, `loadMatchAsCurrent`), restructure `renderBilanMatch()` (perte de deux responsabilités, déplacées, pas supprimées) et `renderBilan()` (orchestration à 4 onglets au lieu de 2), et rebranche un seul handler existant sans changer son comportement observable. Aucun changement d'organisation générale du fichier, aucun nouveau module, aucune évolution de schéma de données. Le jour où Bilan accumulerait un 3e ou 4e jumeau scoped-match de ce type (par exemple si le Nice to Have #12 — PDF complet archivé — est un jour repris), ce serait le signal pour se poser la question d'un module dédié `bilan.js` regroupant `matchStats`/`matchAnalysis`/`matchExportText` et leurs futurs jumeaux — pas justifié par cette seule feature, qui n'en ajoute que 2 (`matchAnalysis`, `matchExportText`) à un `matchStats` déjà existant.
