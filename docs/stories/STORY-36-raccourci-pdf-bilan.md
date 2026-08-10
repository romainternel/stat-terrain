# STORY-36 — Raccourci PDF depuis Bilan (avec correctif P0 Realtime)

**En tant que** Romain,
**Je veux** un raccourci depuis Bilan qui charge un match archivé comme match courant puis m'amène directement sur Stats → PDF prêt à générer,
**Afin de** sortir rapidement un PDF d'un vieux match sans naviguer manuellement par l'Historique — **sans jamais risquer de corrompre les données Supabase d'un vrai match en cours affiché sur un autre appareil**, ce que le flux "Charger" actuel ne garantit pas aujourd'hui.

## Contexte

Should Have #10 du PRD (`docs/prd-v7-analyse-pdf-bilan.md`) : réutilise le flux existant "Charger ce match" (`[data-load-match]`, ~3900-3924) — présenté explicitement à Romain comme un pis-aller assumé (pas un PDF archivé sécurisé à froid), zéro duplication de `generatePDF()`.

**Risque P0 non couvert par l'Architecture, trouvé par le Risk Analyst — bloquant pour cette story.** Vérifié dans le code : `newMatch()` (~1394-1411) fait explicitement `S.currentMatchId=null; unsubscribeMatchEvents();` avant tout reset, car changer complètement le contenu de `S` doit couper tout lien avec l'ancien match Supabase. Le handler `[data-load-match]` actuel (et donc la fonction `loadMatchAsCurrent()` que cette story extrait) **ne fait ni l'un ni l'autre**. Si un match est réellement en cours de saisie avec une souscription Realtime active (`S.currentMatchId` non nul, canal `subscribeMatchEvents()` ouvert — cas normal pendant tout match Starligue en direct), charger un match archivé via ce raccourci laisse l'ancien canal actif : `mergeRemoteEvent()`/`mergeRemoteMatchSnapshot()` (~366-399) écrivent sans vérification dans `S.events`/`S.period`/`S.time`/`S.running` dès qu'un événement arrive — qu'il s'agisse toujours du vrai match ou, désormais, du match archivé affiché à l'écran. Pire : toute action qui déclenche `upsertMatchSnapshot()` (sélection GB, bascule mi-temps, chrono...) pendant que le match archivé est affiché écraserait le **vrai match en cours** sur Supabase avec les données périmées du match archivé — visible en temps réel par l'autre appareil, en pleine rencontre. Le raccourci PDF de Bilan est un point d'entrée plus léger que le bouton "📂 Charger" de l'Historique ("juste générer un PDF"), donc plus facile à déclencher par erreur pendant un vrai match en cours — c'est exactement ce qui rend ce correctif non négociable avant de livrer ce Should Have.

## Contexte technique

### `loadMatchAsCurrent(id, opts)` — extraction du handler `[data-load-match]` existant, avec le correctif P0 intégré

