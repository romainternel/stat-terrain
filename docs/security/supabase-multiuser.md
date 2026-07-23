# Audit sécurité — Design Supabase (accès partagé)

*Produit par le Security Access Auditor — squad build BMAD*
*Audit du **design prévu** dans `docs/architecture-supabase.md`, avant implémentation. À rejouer sur le vrai projet Supabase une fois configuré, pas seulement sur le papier.*

## Ressources concernées
- Table `matches`, table `match_events`.
- Authentification Supabase (un seul compte partagé).
- Clé anon + URL du projet (visibles côté client, normal pour ce type d'architecture).

## Findings

### 🔴 Critique — Auto-inscription possible si non désactivée explicitement
Le design repose sur "un seul compte pré-créé, jamais de compte individuel". Mais **par défaut, Supabase Auth autorise n'importe qui possédant la clé anon (visible dans le code client déployé) à créer son propre compte** via `signUp()`. Si l'inscription publique n'est pas désactivée dans les réglages du projet, un inconnu sur internet peut :
1. Récupérer l'URL + clé anon (triviales à extraire d'un site déployé, ce n'est pas un secret).
2. Créer son propre compte Supabase Auth.
3. Devenir "authenticated" au sens de la policy RLS prévue (`auth.role() = 'authenticated'`).
4. Obtenir un accès total en lecture/écriture à tous les matchs — sans jamais connaître le mot de passe partagé.

**Ça annule complètement l'intention de sécurité de F7.** Le mot de passe partagé ne protège que le chemin "prévu" (l'écran de connexion de l'app), pas les appels directs à l'API Supabase.

**Recommandation obligatoire avant mise en prod** : désactiver l'inscription publique dans Supabase (Authentication → Providers/Settings → désactiver "Enable email signups" ou équivalent), pour que seul le compte unique créé manuellement par Romain puisse jamais s'authentifier. À vérifier concrètement (tenter de créer un compte depuis la console/API et confirmer que ça échoue) avant de considérer F7 terminé.

### 🔴 Critique (conditionnel) — RLS non activée sur les tables
Le design prévoit des policies RLS, mais une policy ne s'applique **que si RLS est explicitement activée** sur la table (`alter table matches enable row level security;`). Si cette étape est oubliée à la création des tables, **la table est accessible sans aucune restriction à quiconque possède la clé anon**, même sans authentification — pire que le problème d'auto-inscription ci-dessus.

**Recommandation obligatoire** : vérifier explicitement, table par table, que RLS est activée (pas seulement que des policies existent) avant toute mise en prod. C'est l'erreur la plus fréquente en configuration Supabase — à inclure comme item de checklist de recette, pas seulement une supposition.

### 🟠 Majeur — Aucune distinction lecture/écriture au sein du compte unique
La policy prévue (`for all using/with check auth.role()='authenticated'`) donne les mêmes droits totaux à quiconque se connecte avec le compte partagé — cohérent avec la décision produit (D2, pas de granularité par personne), mais ça veut dire qu'une erreur de manipulation (suppression accidentelle d'un match par un bénévole peu à l'aise) n'a aucune barrière technique, seulement les confirmations UI déjà existantes dans l'app.
**Recommandation** : accepté comme risque assumé (cohérent avec `docs/risks/supabase-multiuser.md` #3), pas de blocage — mais s'assurer que les confirmations de suppression déjà présentes dans l'app restent systématiques et ne soient jamais contournables.

### 🟡 Mineur — Pas de traçabilité de qui a fait quoi
Sans compte individuel, impossible de savoir qui (Romain ou le bénévole du jour) a saisi ou supprimé un événement précis. C'est un choix assumé (D2), mais si ça devient gênant à l'usage, une amélioration à faible coût serait d'ajouter un champ `device_label` optionnel (texte libre, ex : "iPad Romain" / "iPhone bénévole") dans `match_events`, sans en faire un vrai système d'identité.

### 🟡 Mineur — Récupération de mot de passe
Le compte unique aura une adresse email associée pour permettre la réinitialisation du mot de passe si besoin. Vérifier que cette adresse est bien contrôlée par Romain (pas une adresse générique non surveillée), sinon une demande de réinitialisation resterait sans conséquence pratique mais autant partir sur une base saine.

## Verdict

**Pas de feu vert pour F6/F7 tant que les deux findings Critiques ne sont pas vérifiés sur le vrai projet Supabase** (inscription publique désactivée + RLS effectivement activée sur chaque table). Ce sont des cases à cocher rapides à la configuration, pas un changement de design — mais elles sont non négociables avant toute donnée réelle de match n'y transite.

## Comment je travaille avec les autres agents
Ces deux findings Critiques doivent devenir des critères d'acceptation explicites dans les stories Scrum Master concernées (F6/F7), pas de simples recommandations qu'on espère suivre.
