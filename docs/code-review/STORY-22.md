# Code Review — STORY-22 : Refonte SVG du terrain

## Périmètre revu
- `app.js` : suppression de `COURT_IMG` (constante base64 ~17 617 caractères), ajout de `courtSvgMarkup()`, 7 points d'appel mis à jour.
- `style.css` : 4 nouveaux tokens `--court-*`, classe `.court-svg-bg`.
- `sw.js` : `CACHE_NAME` v56 → v57.

## Conformité architecture
- Référentiel de coordonnées `viewBox 0 0 350 208` strictement conservé — point non négociable de `docs/architecture/terrain-joueurs.md`, respecté. Les événements historiques (x/y) restent valides sans migration.
- Une seule fonction `courtSvgMarkup()` au niveau module, appelée telle quelle aux 7 emplacements (4×`.court-pick` + 3×`<svg viewBox>` déjà existants) : pas de duplication, conforme au pattern déjà en place dans le projet (cf. consolidation `displayNumber()` en STORY-21).
- Nom de fonction différent de la spec (`courtSvgMarkup` au lieu de `renderCourtSvg`) — cosmétique, aligné avec les noms `render*State`/`*Markup` déjà présents, ne pose pas de problème de cohérence.

## Conventions de code
- Style cohérent avec le reste du fichier (template literals, pas de framework, indentation identique).
- Commentaire ajouté au-dessus de `courtSvgMarkup()` justifie une contrainte non-évidente (référentiel de coordonnées) — conforme à la politique "commenter le pourquoi, pas le quoi".

## Réutilisation vs duplication
- RAS. Aucune réinvention : la fonction est unique et partagée.

## Scope
- Diff contenu au strict périmètre de la story (terrain uniquement). Pas de dérive vers STORY-20/21 (sélection joueurs, numéro maillot) déjà livrées séparément.

## Dette silencieuse détectée (non bloquant)
- **Note** : `.court-pick` conserve la règle `background-size:100% 100%;` (style.css) qui n'a plus aucun effet — plus aucun élément ne pose de `background-image` dessus depuis la suppression de `COURT_IMG`. Résidu mort, sans impact fonctionnel. À nettoyer à l'occasion d'un prochain passage sur ce bloc CSS, pas la peine d'ouvrir une story dédiée pour ça.

## Gestion d'erreurs
- Non applicable — génération de markup SVG pure, pas d'appel externe/asynchrone.

## Sécurité basique
- Aucune donnée utilisateur interpolée dans `courtSvgMarkup()` (pas de XSS possible, la fonction ne prend aucun paramètre). Pas de saisine du Security Auditor nécessaire.

## Verdict
**APPROUVÉ**

Aucune remarque bloquante. Une note cosmétique (CSS mort) laissée pour un futur ménage, sans urgence.
