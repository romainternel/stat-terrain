# Architecture — Terrain à effectif variable par poste + PDF v2 (itération 3)

## 1. Terrain — généralisation de `courtPlayerPositions()` (app.js:2270)

### Décision
Nouveau mode `spread:"grid"` dans `POS_XY`, utilisé pour `PVT` à la place de `spread:"h"`. Il subsume le comportement actuel à 1-2 joueurs (identique visuellement) et ajoute des dispositions dédiées à 3 (triangle) et 4 (carré) via une table de layouts relatifs `{dx,dy}` autour de `base.x/base.y` :

```js
PVT: {x:50, y:59, spread:"grid", hSpread:26, vSpread:13},
```

```js
} else if(base.spread==="grid"){
  const hStep=base.hSpread||26, vStep=base.vSpread||13;
  const layouts = {
    1: [{dx:0,dy:0}],
    2: [{dx:-hStep/2,dy:0},{dx:hStep/2,dy:0}],
    3: [{dx:0,dy:-vStep/2},{dx:-hStep/2,dy:vStep/2},{dx:hStep/2,dy:vStep/2}],
    4: [{dx:-hStep/2,dy:-vStep/2},{dx:hStep/2,dy:-vStep/2},{dx:-hStep/2,dy:vStep/2},{dx:hStep/2,dy:vStep/2}],
  };
  const layout = layouts[players.length];
  if(layout){
    players.forEach((p,i)=>result.push({...p,
      cx:Math.max(6,Math.min(94,base.x+layout[i].dx)),
      cy:Math.max(4,Math.min(96,base.y+layout[i].dy)), anchor}));
  } else {
    // 5+ : garantie de non-crash/non-chevauchement total, pas de disposition
    // dédiée (cf. PRD, hors scope) — grille générique 2 colonnes.
    const perRow=2, rowCount=Math.ceil(players.length/perRow);
    players.forEach((p,i)=>{
      const row=Math.floor(i/perRow), col=i%perRow;
      const colsInRow=Math.min(perRow, players.length-row*perRow);
      result.push({...p,
        cx:Math.max(6,Math.min(94,base.x+(col-(colsInRow-1)/2)*hStep)),
        cy:Math.max(4,Math.min(96,base.y+(row-(rowCount-1)/2)*vStep)), anchor});
    });
  }
}
```
Remarque : le cas `1` est inclus dans la table `layouts` pour uniformiser le code (avant : branche séparée `players.length===1`) mais **le branchement existant `if(players.length===1){...}` en tête de fonction reste prioritaire et inchangé** — il gère aussi bien le mode `"grid"` que les autres, pas de duplication. La table `layouts[1]` n'est donc jamais réellement consultée ; elle est documentée ici pour la lisibilité de la logique mais son retrait n'a aucun effet.

### Pourquoi ce choix plutôt que d'autres
- **Alternative rejetée — étendre le spread vertical linéaire existant (`(i-(n-1)/2)*vSpread`) à PVT** : produirait une colonne verticale à 3-4 joueurs, pas le triangle/carré explicitement demandé. Rejeté : ne répond pas à la demande.
- **Alternative rejetée — hardcoder `if(pos==="PVT" && players.length===3)`** directement dans `courtPlayerPositions()` : fonctionnellement identique mais mélange la géométrie (donnée) avec la logique de branchement (code), et empêche un autre poste de bénéficier un jour du même mécanisme sans dupliquer la fonction. Le mode `spread:"grid"` généraliste, piloté par les données de `POS_XY`, est cohérent avec le pattern déjà en place (`spread:"h"` vs spread vertical par défaut, `anchor:"left"/"right"`).
- **Portée volontairement limitée à PVT pour cette livraison** : ARG/ARD/DC/GB restent en spread vertical linéaire (déjà validé par Romain, aucun retour dessus). Le mode `"grid"` est disponible pour eux si un jour un effectif réel l'exige, sans travail supplémentaire — mais ce n'est pas développé/testé pour ces postes dans ce cycle.

