# STORY-49 — Champ Championnat / Amical, exclusion du bilan de saison

> **⚠️ SUPERSEDED — absorbée par STORY-50.** Romain a introduit le besoin de deux équipes (-18/CF) juste après le cadrage de cette story ; le champ Championnat devient scopé par équipe plutôt qu'une liste figée globale. Développée dans le cadre de STORY-50 (`docs/stories/STORY-50-fondation-deux-equipes.md`), pas séparément. Ce fichier est conservé pour l'historique du cadrage, ne pas le développer tel quel.

**En tant que** Romain,
**Je veux** marquer chaque match comme N1, N2, -18, Amical (ou une valeur libre), et que les matchs amicaux n'entrent pas dans le bilan de saison,
**Afin de** garder des statistiques de saison fidèles à la compétition officielle, sans les fausser avec des matchs de préparation.

Suite directe de STORY-48 — réutilise la même migration SQL (déjà étendue) et le même point d'écriture Supabase (`markMatchFinishedById()`, déjà découplé en 2 appels par STORY-48). Si les deux stories sont développées ensemble, implémenter cette extension directement dans le code de STORY-48 plutôt qu'en double.

## ⚠️ Prérequis de déploiement
Partagé avec STORY-48 : `docs/supabase-migration-season-journee-notes.sql` doit être exécuté par Romain (colonne `championnat` déjà incluse dans le script, un seul run pour les deux stories).

## Contexte technique
- Référence design (widget, badge liste, couleurs) : `docs/design/championnat-amical.md`
- Référence architecture (emplacements exacts, dont la découverte que `renderScoreboard()` est du code mort à ne pas toucher) : `docs/arch/championnat-amical.md`
- Risques déjà tranchés pendant le cadrage (réinitialisation à chaque match, pas de persistance comme Saison) : `docs/risks/championnat-amical.md` R1 — **décision déjà actée, pas à rediscuter en développement**

## Critères d'acceptation
- [ ] `S.championnat` initialisé à `"N1"`, **réinitialisé à `"N1"` par `newMatch()`** (pas persistant comme `S.season` — décision R1)
- [ ] Sélecteur `<select id="edit-championnat">` ajouté au badge Saison/Journée existant dans l'écran Match (`.ml-extra`, seul emplacement réellement rendu — ne pas toucher `renderScoreboard()`, code mort confirmé) : options N1/N2/-18/Amical + "Autre…"
- [ ] "Autre…" ouvre un `prompt()` pour saisie libre ; une valeur libre déjà choisie reste correctement affichée en rouvrant le sélecteur (option dynamique ajoutée si la valeur ne correspond à aucune des 4 options fixes)
- [ ] `saveMatch()` inclut `championnat:S.championnat` dans l'objet match local
- [ ] `championnat` ajouté au même appel `update()` "confort" que season/journee/coach_notes dans `markMatchFinishedById()` (pas un 3e appel réseau séparé)
- [ ] `renderBilanSaison()` : `matches` filtré aussi sur `m.championnat!=="Amical"` — un match sans `championnat` renseigné reste inclus (seule la valeur exacte "Amical" exclut)
- [ ] `renderHistory()` : badge Championnat affiché à côté de Journée sur chaque ligne, uniquement si `m.championnat` est renseigné ; couleur distincte pour "Amical" (neutre/atténuée, pas une couleur d'alerte)
- [ ] Aucune régression sur : Saison/Journée (édition existante inchangée), le reste du bilan (Bilan → Match individuel affiche toujours tous les matchs, amicaux compris), export/import CSV

## Cas limites à tester
- **Match Amical suivi d'un match N1** : vérifier concrètement que le 2e match repart bien sur "N1" (pas "Amical" hérité) — le test qui aurait détecté R1 si non corrigé
- **Valeur libre saisie via "Autre…"** (ex: "Coupe de France"), match sauvegardé, écran Match rouvert : le sélecteur affiche bien la valeur libre, pas "N1" par défaut
- **Bilan de saison avec un mélange** N1/Amical : totaux (victoires/nuls/défaites/stats joueurs) recalculés en excluant strictement les matchs Amical, vérifié par comparaison manuelle
- **Matchs existants sans `championnat`** (créés avant cette story) : toujours comptés dans le bilan de saison, pas de régression sur les totaux déjà corrects avant cette story

## Hors scope
Migration rétroactive des matchs existants, filtre pour réafficher les amicaux dans le bilan, niveau de championnat séparé (un seul champ combiné).

## Dépend de
STORY-48 (migration SQL commune, point d'écriture Supabase déjà découplé à réutiliser).

## Taille
S — état + UI + un filtre + un badge d'affichage, pas de nouvelle fonction Supabase (réutilise l'appel déjà spécifié par STORY-48).
