# STORY-55 — Effectif adversaire par défaut (7 postes prêts à l'emploi)

**En tant que** Romain,
**Je veux** que le côté Adversaire parte déjà rempli (une place par poste, nom = poste) plutôt que vide,
**Afin de** pouvoir suivre le match par poste sans avoir à saisir chaque joueuse adverse une par une, tout en gardant la possibilité de renommer si l'effectif adverse est connu à l'avance.

Demande de Romain : "Est-ce qu'on peut insérer une équipe Fenix CF automatique plutôt qu'import CSV tout le temps ?" — en creusant, `joueurs.csv` (déposé par Romain à la racine du projet) s'est avéré être un modèle intentionnel pour le côté **adversaire** (noms = codes de poste, "fait exprès pour la lecture sur le terrain si on a pas envie de les renommer"), distinct du besoin FENIX CF (vrai effectif nominatif, en attente des données réelles de Romain — cf. STORY-56 à venir).

## Contexte technique
Nouvelles fonctions `defaultAdversairePlayers()`/`defaultAdversaireTeam()` — 7 joueurs générés à partir de `POSITIONS` (hors `"?"`), nom = code de poste, tous `selected:true`, `gkId` pointé sur l'entrée GB. Appliqué à deux points :
1. `loadTeamsForActiveProfile()` — remplace le fallback `{players:[],gkId:null}` pour un profil sans effectif adversaire sauvegardé.
2. `newMatch()` — remplace `S.away.name="Adversaire"` (reset partiel) par `S.away=defaultAdversaireTeam()` (reset complet) : chaque nouveau match repart du modèle générique, jamais de l'effectif adverse (éventuellement renommé) du match précédent.

## Critères d'acceptation
- [x] Nouveau profil / effectif adversaire jamais sauvegardé sur cet appareil → 7 joueurs (GB/ALG/ARG/DC/PVT/ARD/ALD) déjà présents et sélectionnés, GB déjà assigné
- [x] `newMatch()` réinitialise toujours l'adversaire à ce modèle, même si le match précédent avait été renommé avec de vrais noms
- [x] Renommage/ajout/suppression manuels toujours possibles ensuite (aucun changement au flux d'édition existant)
- [x] N'affecte jamais le côté FENIX (`S.home`), qui reste vide tant qu'aucun effectif n'a été saisi/importé

## Vérifié par CDP
Profil jamais utilisé (localStorage vidé pour ce profil) → 7 entrées correctes, `gkId` défini, 7/7 sélectionnés (capture d'écran) ; renommage manuel d'une entrée puis `newMatch()` → effectif adversaire revient bien au modèle générique (pas l'ancien nom renommé).

## Hors scope
Effectif FENIX CF réel (nominatif) — en attente de la liste des joueurs de Romain, traité séparément (STORY-56).

## Taille
XS — 2 fonctions courtes, 2 points d'appel modifiés.
