# Brief v3 — Terrain et affichage des joueurs

*Produit par l'Analyst — squad build BMAD*
*Complète les cycles 1 et 2. Déclenché par un retour direct de Romain sur l'app en production (capture d'écran réelle), après STORY-04/STORY-05.*

## 1. Contexte

Romain a confirmé, sur son app réellement déployée, que le vrai point faible visuel est l'affichage des joueurs sur le terrain — exactement ce que le Developer et le Code Reviewer avaient anticipé après STORY-04. Il a ajouté trois retours concrets et vérifiables dans le code, pas de simples impressions :

1. **L'image du terrain n'est pas jolie** — j'ai vérifié : `COURT_IMG` est une image raster (JPEG encodé en base64, ~700 lignes de données dans `app.js`) utilisée telle quelle en `background-image` sur `.court-pick` (écran Match) **et** intégrée via `<image href>` dans les SVG des cartes de tir (écran Stats). Ce n'est pas un dessin vectoriel maison cohérent avec le reste de la charte (dark theme, couleurs FENIX) — c'est une image générique, la même partout.
2. **Terrain qui affiche tout le monde par défaut** — confirmé dans le code (`renderMatchPanel()`, `renderPdSelect()`, `renderPlayerSelect()`, trois fois le même motif) :
   ```js
   let roster = S[team].players.filter(p=>p.selected);
   if(roster.length===0) roster = S[team].players;
   ```
   C'est un choix délibéré (probablement pensé comme un filet de sécurité "si t'as oublié de sélectionner ton effectif, on te montre tout le monde plutôt qu'un écran vide") — mais Romain le vit comme un bug : il veut un terrain vide tant qu'il n'a pas explicitement choisi son effectif.
3. **"?" affiché pour un joueur sans numéro** — confirmé : `dn=(p)=>p.number?p.number:"?"`, dupliquée trois fois dans le code. Le "?" est utilisé comme repère visuel ET comme indicateur "modifier ce joueur" ailleurs dans l'app (`renderTeamSetup`) — donc le changer doit se faire avec précaution pour ne pas perdre cette fonction.

## 2. Besoin réel (pas juste "rendre plus joli")

Le besoin réel n'est pas esthétique au sens décoratif — c'est que Romain, en un coup d'œil pendant un match, doit pouvoir faire confiance à ce qu'il voit sur le terrain : les bons joueurs, avec les bonnes infos, sans bruit visuel (joueurs qu'il n'a pas sélectionnés, numéros manquants qui ressemblent à une erreur plutôt qu'à un champ vide).

## 3. Utilisateurs et contexte

Inchangé par rapport aux cycles précédents : Romain, bord de terrain, iPad ou iPhone, sous pression du direct.

## 4. Vision

Le terrain de jeu affiché dans l'app doit inspirer confiance visuellement (cohérent avec le reste de l'app, pas une image générique rapportée) et ne jamais afficher une information que Romain n'a pas explicitement choisie.

## 5. Scope

**Dans le scope :**
- Redesign visuel du terrain (remplacement ou refonte de `COURT_IMG`) — décision technique/visuelle à trancher par le Designer et le Visual Crafter.
- Correction du comportement par défaut : terrain vide si aucun joueur sélectionné (affecte 3 endroits identifiés dans le code).
- Traitement du cas "numéro non renseigné" sans réintroduire de confusion avec le marqueur "cliquer pour modifier" existant.

**Hors scope :**
- Changement du système de sélection de roster lui-même (comment on coche "selected", ça reste pareil).
- Toute nouvelle fonctionnalité de gestion d'équipe.

## 6. Critères de succès

- Le terrain ne montre jamais un joueur non sélectionné.
- L'image du terrain est perçue comme cohérente avec le reste de l'app par Romain.
- Un joueur sans numéro reste identifiable sans afficher un "?" qui prête à confusion avec le marqueur d'édition existant.

## 7. Questions en suspens

- Si le terrain est vide (aucune sélection), faut-il un message explicite ("Sélectionnez votre effectif dans l'onglet Équipes") plutôt qu'un simple vide silencieux ? Je recommande oui, pour ne pas que ça ressemble à un bug plutôt qu'à un état attendu — à trancher par le Designer.
- Le remplacement de `COURT_IMG` touche aussi les cartes de tir de l'écran Stats (même image partagée) — à valider si Romain veut que **les deux** endroits changent d'aspect, ou seulement le terrain de saisie en match. Je pars du principe que oui (cohérence globale), sauf avis contraire.
