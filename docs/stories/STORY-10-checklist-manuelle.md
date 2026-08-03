# STORY-10 — Checklist manuelle (à exécuter par Romain)

Ces étapes nécessitent un accès au compte/dashboard Supabase de Romain — ne peuvent pas être faites par l'assistant. Une fois complétées, donner l'URL du projet + la clé `anon` pour que le développement puisse continuer.

## 1. Créer le projet
- Aller sur [supabase.com](https://supabase.com), créer un compte (gratuit) si besoin.
- "New Project" — nom libre (ex: "fenix-stats"), choisir un mot de passe de base de données (pas celui du compte partagé de l'app, différent, à garder de côté).
- Attendre la fin du provisionnement (~2 min).

## 2. Créer les tables + sécurité (RLS)
- Dans le projet : menu **SQL Editor** → **New query**.
- Copier-coller tout le contenu de `docs/supabase-setup.sql` (à la racine du projet fenix/docs).
- Cliquer **Run**.
- Vérifier qu'aucune erreur ne s'affiche.

## 2bis. Activer le Realtime (nécessaire depuis STORY-13/14 — sans cette étape le chrono et les événements ne se synchronisent jamais entre appareils, sans aucune erreur visible)
- Toujours dans **SQL Editor** → **New query**.
- Copier-coller le contenu de `docs/supabase-realtime-setup.sql` (2 lignes `alter publication supabase_realtime add table ...`).
- Cliquer **Run**.

## 3. Créer le compte partagé (unique, pas d'auto-inscription)
- Menu **Authentication** → **Users** → **Add user** → **Create new user**.
- Email au choix (idéalement une adresse que Romain surveille, pour la récupération de mot de passe).
- Mot de passe au choix — **c'est celui que l'app demandera à l'écran d'accès partagé**.
- Cocher "Auto Confirm User" si l'option existe (évite un email de confirmation à traiter).

## 4. Désactiver l'inscription publique (critique sécurité, non négociable)
- Menu **Authentication** → **Providers** (ou **Settings** selon la version) → **Email**.
- Désactiver **"Enable email signups"** (ou équivalent "Allow new users to sign up").
- Sans cette étape, n'importe qui trouvant l'URL du site pourrait créer son propre compte et accéder à toutes les données — cf. `docs/security/supabase-multiuser.md`.

## 5. Vérifier RLS activée (pas juste supposée)
- Menu **Table Editor** → cliquer sur `matches` → vérifier le badge "RLS enabled" (vert) en haut de la table.
- Idem pour `match_events`.
- Si l'un des deux n'affiche pas RLS activée, ré-exécuter les lignes `alter table ... enable row level security;` du script SQL.

## 6. Récupérer les identifiants à transmettre
- Menu **Settings** → **API**.
- Copier **Project URL** (ex: `https://xxxxx.supabase.co`).
- Copier la clé **`anon` `public`** (PAS la clé `service_role`, qui ne doit jamais quitter le dashboard).
- Transmettre ces deux valeurs pour que `config.js` puisse être créé côté code.

## Une fois tout ça fait
Dire "c'est fait, voici l'URL et la clé" (ou donner directement les deux valeurs) — le développement de STORY-10 (côté code) et la suite (STORY-11 à 17) peuvent alors continuer.
