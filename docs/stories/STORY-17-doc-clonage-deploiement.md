# STORY-17 — Documentation du clonage pour un autre déploiement

**En tant que** Romain,
**Je veux** que la procédure pour dupliquer l'app pour un autre coach (ex : coach des -18) soit écrite noir sur blanc,
**Afin de** pouvoir le faire moi-même ou le déléguer sans avoir à redemander à Claude à chaque fois.

## Contexte technique

- Documentation uniquement — aucun code à écrire au-delà de ce qui existe déjà après STORY-10 (`config.js` isolé).
- Zone concernée : `CLAUDE.md` du projet (section à ajouter, à faire valider par l'Archiviste au moment de la livraison).

## Critères d'acceptation

- [x] `CLAUDE.md` contient une section "Cloner ce projet pour un autre coach/équipe" listant : copier le repo → créer un nouveau projet Supabase → exécuter le script de création des tables/policies (STORY-10) → remplacer `config.js` → créer le compte unique → désactiver l'inscription publique.
- [x] La checklist de sécurité de STORY-10 (RLS activée, inscription désactivée) est rappelée explicitement dans cette documentation, pas seulement dans les stories de dev.

## Note d'implémentation

En vérifiant `docs/stories/STORY-10-checklist-manuelle.md` pour rédiger cette section, une étape manquante a été trouvée et corrigée dans ce même fichier : l'activation du Realtime (`docs/supabase-realtime-setup.sql`), nécessaire depuis STORY-13/14 mais absente de la checklist d'origine (qui datait d'avant ces stories). Sans cette étape, un clone fonctionnerait mais ne synchroniserait jamais le chrono ni les événements entre appareils, sans aucune erreur visible — piège déjà rencontré une fois en production, maintenant documenté dans la procédure de clonage elle-même.

## Hors scope

- Automatiser la création du projet Supabase (script/CLI) — une checklist manuelle suffit pour l'usage occasionnel prévu (un clonage de temps en temps, pas un produit à grande échelle).

## Dépend de

STORY-10.

## Taille

XS