```js
function loadMatchAsCurrent(id, opts={}){
  if(S.readOnly) return false;
  const m=S.matchHistory.find(x=>x.id===id); if(!m) return false;

  // Texte de confirmation : quantifié uniquement pour le raccourci PDF de Bilan (risque #2, Risk Analyst)
  // — le bouton "📂 Charger" de l'Historique garde son texte actuel, inchangé.
  let msg = `Charger ${m.home?.name} vs ${m.away?.name} (${m.journee||""}) ?\nLe match en cours sera remplacé.`;
  if(opts.confirmContext==="pdf-bilan" && S.events.length>0){
    msg = `⚠️ Vous avez un match EN COURS avec ${S.events.length} événement(s) non sauvegardé(s).\nLe charger effacera ${S.events.length} action(s) déjà saisies.\nCharger ${m.home?.name} vs ${m.away?.name} (${m.journee||""}) à la place ?`;
  }
  if(!safeConfirm(msg)) return false;

  // ─── P0 — CORRECTIF BLOQUANT (Risk Analyst #1) ───────────────────────────
  // Symétrique à newMatch() (~1408-1409) : couper tout lien avec le match en cours
  // AVANT de charger les données du match archivé, pour les DEUX points d'entrée
  // (bouton "Charger" de l'Historique ET nouveau bouton PDF de Bilan).
  S.currentMatchId = null;
  unsubscribeMatchEvents();
  // ──────────────────────────────────────────────────────────────────────────

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

### `bind()` — deux points d'entrée
```js
document.querySelectorAll("[data-load-match]").forEach(el=>{
  el.onclick=()=>{ loadMatchAsCurrent(parseInt(el.dataset.loadMatch)); };
});
document.querySelectorAll("[data-load-match-pdf]").forEach(el=>{
  el.onclick=()=>{ loadMatchAsCurrent(parseInt(el.dataset.loadMatchPdf), {gotoView:"stats", gotoStatsTab:"pdf", confirmContext:"pdf-bilan"}); };
});
```

### Rendu
- `renderBilanPdf(m)` — nouvelle fonction, carte "zone à risque" (`.card.bilan-pdf-card`, texture rayée orange), note d'avertissement permanente (`.bilan-pdf-warning-note`) affichée **au-dessus** du bouton, bouton `<button class="btn-pdf-warn" data-load-match-pdf="${m.id}">⚠️ Charger ce match & générer son PDF</button>` (spec complète `docs/visual/analyse-pdf-bilan.md` §6).
- `renderBilan()` (déjà restructurée par STORY-35) : ajoute le 4e onglet `{id:"pdf",l:"📄 PDF"}`, inséré entre Analyse et Saison — ordre final `Match/Analyse/PDF/Saison`. Ajoute la branche `if(S.bilanTab==="pdf") html += renderBilanPdf(m);`. Le sélecteur et le bandeau "MATCH ARCHIVÉ" déjà partagés par STORY-35 s'étendent naturellement à cet onglet (aucune modification de `renderBilanMatchSelector()`/`renderBilanArchivedBanner()`).

### CSS à ajouter (`style.css`, spec complète `docs/visual/analyse-pdf-bilan.md` §6)
- `.card.bilan-pdf-card` — texture rayée diagonale orange à opacité `.045`.
- `.btn-pdf-warn` + `.btn-pdf-warn:active` — bordure `2px`, rayures `.16`/`.06`, couleur `var(--orange)` (pas `--gk-off`, cf. §0 du Visual Crafter).
- `.bilan-pdf-warning-note` — bordure gauche `3px solid var(--orange)`, fond `rgba(232,138,78,.06)`.
- Responsive `<700px` : bouton reste pleine largeur, padding/font-size réduits.

## Critères d'acceptation

1. **[P0 — BLOQUANT]** `loadMatchAsCurrent(id, opts)` exécute `S.currentMatchId = null;` et `unsubscribeMatchEvents();` juste après la confirmation acceptée, avant tout reset des données du match archivé (`S.home`/`S.away`/`S.events`/...) — vérifiable par lecture directe du code, symétrique à `newMatch()`.
2. **[P0 — BLOQUANT, scénario réel]** Avec un match réellement en cours de saisie (`S.currentMatchId` non nul, souscription Realtime active — reproductible en test en appelant `subscribeMatchEvents(id)` manuellement puis en déclenchant le raccourci), après chargement d'un match archivé via le bouton PDF de Bilan **ou** via "📂 Charger" de l'Historique : aucun événement reçu ensuite sur l'ancien canal Realtime ne doit plus s'écrire dans `S.events`/`S.period`/`S.time`/`S.running` ; aucune action déclenchant `upsertMatchSnapshot()` (sélection GB, bascule mi-temps, chrono) après le chargement ne doit pousser de données vers l'ancien `matchId` Supabase.
3. Le bouton "📂 Charger" de l'Historique (`data-load-match`) conserve un comportement strictement identique côté UI à avant ce cycle : même texte de confirmation (non quantifié, `opts.confirmContext` absent pour cet appel), même séquence de reset, même navigation finale vers `S.view="match"`. Seule différence, interne et invisible côté UI : il bénéficie désormais aussi du correctif P0.
4. Nouveau bouton "⚠️ Charger ce match & générer son PDF" (`data-load-match-pdf`, classe `.btn-pdf-warn`) visible dans le nouvel onglet "📄 PDF" de Bilan, inséré entre Analyse et Saison dans la barre (ordre final : Match/Analyse/PDF/Saison).
5. Cliquer ce bouton avec `S.events.length>0` côté match en cours : le texte de `safeConfirm()` quantifie explicitement le nombre d'événements qui seraient perdus (ex. *"⚠️ Vous avez un match EN COURS avec {N} événement(s) non sauvegardé(s). Le charger effacera {N} action(s) déjà saisies."*) — jamais uniquement le texte générique "Le match en cours sera remplacé".
6. Cliquer ce bouton avec `S.events.length===0` côté match en cours (aucune saisie active) : le texte de confirmation reste le texte simple existant, sans mention de perte quantifiée (rien à perdre, pas de sur-alerte inutile).
7. Après confirmation acceptée : le match sélectionné est chargé comme match courant (mêmes champs reconstruits que le flux "Charger" actuel) et `S.view` passe à `"stats"` avec `S.statsTab="pdf"` — Stats → PDF s'affiche prêt à générer, sans erreur JS.
8. Annuler la confirmation : aucun changement d'état (`S.home`/`S.away`/`S.events`/`S.currentMatchId` restent ceux du match en cours), aucune navigation, la fonction retourne `false`.
9. Carte "zone à risque" (`.bilan-pdf-card`, texture rayée orange) et note d'avertissement permanente (`.bilan-pdf-warning-note`) affichées **au-dessus** du bouton, visibles sans avoir besoin de déclencher la popup de confirmation.
10. Le bandeau sticky "📁 MATCH ARCHIVÉ — {home} {scoreH}-{scoreA} {away} ({journée})" (STORY-35) est également affiché sur l'onglet PDF dès qu'un match est sélectionné.
11. `generatePDF()` n'est ni modifiée ni appelée directement par ce raccourci — celui-ci navigue seulement vers l'écran Stats → PDF existant, sans invoquer ni dupliquer sa logique.
12. Aucune duplication de la logique de reset de match (~15 lignes) : un seul corps de fonction (`loadMatchAsCurrent`) partagé par les deux boutons (`[data-load-match]` et `[data-load-match-pdf]`).
13. Mode lecteur (`S.readOnly` actif) : le bouton PDF de Bilan est inopérant — garde `if(S.readOnly) return false;` déjà en tête de `loadMatchAsCurrent()`, aucun chargement possible.
14. `new Function()` (ou équivalent) valide `app.js` sans erreur de syntaxe après toutes les modifications.

## Hors scope

- Génération PDF complète pour un match archivé sans passer par le chargement destructif (Nice to Have #12 du PRD — chantier séparé, hors de proportion pour cette version).
- Toute modification du texte de confirmation du bouton "📂 Charger" de l'Historique au-delà du correctif P0 interne (invisible côté UI, reste le texte actuel non quantifié).
- Onglet Analyse / notes coach de Bilan — couvert par STORY-35 (dépendance).
- Toute logique supplémentaire liée à la fraîcheur de `S.bilanMatch` après le retour sur Bilan post-raccourci : déjà couverte par la re-dérivation `m = S.bilanMatch = S.matchHistory.find(...)` ajoutée dans `renderBilan()` par STORY-35 — ce raccourci ne lit ni ne modifie `m.coachNotes`, rien de plus à faire ici.
- Message explicite pour le mode lecteur au-delà de la garde `if(S.readOnly) return false;` existante (optionnel, non bloquant).

## Dépend de

**STORY-35** — nécessite la structure à onglets déjà étendue de `renderBilan()` (sélecteur et bandeau "MATCH ARCHIVÉ" partagés, mécanisme de re-dérivation de `m`) pour y insérer proprement le 4e onglet "PDF" sans dupliquer cette infrastructure.

## Taille

M