### Impact sur l'existant
- `cpBoxStyle()` (app.js:2264) : aucun changement, consomme `cx/cy/anchor` déjà produits par `courtPlayerPositions()` quel que soit le mode de spread
- Les 4 sites d'appel (`renderMatchPanel`, `renderPenRoster`, `renderPdSelect`, `renderPlayerSelect`) : aucun changement, ils consomment le résultat de `courtPlayerPositions()` sans connaître son mode interne
- Aucune nouvelle structure de données, aucun changement de schéma IndexedDB/Supabase

## 2. PDF — pagination robuste (`generatePDF()`, app.js:4432)

### Décision
Deux mesures complémentaires, pas une seule :

**a) Fix ciblé (résout le cas rapporté)** : la carte "ÉVOLUTION DU SCORE" (actuellement construite juste après les deux tableaux Joueurs, ligne ~4771) est déplacée sur sa propre page (`doc.addPage()` + `pageHeader()` dédié), après la section Joueurs et avant "Carte tir joueur".

**b) Garde générique réutilisable (protection de fond)** : nouvelle fonction utilitaire, appelée avant tout bloc dont la hauteur dépend du volume de données (tableaux Joueurs FENIX/ADVERSAIRE, sections Carte tir joueur FENIX/ADVERSAIRE) :

```js
// Si le bloc à venir (hauteur neededHeight) ne tient pas dans l'espace restant
// avant le pied de page, ouvre une nouvelle page et redessine l'en-tête —
// évite qu'un tableau/section déborde silencieusement de sa page, quel que
// soit le volume de données du match (gros effectif, beaucoup de tirs...).
function ensurePageSpace(y, neededHeight, title, subtitle){
  if(y + neededHeight > H - 15){
    doc.addPage(); bg(); pageHeader(title, subtitle);
    return 18;
  }
  return y;
}
```
Appelée avant `drawPlayerTable()` (une fois pour FENIX, une fois avant ADVERSAIRE — un effectif FENIX à 16 joueurs à lui seul peut légitimement remplir une page) et avant chaque section de `drawShotCardsSection()` (nouvelle fonction, voir §3).

**Non retenu : réécrire `generatePDF()` en moteur de mise en page générique (flow automatique façon HTML)** — sur-ingénierie pour un document au nombre de sections fixe et connu à l'avance. Le pattern procédural actuel (calculer une position Y, dessiner, avancer Y) reste adapté à la taille du document ; `ensurePageSpace()` comble le seul angle mort réel (une section individuelle qui dépasse l'espace restant) sans changer l'architecture générale.

### Chevauchement page 1 (bandeau/carte score)
Non reproduit par investigation manuelle (roster adverse court). Cause probable : **absente une fois F2a/F2b en place** — la carte score de la page 1 a une hauteur fixe indépendante des données (contrairement à la page Joueurs), donc aucun mécanisme de débordement plausible n'a été identifié à cet endroit précis. Le Developer revérifie néanmoins avec un jeu de données chargé des deux côtés (effectifs 16/16, notes coach longues) une fois F2a/F2b livrés ; si le symptôme persiste après ce test, il s'agit d'un bug distinct à recadrer séparément plutôt que de bloquer cette story dessus.

## 3. PDF — Carte tir joueur : section ADVERSAIRE + centrage

### Décision
Extraction de la boucle de dessin en grille (déjà écrite pour FENIX) en fonction partagée, sur le même principe que `drawPlayerTable()` :
```js
function drawShotCardsSection(y, title, players, teamKey){
  // construit shotPlayers pour l'équipe teamKey, dessine le titre de section,
  // délègue à ensurePageSpace() avant le premier rang de cartes, gère le
  // centrage de la dernière ligne à carte unique. Retourne le nouveau y.
}
```
Appelée une fois pour `"home"`, une fois pour `"away"` (seulement si `shotPlayers.length>0` côté away — même garde que le tableau ADVERSAIRE existant). Centrage d'une carte seule en fin de grille : `gpx = margeGauche + (largeurContenu - cellW) / 2` au lieu de rester sur la colonne de gauche par défaut.

