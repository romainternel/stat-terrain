# Visual Spec — Terrain et affichage des joueurs

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/design/terrain-joueurs.md`*

## 1. Terrain (F10) — décision : SVG dessiné, pas une image retravaillée

**Constat sur l'existant** : `COURT_IMG` est une photo/illustration raster (JPEG) au fond clair, utilisée à `opacity:0.9` pour s'atténuer sur le fond sombre de l'app — ce traitement (une image claire "assourdie" pour s'intégrer à un thème sombre) donne un rendu terne plutôt qu'un vrai design sombre. C'est probablement la source du "pas très joli".

**Recommandation** : remplacer par un terrain **dessiné en SVG natif** (lignes/arcs), dans les couleurs du thème plutôt qu'une image importée. Le viewBox `0 0 350 208` déjà utilisé ailleurs dans le code (cartes de tir) doit être conservé pour ne pas casser le système de coordonnées des tirs déjà enregistrés (les positions `x`/`y` des événements sont exprimées dans ce référentiel).

### Palette du terrain
```css
--court-fill: #0F1923;        /* même fond que --bg, le terrain se fond dans l'app plutôt que de trancher en clair */
--court-line: rgba(123,167,194,.55);   /* lignes réglementaires, teinte fenix-sky assourdie */
--court-line-dash: rgba(123,167,194,.35); /* ligne des 9m, pointillée, encore plus discrète */
--court-goal: rgba(232,70,90,.6);      /* ligne de but, seul élément qui peut porter un soupçon de couleur distincte */
```

### Éléments à dessiner (tous dans le viewBox 350×208, fond en haut = ligne de but)
1. **Ligne de but** : trait horizontal en haut, `--court-goal`, épaisseur 2.
2. **Zone des 6m** : arc de cercle (quart), `--court-line`, épaisseur 1.5, non rempli (pas de zone remplie en aplat — garder le fond uniforme avec le reste du terrain).
3. **Ligne des 9m** : arc plus large, `--court-line-dash`, `stroke-dasharray:4,3`.
4. **Point de penalty (7m)** : petit trait horizontal court (pas un point plein — cohérent avec la convention déjà utilisée dans l'image actuelle), `--court-line`.
5. **Marque des 4m** : petit trait très court devant le but, `--court-line`.

**Pourquoi pas de remplissage coloré de zone** : le fond du terrain doit rester visuellement calme — ce sont les étiquettes joueurs qui doivent capter l'œil en premier (cohérent avec la note du Designer). Un terrain "trop dessiné" recréerait le problème inverse (surcharge visuelle).

### Impact sur les cartes de tir (Stats)
Le même SVG remplace `<image href="${COURT_IMG}">` dans les cartes de tir — les points de tir déjà dessinés par-dessus (cercles verts/rouges/oranges) restent inchangés, seul le fond change. Cohérence immédiate entre Match et Stats.

## 2. État vide du terrain (F11)

```css
.court-empty-msg{
  position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:6px;color:var(--t3);font-size:13px;text-align:center;pointer-events:none;
}
.court-empty-msg .icon{font-size:28px;opacity:.5;}
```
- Ton neutre (`--t3`, déjà utilisé pour les états vides ailleurs dans l'app — cf. `.empty{color:var(--t3)}` existant, réutilisation directe plutôt que nouvelle couleur).
- `pointer-events:none` pour ne jamais gêner un clic sur le terrain vide sous-jacent (au cas où l'état se termine pendant une interaction).

## 3. Numéro manquant (F13)

```css
.cp-num.cp-num-missing{opacity:.4;font-weight:400;}
```
- Le tiret `–` remplace le `?` avec une opacité réduite (0.4) et un poids de police normal (pas 800 comme un vrai numéro) — se lit comme "absence d'info", pas comme un symbole cliquable ou une erreur.
- Distinct du `?`+✏️ de l'écran Équipes (`renderTeamSetup`), qui reste inchangé — contexte différent, pas dans le scope visuel ici.

## Checklist contraste
- `--court-line` (rgba(123,167,194,.55)) sur `--court-fill` (#0F1923) : lignes discrètes par conception, mais doivent rester visibles à l'œil nu en plein soleil (cf. risque déjà noté en cycle 1 sur la lisibilité extérieure) — à vérifier visuellement par le Developer avant de considérer F10 terminé, pas seulement en environnement de test sombre.
