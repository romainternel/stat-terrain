# STORY-56 — Effectif FENIX CF réel chargé automatiquement

**En tant que** Romain,
**Je veux** que l'effectif FENIX CF se charge automatiquement sur un nouvel appareil,
**Afin de** ne plus avoir à importer un CSV à chaque fois.

Suite directe de STORY-55 : demande initiale "insérer une équipe Fenix CF automatique plutôt qu'import CSV tout le temps". La liste réelle a été retrouvée dans `joueurs.csv` (racine `#1 Projet Appli`, mis à jour par Romain avec les vrais noms après l'échange sur STORY-55) — 22 joueurs, format `Prénom.InitialeNom` (convention du club, pas une troncature), sans numéro.

## Point technique : encodage
Le fichier `joueurs.csv` est en **Windows-1252/ANSI**, pas UTF-8 — une première lecture affichait des caractères mojibake sur les accents (`Hail�.G` au lieu de `Hailé.G`). Confirmé et corrigé par relecture explicite en cp1252 avant toute saisie de la liste dans le code (`Hailé`, `Siméo`, `Mattéo` correctement accentués dans `FENIX_CF_ROSTER`, vérifiés affichés correctement en conditions réelles).

## Contexte technique
Nouvelle constante `FENIX_CF_ROSTER` (22 entrées `{name,position}`, en dur dans `app.js`) et fonction `defaultFenixCfTeam()` — même schéma que `defaultAdversaireTeam()` (STORY-55), mais `selected:false` par défaut (comme un import CSV classique : effectif complet chargé, au coach de sélectionner qui joue ce match) et scopée strictement au profil `"cf"` (`S.teamProfile==="cf"`) — le profil `"-18"` n'est pas concerné, aucune liste fournie pour cette équipe. Branché dans `loadTeamsForActiveProfile()`, uniquement quand aucun effectif CF n'est encore sauvegardé sur l'appareil (comportement "automatique au premier lancement" confirmé par Romain) — jamais réappliqué après un premier enregistrement, quels que soient les changements faits ensuite (ajout/suppression/renommage).

## Critères d'acceptation
- [x] Profil "cf" jamais utilisé sur cet appareil → 22 joueurs FENIX Toulouse chargés automatiquement (noms + postes corrects, accents inclus), tous non sélectionnés, GB par défaut assigné au premier gardien de la liste
- [x] Profil "-18" non affecté (reste vide comme avant, pas de liste fournie pour cette équipe)
- [x] Un effectif CF déjà sauvegardé (même après une seule modification) n'est jamais écrasé par un rechargement de la page
- [x] `S.away` (modèle adversaire, STORY-55) non affecté par ce changement

## Vérifié par CDP
Profil "cf" neuf (localStorage vidé) → 22 entrées exactes, positions et noms accentués corrects (capture d'écran), `gkId` assigné, 0 sélectionné ; profil "-18" neuf → reste à 0 joueur ; sauvegarde puis rechargement → effectif réutilisé tel quel (pas régénéré).

## Hors scope
Effectif -18 (aucune liste fournie pour cette équipe à ce jour).

## Taille
XS — 1 constante de données + 1 fonction courte + 1 point de branchement.
