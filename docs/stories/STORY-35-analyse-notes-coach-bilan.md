# STORY-35 — Onglet Analyse et notes coach éditables depuis Bilan

**En tant que** Romain (ou un aidant occasionnel utilisant l'app),
**Je veux** consulter l'analyse automatique et éditer mes notes de coach pour n'importe quel match archivé, directement depuis Bilan,
**Afin de** pouvoir debriefer un vieux match sans jamais toucher ni risquer d'écraser le match en cours — y compris quand un vrai match est activement en train d'être saisi en parallèle, potentiellement sur un autre appareil.

## Contexte

Le Must Have complet du PRD (`docs/prd-v7-analyse-pdf-bilan.md`, points 1-9). Décision architecturale actée : **jumeau scoped-match** (`matchAnalysis(m)`/`matchExportText(m)`, sur le modèle de `matchStats(m)` déjà existant), jamais de paramètre partagé injecté dans `teamScore`/`teamStat`/`teamPoss`/`periodScore`/`countType` — ces 5 helpers sont lus par 9 fonctions dont `renderMatch()`/`saveMatch()`, toucher leur signature serait un risque de régression disproportionné (`docs/arch/analyse-pdf-bilan.md` §Décision technique globale).

Le raccourci PDF (Should Have du PRD) et le correctif P0 associé à `loadMatchAsCurrent()` sont **hors scope de cette story** — couverts par STORY-36, qui en dépend.

## Contexte technique

### Fonctions à créer (additives, aucune fonction existante ci-dessous n'est modifiée)
- `periodScoreOfMatch(m, side, per)` — miroir de `periodScore(side,per)` (~1890-1892) avec `m.events` :
  ```js
  function periodScoreOfMatch(m, side, per){
    return (m.events||[]).filter(e=>e.team===side && e.period===per && ACTIONS[e.type]?.isGoal).length;
  }
  ```
- `matchAnalysis(m)` — jumeau de `autoAnalysis()` (~2540-2632) : `const ms = matchStats(m);` en tête, substitue tous les couples `teamScore`/`teamStat` par `ms.home.X`/`ms.away.X`, substitue tout filtre brut `S.events` par `m.events`, substitue `periodScore(...)` par `periodScoreOfMatch(m,...)`. Retourne exactement la même forme (`[{icon,text}]`).
- `matchExportText(m)` — jumeau de `generateExportText()` (~2634-2672), appelle `matchAnalysis(m)` en interne, utilise `ms=matchStats(m)`, `periodScoreOfMatch(m,...)`, et **`m.coachNotes`** (jamais `S.coachNotes`) à la fin du texte.
- `renderBilanAnalyse(m)` — rendu de l'onglet : carte insights (`.card`/`.card-t` "🧠 Analyse automatique", style strictement identique à `renderAnalyse()`), carte notes (textarea + chip dirty-state + bouton "💾 Sauvegarder notes"), carte export (bouton "📋 Copier le résumé d'analyse").
- `renderBilanMatchSelector()` — extraction pure du `<select id="bilan-match-sel">` déjà existant (~3144-3150), markup byte-pour-byte identique, seule sa position change (remonte au-dessus de la barre d'onglets).
- `renderBilanArchivedBanner(m)` — bandeau sticky, pur habillage, aucune logique de calcul.
- `saveBilanNotes()` — écriture réelle :
  ```js
  async function saveBilanNotes(){
    if(S.readOnly) return;
    const m = S.bilanMatch; if(!m) return;
    m.coachNotes = S.bilanNotesDraft!==null ? S.bilanNotesDraft : (m.coachNotes||"");
    try{
      await dbSaveMatch(m);
      showToast("💾 Notes sauvegardées !");
      S.bilanNotesDraft = null;
    }catch(e){ safeAlert("Erreur de sauvegarde: "+e.message); }
  }
  ```
  **Impératif** : toujours passer `m` complet (l'objet obtenu via `S.matchHistory.find(...)`, jamais une copie partielle) à `dbSaveMatch()` — `put()` IndexedDB remplace l'enregistrement entier. Un objet reconstruit à la main (`{id:m.id, coachNotes:...}`) effacerait silencieusement tous les autres champs du match en base (événements, scores, effectifs).

### Fonctions restructurées (comportement observable inchangé pour l'existant)
- `renderBilan()` (~3526-3536) : passe de 2 à **3** onglets pour cette story — `Match / Analyse / Saison` (l'onglet `PDF` sera inséré entre Analyse et Saison par STORY-36, ordre final `Match/Analyse/PDF/Saison`). Construit le sélecteur (`renderBilanMatchSelector()`) et le bandeau (`renderBilanArchivedBanner(m)`) une seule fois, les partage entre Match et Analyse (jamais sur Saison, jamais si `S.bilanMatch` est nul).
  - **Correctif obligatoire du risque #3 (Risk Analyst)** : `S.bilanMatch` doit être **re-dérivé** depuis `S.matchHistory` à chaque rendu de `renderBilan()`, pas seulement lu tel quel : `const m = S.bilanMatch = S.matchHistory.find(x=>x.id===S.bilanMatchId)||null;`. Raison vérifiée dans le code : le nav header (`[data-v]`, ~3616-3620) fait `S.matchHistory=await dbGetAll()` à chaque clic vers "history"/"bilan", ce qui remplace les instances d'objets de `S.matchHistory` par de nouvelles instances désérialisées — sans cette re-dérivation, `S.bilanMatch` resterait une référence obsolète (absente par identité du nouveau `S.matchHistory`) dès qu'on quitte puis revient sur Bilan sans re-sélectionner dans le `<select>`, ce qui invaliderait silencieusement la garantie "muter `m.coachNotes` met aussi à jour `S.matchHistory`" dont dépend le Must Have #6.
- `renderBilanMatch(m)` (~3135-3291) : signature change (reçoit `m` en paramètre au lieu de lire `S.bilanMatch`), perd la construction du sélecteur et des deux placeholders (remontés dans `renderBilan()`). Corps comparatif (scoreboard, barres, tableaux joueurs, fil du match) **strictement inchangé**.

### Nouvelle structure d'état
- `S.bilanNotesDraft` (string|null, défaut `null`) — brouillon en cours d'édition, jamais persisté (ni IndexedDB, ni Supabase, ni `localStorage`), réinitialisé à `null` à chaque changement de match sélectionné.

### `bind()` — ajouts/modifications
```js
// sélecteur de match (~3665-3671), modifié : vérification dirty-state ajoutée
const bms=document.getElementById("bilan-match-sel");
if(bms) bms.onchange=()=>{
  const newId=parseInt(bms.value)||null;
  const savedNote=S.bilanMatch?.coachNotes||"";
  if(S.bilanNotesDraft!==null && S.bilanNotesDraft!==savedNote){
    if(!safeConfirm("Notes non sauvegardées. Changer de match quand même ?\nVos modifications seront perdues.")){
      bms.value=String(S.bilanMatchId||""); return;
    }
  }
  S.bilanMatchId=newId;
  S.bilanMatch=S.matchHistory.find(m=>m.id===newId)||null;
  S.bilanNotesDraft=null;
  R();
};

// NOUVEAU — textarea notes Bilan : jamais de R() dans oninput (casserait focus/curseur, cf. R() ~1457-1510)
const bcn=document.getElementById("bilan-coach-notes");
if(bcn) bcn.oninput=()=>{
  if(S.readOnly) return;
  S.bilanNotesDraft=bcn.value;
  const dirty = S.bilanNotesDraft !== (S.bilanMatch?.coachNotes||"");
  bcn.style.borderColor = dirty ? "rgba(240,199,94,.45)" : "var(--border)";
  const chip=document.querySelector(".bilan-dirty-chip");
  if(chip){ chip.classList.toggle("saved", false); chip.style.display = dirty ? "" : "none"; }
};

// NOUVEAU — bouton Sauvegarder notes Bilan
const sbcn=document.getElementById("save-bilan-coach-notes");
if(sbcn) sbcn.onclick=async()=>{
  if(S.readOnly) return;
  await saveBilanNotes();
  const bcn2=document.getElementById("bilan-coach-notes");
  if(bcn2) bcn2.style.borderColor="var(--border)";
  const chip=document.querySelector(".bilan-dirty-chip");
  if(chip){ chip.classList.add("saved"); chip.style.display=""; chip.querySelector("span:last-child").textContent="✓ Sauvegardé"; }
  setTimeout(()=>{ const c=document.querySelector(".bilan-dirty-chip"); if(c) c.style.display="none"; }, 1400);
};
```

### CSS à ajouter (`style.css`, spec complète `docs/visual/analyse-pdf-bilan.md`)
- `.bilan-match-select` (§3) — `min-height:38px`, bordure fenix-sky neutre.
- `.bilan-archived-banner` (§4) — sticky `top:0`, bordure jaune `2px`, coins plats en haut/arrondis en bas, ombre dédiée. Responsive `<700px` : padding réduit, `font-size:11px`.
- `.bilan-dirty-chip` + `.bilan-dirty-chip.saved` (§7.1) — chip jaune "● Non sauvegardé" / vert "✓ Sauvegardé" (`var(--gk-goal)`).
- Première application réelle de `.is-disabled` (déjà existante, `style.css` ligne 36) sur la textarea et le bouton "Sauvegarder notes" en mode lecteur.

## Critères d'acceptation

1. Nouvel onglet "🧠 Analyse" visible dans la barre `S.bilanTab`, entre "🔍 Match" et "🏆 Saison" — actif uniquement quand un match est sélectionné (`S.bilanMatch` non nul), sinon placeholder "↑ Sélectionne un match pour le revoir" identique au comportement déjà en place.
2. Les insights de l'onglet Analyse de Bilan sont calculés exclusivement par `matchAnalysis(m)` à partir de `m.events`/`m.home`/`m.away` — **aucune occurrence** de `S.events`, `S.home`, `S.away`, `S.coachNotes` dans le corps de `matchAnalysis(m)` ni `matchExportText(m)` (vérifiable par recherche textuelle simple dans le code, critère de revue explicite du Code Reviewer).
3. Avec un match en cours actif en parallèle affichant des chiffres différents (score, événements) et un match archivé sélectionné dans Bilan, les deux vues (Stats → Analyse du match en cours, Bilan → Analyse du match archivé) affichent chacune leurs propres chiffres sans jamais se mélanger — testable en side-by-side, potentiellement sur deux appareils.
4. Le bouton "📋 Copier le résumé d'analyse" dans Bilan produit, via `matchExportText(m)`, un texte reflétant exactement le match sélectionné (score, insights, joueurs, `m.coachNotes`) — jamais le match en cours.
5. La textarea notes affiche `m.coachNotes||""` du match sélectionné dès l'ouverture de l'onglet Analyse.
6. Changer de match dans le sélecteur met à jour immédiatement la textarea avec les notes propres au nouveau match — jamais celles du match précédemment consulté, ni celles du match en cours (`S.bilanNotesDraft` réinitialisé à `null` au changement de sélection).
7. Cliquer "💾 Sauvegarder notes" dans Bilan déclenche un `dbSaveMatch(m)` réel avec l'objet match complet. Vérifiable : après sauvegarde, relire le match via `dbGetAll()` et confirmer que `events.length`, `scoreH`, `scoreA`, `home`, `away` sont strictement inchangés — seul `coachNotes` a changé.
8. Après un clic sur "💾 Sauvegarder notes" réussi : toast de confirmation affiché, chip passe à "✓ Sauvegardé" (vert) pendant 1.4s exactement puis disparaît, bordure de la textarea repasse à `var(--border)`.
9. Reflet immédiat (Must Have #6) : après sauvegarde, changer de match puis revenir sur le match édité affiche la note sauvegardée, sans re-sélection nécessaire dans la même session.
10. Persistance réelle (Must Have #6) : après un rechargement complet de la page puis re-sélection du même match, la note éditée est toujours présente.
11. Pendant toute la frappe (`oninput`) dans la textarea Bilan, aucun appel à `R()` n'est déclenché — vérifiable en tapant une phrase longue sans que le focus/curseur ne saute.
12. Le brouillon (`S.bilanNotesDraft`) survit à un `R()` déclenché par un événement externe (ex. réception Supabase Realtime d'un match en cours actif en parallèle) pendant la frappe — le texte tapé n'est jamais perdu.
13. L'indicateur "non sauvegardé" (chip jaune + bordure textarea jaune `rgba(240,199,94,.45)`) apparaît dès la première frappe qui rend la note différente de `m.coachNotes`, avant toute tentative de changement de match.
14. Tenter de changer de match dans le sélecteur alors que la note est "sale" déclenche `safeConfirm("Notes non sauvegardées. Changer de match quand même ?\nVos modifications seront perdues.")` ; annuler revert visuellement le `<select>` sans changer `S.bilanMatchId`/`S.bilanMatch`.
15. Isolation stricte (Must Have #7) : consulter/éditer Analyse ou Notes depuis Bilan ne modifie jamais `S.coachNotes` ; l'onglet Stats → Analyse du match en cours reste inchangé pendant toute la session Bilan (testable avec une saisie active en parallèle).
16. Mode lecteur (`S.readOnly` actif, Must Have #8) : la textarea et le bouton "💾 Sauvegarder notes" de Bilan reçoivent `.is-disabled` (`opacity:.35;pointer-events:none`) ; la garde `if(S.readOnly) return;` est présente en tête de `saveBilanNotes()` et de l'handler `oninput` (bloque aussi la mise à jour de `S.bilanNotesDraft`, pas seulement la persistance).
17. Aucune régression sur Stats → Analyse pour le match en cours (Must Have #9) : `autoAnalysis()`, `generateExportText()`, `renderAnalyse()`, la textarea liée à `S.coachNotes`, le bouton "Sauvegarder notes" (toast cosmétique, comportement inchangé dans ce contexte) — zéro ligne de ces fonctions modifiée.
18. Bandeau sticky "📁 MATCH ARCHIVÉ — {home} {scoreH}-{scoreA} {away} ({journée})" affiché en haut des onglets Match et Analyse dès qu'un match est sélectionné (jamais sur Saison, jamais sur le placeholder vide), reste visible pendant le scroll.
19. Sélecteur de match remonté au-dessus de la barre d'onglets, partagé entre Match et Analyse, classe `.bilan-match-select` appliquée ; le binding existant fonctionne sans changement de comportement pour l'onglet Match.
20. Robustesse référence stale (risque #3, Risk Analyst) : `S.bilanMatch` est re-dérivé depuis `S.matchHistory` à chaque rendu de `renderBilan()`. Testable via le parcours Bilan → (Matchs ou Stats) → retour Bilan **sans** re-sélection dans le `<select>` : la note affichée/éditable reste celle du bon match, cohérente avec `S.matchHistory` fraîchement rechargé.
21. Aucune modification de `teamScore`, `teamStat`, `teamPoss`, `periodScore`, `countType`, `gkStats`, `gkStatsCombined`, `matchStats(m)`, `dbSaveMatch()` — zéro nouveau paramètre, zéro ligne changée dans ces fonctions.
22. `new Function()` (ou équivalent) valide `app.js` sans erreur de syntaxe après toutes les modifications.

## Hors scope

- Onglet PDF de Bilan et raccourci "Charger ce match & générer son PDF" — couvert par **STORY-36**.
- `loadMatchAsCurrent()` (n'existe pas encore comme fonction extraite avant STORY-36) et le correctif P0 associé (`S.currentMatchId`/`unsubscribeMatchEvents()`) — hors scope ici, cette story ne touche à aucun moment au match en cours.
- Génération PDF complète pour un match archivé sans chargement destructif (Nice to Have #12 du PRD).
- Synchronisation Supabase des notes éditées a posteriori sur un match `finished` (Décision actée #7 du PRD, risque accepté).
- Rattrapage/migration des matchs sauvegardés sans `coachNotes` (`||""` suffit, pas de migration).
- **Avertissement `beforeunload` pour `S.bilanNotesDraft` (risque #6, Risk Analyst) — risque accepté explicitement, non corrigé par cette story.** Si l'application est fermée brutalement (ex. l'étape de déploiement documentée dans `CLAUDE.md` : "Fermer Safari complètement sur iPad → réouvrir") pendant une frappe non sauvegardée dans Bilan, le brouillon est perdu silencieusement, sans avertissement. Limite documentée et acceptée — cohérente avec la même fragilité déjà existante aujourd'hui pour `S.coachNotes` du match en cours (aucun `beforeunload` n'existe nulle part dans `app.js`, ce n'est donc pas une régression introduite par ce cycle, seulement une surface élargie car Bilan permet désormais d'éditer les notes de n'importe quel match de l'historique en une session).
- **Divergence multi-appareil des notes (risque #4, Risk Analyst) — déjà accepté par le PRD (Décision actée #7), aucune mitigation technique.** Précision utile pour un futur diagnostic si Romain rapporte un "doublon" dans son historique : deux sauvegardes indépendantes du même match réel (ex. deux appareils ayant chacun appelé `saveMatch()` après une reprise) produisent deux fiches distinctes jamais reliées (`id` généré par `Date.now()` localement à chaque appareil) — éditer les notes de l'une n'affecte jamais l'autre. Ce n'est pas un écrasement du même enregistrement, mais un fork silencieux entre deux fiches.
- Message explicite dans la textarea désactivée en mode lecteur au-delà de la désaturation `.is-disabled` standard (amélioration optionnelle non bloquante, risque #5).
- Toute refonte visuelle de `renderBilanMatch()` au-delà de l'extraction du sélecteur/bandeau — le comparatif (scoreboard, barres, tableaux joueurs, fil du match) est déjà fonctionnel, non concerné.

## Dépend de

Aucune.

## Taille

L
