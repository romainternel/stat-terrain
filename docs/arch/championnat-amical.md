# Architecture — Champ Championnat / Amical

## Fichiers touchés
`app.js` uniquement (état initial, UI du badge Match, `bind()`, `saveMatch()`, `renderBilanSaison()`, `renderHistory()`). Migration Supabase déjà livrée avec STORY-48 (`docs/supabase-migration-season-journee-notes.sql`, colonne `championnat` déjà présente). Écriture réseau déjà spécifiée par STORY-48 (`markMatchFinishedById()`, cf. `docs/arch/sync-historique-multi-appareil.md`, section déjà mise à jour pour inclure `championnat` dans le 2e `update()`) — **pas à redéfinir ici**, juste à implémenter au même moment que STORY-48 si les deux sont développées ensemble.

## État initial
```js
// ligne ~54-55, à côté de season/journee
season:"2025-2026",
journee:"J1",
championnat:"N1",
```
**Réinitialisé par `newMatch()`** (~ligne 1455-1469), contrairement à `S.season` — ajouter `S.championnat="N1";` dans cette fonction, au même endroit que `S.journee="J"+(jNum+1);`. Décision du Risk Analyst (cf. `docs/risks/championnat-amical.md` R1) : persister la valeur comme Saison exposerait à un oubli de rebasculer après un match Amical, excluant silencieusement le match suivant (un vrai match de championnat) du bilan de saison.

## UI — badge Match (`.ml-extra`, seul point d'affichage réellement rendu)
**Point de vigilance trouvé en investiguant** : `S.season`/`S.journee` sont dupliqués dans le code à deux endroits (`app.js` ~ligne 1962-1968 dans le layout Expert, et ~ligne 2053-2055 dans `renderScoreboard()`) — mais `renderScoreboard()` **n'est appelée nulle part** (grep confirmé, fonction morte, cohérent avec la note déjà présente dans `CLAUDE.md` sur `renderMiniCompare()`/`renderGkBar()` également mortes). **Seul le bloc `.ml-extra` (~ligne 1962-1968) est réellement affiché** — c'est le seul endroit à modifier ; ne pas perdre de temps à also modifier `renderScoreboard()`, et ne pas la considérer comme une régression si elle n'est pas touchée par cette story (elle ne s'affiche déjà nulle part).

```html
<!-- avant -->
<span id="edit-season">${S.season}</span> · <span id="edit-journee">${S.journee}</span>

<!-- après -->
<span id="edit-season">${S.season}</span> · <span id="edit-journee">${S.journee}</span> ·
<select id="edit-championnat">
  ${["N1","N2","-18","Amical"].map(v=>`<option value="${v}" ${S.championnat===v?"selected":""}>${v}</option>`).join("")}
  ${!["N1","N2","-18","Amical"].includes(S.championnat)?`<option value="${S.championnat}" selected>${S.championnat}</option>`:""}
  <option value="__autre__">Autre…</option>
</select>
```
La branche `!["N1","N2","-18","Amical"].includes(...)` couvre le cas d'une valeur libre déjà choisie (ex: "Coupe de France") — sans elle, rouvrir le `<select>` afficherait "N1" par erreur alors que la vraie valeur est différente (bug de perte d'affichage, pas de perte de donnée — `S.championnat` resterait correct en mémoire, mais le menu mentirait visuellement).

## `bind()` — nouveau gestionnaire
```js
const ec=document.getElementById("edit-championnat");
if(ec) ec.onchange=()=>{
  if(ec.value==="__autre__"){
    const v=prompt("Championnat :",S.championnat);
    if(v!==null) S.championnat=v.trim()||S.championnat;
  } else {
    S.championnat=ec.value;
  }
  R();
};
```

## `saveMatch()` (~ligne 1401-1413)
Ajouter `championnat:S.championnat,` dans l'objet `match` construit — même endroit que `season`/`journee` déjà présents.

## `renderBilanSaison()` (~ligne 3904-3907)
```js
// avant
const matches=S.matchHistory.filter(m=>m.season===season);
// après
const matches=S.matchHistory.filter(m=>m.season===season && m.championnat!=="Amical");
```
Conforme à M6 du PRD : un match sans `championnat` (`undefined`/`""`) passe le test `!=="Amical"` normalement (reste inclus) — seule la valeur exacte `"Amical"` exclut.

## `renderHistory()` (~ligne 4191-4207, la ligne d'un match dans la liste)
Ajouter un badge à côté de Journée, uniquement si `m.championnat` est renseigné :
```js
${m.championnat?`<span class="mono" style="font-size:11px;padding:1px 6px;border-radius:4px;${m.championnat==="Amical"?"color:var(--t3);background:rgba(255,255,255,.05);":"color:var(--t2);background:rgba(255,255,255,.05);"}">${m.championnat}</span>`:""}
```
Placé juste après le badge Journée existant (`<span class="mono" ...>${m.journee||"—"}</span>`), avant le nom d'équipe.

## Aucun changement sur
`resumeMatch()` (ne lit pas `championnat`, un match repris garde `S.championnat` déjà en mémoire sur l'appareil qui reprend — cohérent, ce champ n'a pas besoin d'être resynchronisé pendant qu'un match est en cours, seulement à la sauvegarde comme season/journee), export/import CSV (hors scope, pas de colonne CSV concernée par cette story).
