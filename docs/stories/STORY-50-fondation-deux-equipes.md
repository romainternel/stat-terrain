# STORY-50 — Fondation deux équipes (-18 et CF/N1)

**En tant que** Romain,
**Je veux** que l'appli sépare complètement les données de l'équipe -18 et de l'équipe CF (effectifs, matchs, championnat),
**Afin de** gérer les deux équipes du centre de formation avec la même installation, sans jamais mélanger leurs données.

**Absorbe STORY-49** (champ Championnat/Amical) — développée ensemble puisque le Championnat devient naturellement scopé par équipe plutôt qu'une liste figée globale. `docs/stories/STORY-49-championnat-amical.md` est **superseded**, ne pas développer séparément.

Dépend de STORY-48 (sync historique, migration SQL commune, point d'écriture Supabase déjà découplé). Précède STORY-51 (écran visuel de choix — cette story développe la logique, l'UI provisoire minimale suffit ici).

## ⚠️ Prérequis de déploiement
Migration SQL déjà exécutée par Romain pour season/journee/coach_notes/championnat — **doit être ré-exécutée** (idempotente, sans risque) pour ajouter `team_profile` : `docs/supabase-migration-season-journee-notes.sql` mis à jour avec une ligne supplémentaire.

## ⚠️ Point à faire confirmer explicitement par Romain avant de considérer cette story terminée
`docs/risks/deux-equipes.md` R0 : l'équipe -18 étant composée de mineurs, le modèle "un seul mot de passe partagé pour tout voir" (déjà en place depuis STORY-10) s'étend maintenant à leurs données aussi. Ce n'est pas un bug à corriger dans cette story, mais Romain doit explicitement en avoir conscience — à mentionner dans le rapport de livraison, pas juste dans ce fichier.

## Contexte technique
Référence complète : `docs/arch/deux-equipes.md` (état, ordre d'initialisation, scoping localStorage/IndexedDB/Supabase, toutes les fonctions à ajouter/modifier avec leur emplacement précis).

## Critères d'acceptation

**État et migration**
- [ ] `S.teamProfile` (`"cf"`|`"u18"`|`null`), chargé depuis `localStorage hb2_team_profile` **avant** le chargement de l'effectif (ordre vérifié explicitement, cf. Risque R2)
- [ ] Migration one-shot `hb2_teams` (ancienne clé) → `hb2_teams_cf` si cette dernière n'existe pas encore — l'effectif CF actuel de Romain n'est jamais perdu

**Effectifs scopés**
- [ ] `saveTeams()`/`loadTeamsForActiveProfile()` utilisent `hb2_teams_cf`/`hb2_teams_u18` selon `S.teamProfile` — effectifs totalement indépendants, changer de profil charge un effectif différent
- [ ] Nom d'équipe par défaut selon le profil : "FENIX Toulouse" (cf) / "FENIX Toulouse -18" (u18)

**Matchs scopés (local + Supabase)**
- [ ] `saveMatch()` inclut `teamProfile:S.teamProfile`
- [ ] `renderHistory()`/`renderBilanSaison()`/chargement Bilan filtrent tous par `(m.teamProfile||"cf")===S.teamProfile`
- [ ] `upsertMatchSnapshot()` inclut `team_profile:S.teamProfile` dans son payload principal (pas dans l'appel "confort" séparé — nécessaire dès le début du match, pas seulement à l'archivage)
- [ ] `fetchInProgressMatches()` (STORY-14) filtré par `.eq('team_profile', S.teamProfile)` — un appareil -18 ne voit jamais un match CF "reprenable", et inversement
- [ ] `checkForResumableMatch()` non appelée tant que `S.teamProfile` est `null` (au tout premier lancement) — redéclenchée explicitement une fois le profil choisi

**Changer d'équipe**
- [ ] Bouton dans les réglages (⚙), confirmation bloquante si match en cours (même niveau de protection que `newMatch()`)
- [ ] Après changement : ancien match marqué finished si besoin, `S.teamProfile` remis à `null`, effectif rechargé au prochain choix

**Championnat scopé par équipe (reprend STORY-49)**
- [ ] `<input list="championnat-suggestions">` remplace le `<select>` à 4 valeurs — saisie libre, mémorisée dans `localStorage hb2_championnats_<profil>` (max 10 valeurs récentes, la plus récente en tête)
- [ ] `S.championnat` réinitialisé à `""` par `newMatch()` (pas persistant — protège contre un "Amical" oublié qui contaminerait le match suivant, cf. risque déjà tranché en STORY-49)
- [ ] "Amical" (comparaison insensible à la casse) toujours exclu de `renderBilanSaison()`
- [ ] `championnat` ajouté au même appel `update()` "confort" que season/journee/coach_notes (déjà spécifié par STORY-48/49) — pas un nouvel appel réseau

## Cas limites à tester
- **Migration effectif existant** : un appareil ayant déjà un effectif CF (`hb2_teams`) avant cette story le retrouve intact sous le profil `cf` après mise à jour
- **Changement d'équipe avec match en cours** : confirmation bloquante fonctionne, match abandonné proprement (comme `newMatch()`), pas d'événement orphelin
- **Deux appareils, deux profils différents** : aucun mélange de matchs "reprenables" ni d'historique entre eux (testé avec de vrais matchs `in_progress`/`finished` sur les deux profils simultanément)
- **`<datalist>` sur iPad Safari réel** (pas juste desktop/CDP) — cf. Risque R1, à valider explicitement

## Hors scope
L'écran visuel de choix d'équipe lui-même (STORY-51). Séparation de sécurité au niveau base de données (Won't du PRD).

## Dépend de
STORY-48 (migration SQL commune, découplage des appels Supabase déjà en place).

## Taille
L — touche l'initialisation, le stockage local à 3 niveaux (localStorage effectifs, IndexedDB matchs, Supabase), et 2 fonctions de sync déjà existantes (STORY-14/48) à filtrer correctement.
