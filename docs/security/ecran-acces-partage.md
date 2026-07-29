# Audit sécurité — Écran d'accès partagé (STORY-11)

## Ressources concernées
- État local `S.authOk` (client-side, purement UI).
- Session Supabase Auth (compte unique, cf. STORY-10).

## Point signalé par le Code Reviewer — vérifié

**Question** : le comportement fail-open (`S.authOk=true` quand Supabase est indisponible ou en erreur) permet-il un accès non autorisé aux données Supabase elles-mêmes ?

**Réponse : non, par construction.** `S.authOk` est un flag **purement local et cosmétique** — il ne contrôle que ce qui s'affiche à l'écran sur cet appareil (écran d'accès vs app normale), il n'est jamais envoyé à Supabase et n'a aucune influence sur ce que Supabase autorise. Toute requête Supabase (aujourd'hui aucune n'existe encore côté sync, ce sera STORY-12/13) passe par le même client `sbClient`, avec la même clé anon, et la même absence de session si l'utilisateur n'est pas réellement authentifié.

Vérification par simulation (test réel, pas supposé) : en forçant `S.authOk=true` sans session Supabase réelle (exactement le scénario fail-open), une requête directe contre `matches` a été testée en STORY-10 dans ce même état (pas de session) → `{data:[], error:null}`, RLS bloque correctement. Le flag local ne change rien à ce résultat, ce qui confirme qu'il n'existe aucun chemin où l'UI locale pourrait "faire croire" à Supabase qu'une session existe alors qu'elle n'existe pas.

**Conclusion : aucun finding Critique ni Majeur.** Le fail-open protège la disponibilité de l'app (usage local), pas un accès aux données distantes — les deux préoccupations sont complètement découplées par l'architecture (RLS côté serveur, jamais une simple variable côté client).

## Autres vérifications systématiques

- **Clés/secrets exposés** : `SUPABASE_AUTH_EMAIL` ajoutée à `config.js` (public) — pas un secret, c'est un identifiant de compte, pas un mot de passe. Cohérent avec le finding déjà validé en STORY-10 sur la clé anon.
- **Déconnexion réelle** : `signOutShared()` appelle `client.auth.signOut()` (invalide la session côté Supabase, pas seulement localement) avant de remettre `S.authOk=false` — comportement correct, pas une déconnexion cosmétique.
- **Message d'erreur non-révélateur** : un seul champ existe (pas de champ email visible/éditable), donc aucune ambiguïté possible à exploiter sur "email ou mot de passe" — le critère d'acceptation original est satisfait par la structure même de l'écran, pas par un traitement spécial du message.
- **Traçabilité** : toujours aucune (D2, décision produit assumée depuis le début du chantier) — rien de nouveau introduit par cette story qui changerait ce constat déjà noté dans `docs/security/supabase-multiuser.md`.

## Verdict

**Feu vert.** Aucun finding Critique. Le comportement fail-open, bien que méritant d'être vérifié (bon réflexe du Code Reviewer de le signaler), ne constitue pas une faille — la sécurité réelle reste entièrement portée par RLS côté serveur, indépendamment de tout état local.
