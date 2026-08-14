# Design — Deux équipes distinctes

## Écran de choix d'équipe — proposition provisoire, en attente de la référence de Romain
Romain a annoncé l'envoi d'un visuel de référence ("un visuel que je vais t'envoyer qui apparaît d'un coin à un autre... et qui disparaît"). Tant qu'il n'est pas reçu, proposition raisonnable à considérer comme un **point de départ remplaçable**, pas un rendu figé :

- Plein écran, fond `var(--bg)`, logo FENIX (déjà embarqué en base64, cf. `CLAUDE.md`) centré en haut, petit
- Deux grandes cartes cliquables côte à côte (empilées verticalement sous ~600px de large) : **"-18"** et **"CF"**, typographie très grande (cohérent avec "en gros" demandé par Romain), une couleur d'accent différente par carte (ex: `--fenix-sky` pour CF, une teinte secondaire pour -18 — à trancher avec Romain, pas de couleur "jeune"/"stéréotypée" imposée sans son avis)
- Tap sur une carte → `S.teamProfile` fixé, écran disparaît (fondu simple, pas l'animation "d'un coin à l'autre" que Romain décrit tant que sa référence n'est pas là — cf. Visual Crafter pour la piste d'animation provisoire)
- Aucun bouton "Annuler"/"Retour" — c'est un choix structurant, pas une action réversible d'un clic (le changement se fait ensuite depuis les réglages, geste volontaire différent, cf. M8 du PRD)

## Emplacement dans le flux de l'app
Après l'écran d'accès partagé (`S.authOk`), avant tout le reste — remplace ce que l'utilisateur verrait normalement (Équipes/Match/Stats) tant que `S.teamProfile` n'est pas défini. Une fois défini, plus jamais revu automatiquement (M2 du PRD).

## Changer d'équipe (réglages)
Un bouton dans le panneau ⚙ Réglages (même groupe que le mode Simple/Expert et le mode lecteur, cohérent avec l'audit de clarté d'interface STORY-29 qui a déjà organisé ce panneau en groupes) : **"🔄 Changer d'équipe (actuellement : CF)"**. Clic → confirmation bloquante si un match est en cours (`S.events.length>0`, même style de message que la bascule Expert→Simple) → réaffiche l'écran des deux encarts → nouveau choix → `R()`.

## Champ Championnat — saisie libre avec mémoire par équipe
Remplace le `<select>` à 4 valeurs fixes envisagé par la 1ère version de STORY-49. `<input list="championnat-suggestions" id="edit-championnat">` (pattern HTML natif, pas de nouveau composant JS) :
```html
<input id="edit-championnat" list="championnat-suggestions" value="${S.championnat}" style="...">
<datalist id="championnat-suggestions">
  ${championnatHistory(S.teamProfile).map(v=>`<option value="${v}">`).join("")}
</datalist>
```
Taper une nouvelle valeur et valider (`onchange`, comme Saison/Journée) l'ajoute à l'historique mémorisé de l'équipe active (`localStorage`, scopé par profil — cf. Architecture) — disponible en suggestion la prochaine fois, sans jamais forcer une liste fixe. Rechoisir une valeur déjà utilisée = un seul tap dans les suggestions natives du navigateur, pas de retype.

## Nom d'équipe par défaut selon le profil
`"FENIX Toulouse"` (CF) / `"FENIX Toulouse -18"` (-18) — visible immédiatement dans l'écran Équipes après le choix de profil, modifiable comme aujourd'hui (pas un champ verrouillé).

## Aucune confusion visuelle entre les deux équipes une fois dans l'app
Pas de bandeau permanent "Vous êtes sur CF" during l'usage normal (jugé redondant — le nom d'équipe affiché partout, déjà `S.home.name`, suffit à identifier le contexte) — seul le bouton des réglages rappelle explicitement l'équipe active, pour rester consultable sans imposer un élément visuel permanent supplémentaire sur un écran déjà dense (Match notamment).