### Impact sur l'existant
Le code FENIX actuel (boucle `shotPlayers.forEach` ligne ~4832) est déplacé tel quel dans `drawShotCardsSection()` sans changement de logique de dessin (`drawCourt()`, `drawPlayerZoneGrid()` inchangés) — seul le point d'entrée devient paramétrable par équipe.

## 4. PDF — `drawGoalZone()` : sémantique alignée sur l'app

### Décision
`drawGoalZone()` (utilisée uniquement pour la page Gardiens) recalcule son ratio sur le modèle exact de `goalZoneHeatmap()` (app.js, écran Gardiens en direct) au lieu de sa propre logique actuelle (arrêts/total, perspective gardien) :
- Ratio affiché : `${goals}/${total}` (perspective tireur), pas `${saves}/${total}`
- Couleur : vert `[80,200,120]` si `goals/total > 0.5`, sinon cyan `[78,205,232]` — **jamais rouge** pour ce cas (correction, cf. Visual)
- Cellule vide : `[28,43,64]` (équivalent RGB de `var(--bg3)`)
- Légende ajoutée sous le titre "ZONES D'IMPACT", texte identique à l'app : `"Stat des tireurs (ex : 1/1 = 1 but et non arrêt)"`
- Lettres de zone (HG/HC...) retirées (une ligne supprimée, aucune donnée perdue — c'était un affichage seul, pas une clé de lecture)

### Pourquoi ce choix
`goalZoneHeatmap()` reste la seule source de vérité pour cette sémantique (non modifiée) — le PDF s'aligne dessus plutôt que l'inverse, cohérent avec la règle déjà établie cette session (`teamStat`/flags `isGoal` pour les totaux d'équipe, STORY-37) : ne jamais laisser deux endroits du code raconter une histoire différente sur la même donnée.

## 5. PDF — Top 3 : glyphe et stat gardien

- Rang : `i===0?"1.":(i+1)+"."` — remplace `"★"`. Recherche de tout autre caractère non-ASCII dans `generatePDF()` avant de livrer (audit rapide, pas de refonte).
- Ligne gardien qualifié : `gkS.total`/`gkS.pct` (déjà calculés par `gkStats()`, arrêts/tirs cadrés) au lieu de `gkS.totalAll`/calcul maison. Le seuil de qualification (≥40%, ≥6 arrêts) bascule sur la même base `gkS.total`/`gkS.saves` pour rester cohérent entre le critère d'entrée et le chiffre affiché.

## Risques transverses (renvoi au Risk Analyst)
- Trois itérations PDF déjà livrées cette session sur `generatePDF()` — risque de régression sur ce qui fonctionne déjà (fond blanc, Top 3 mixte, tableau ADVERSAIRE) à chaque nouvelle story touchant la même fonction. Recommandation : une seule story regroupant F2+F3+F4+F5+F6 (toutes dans `generatePDF()`) plutôt que 5 stories séquentielles qui se marchent dessus, avec une vérification visuelle complète des 5-6 pages après le lot plutôt qu'après chaque point.
- Le terrain (F1) est indépendant du PDF (fichier/fonctions disjoints) — peut être développé et vérifié en parallèle sans risque croisé.

## Critère de bascule
Si un futur retour révèle qu'un autre poste que PVT a régulièrement 3+ joueurs sélectionnés en conditions réelles (pas un cas de test), étendre `spread:"grid"` à ce poste ne nécessite qu'une ligne dans `POS_XY` — pas de refonte. Si `generatePDF()` continue de grossir à chaque itération et que `ensurePageSpace()` doit être appelée à plus de 5-6 endroits, reconsidérer une approche de mise en page déclarative (liste de sections avec hauteur estimée, boucle de rendu générique) plutôt que d'empiler les appels manuels.
