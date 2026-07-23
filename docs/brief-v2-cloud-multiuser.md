# Brief v2 — Stockage Supabase + prise de stats partagée (adjoint)

*Produit par l'Analyst — squad build BMAD*
*Complète et fait évoluer `docs/brief.md` (cycle 1) — certains points du cycle 1 sont explicitement remis en cause ci-dessous.*

## 1. Contexte

Romain demande deux choses en même temps :
1. Un **stockage sur Supabase**.
2. Que **la prise de stats soit possible pour un adjoint sur le terrain** — c'est-à-dire une deuxième personne qui saisit des actions pendant le même match.
3. Il demande explicitement que l'Analyst (et le squad) soit prêt à **déconstruire pour reconstruire** si l'existant ne s'y prête pas.

Mon rôle ici est de distinguer la solution énoncée ("Supabase") du besoin réel, avant de valider que c'est bien la bonne réponse.

## 2. Reformulation du besoin réel

Le besoin réel n'est pas "avoir du stockage cloud" en soi — c'est : **permettre à deux personnes de saisir des actions pour le même match, en même temps, sans que l'une écrase ou ignore ce que l'autre vient de faire, et sans perte de données si l'une des deux a un problème de connexion.**

Ce besoin change la nature de l'app :
- **Cycle 1** (brief initial) : un seul appareil, un seul utilisateur, état local, aucune notion de partage. C'est pour ça que "backend serveur" était explicitement listé comme **hors scope**.
- **Cycle 2** (ce brief) : ce hors-scope n'est plus valable. Dès qu'il y a deux personnes qui saisissent le même match, il faut un **état partagé** entre les deux appareils — ce n'est techniquement pas possible avec uniquement du stockage local (IndexedDB par appareil, comme aujourd'hui). Un backend partagé (Supabase ou équivalent) devient donc une nécessité technique, pas juste une préférence. Sur ce point précis, la demande de Romain est la bonne solution au problème qu'il pose — je ne la remets pas en cause.

Ce que je remets en cause, en revanche : est-ce que "Supabase" veut dire remplacer complètement le stockage local, ou l'ajouter par-dessus ? Ma recommandation (à confirmer par l'Architect) : **garder le stockage local comme source de vérité immédiate** (pour que la saisie ne dépende jamais du réseau) et faire de Supabase la couche de **partage + sauvegarde durable**, pas un remplacement pur. Un gymnase de Nationale 1 n'a pas toujours un wifi/4G fiable — si la saisie dépend du réseau pour fonctionner, c'est une régression par rapport à l'app actuelle (qui marche 100% hors-ligne).

## 3. Déconstruire ou reconstruire ?

Ma réponse en tant qu'Analyst, en attendant la validation technique de l'Architect : **on ne reconstruit pas l'app, on reconstruit la couche d'état**.
- Tout ce qui concerne l'affichage, le workflow de saisie (sélection action → équipe → joueur → terrain → validation), le rendu (`R()`), les stats, le PDF : **rien de tout ça ne doit changer**. Ce n'est pas là qu'est le problème.
- Ce qui doit changer en profondeur : la façon dont `S` (l'état du match) est alimenté. Aujourd'hui, `S.events` n'a qu'une seule source (les clics sur cet appareil). Demain, `S.events` doit pouvoir recevoir des événements qui viennent d'un **autre appareil** (celui de l'adjoint), en plus des événements locaux, et rester cohérent (pas de doublon, bon ordre chronologique).
- C'est une évolution structurelle réelle (le Risk Analyst du cycle 1 avait déjà identifié, sans le savoir, la bonne zone : l'absence d'autosave/partage de l'état en cours — `docs/risks/iphone-polish.md` #1). Ce cycle 2 est en fait la version complète de ce problème.

## 4. Nouveau cas d'usage : le mode adjoint

- **Qui** : un membre du staff désigné par Romain pour un match donné (pas un compte permanent multi-clubs, juste "quelqu'un qui aide Romain ce jour-là").
- **Où/quand** : bord de terrain, en même temps que Romain, sur son propre téléphone/tablette.
- **Ce qu'il fait** : vraisemblablement la même chose que Romain (saisir des actions), peut-être sur une équipe ou un type d'action en particulier (ex : Romain suit son équipe, l'adjoint suit le gardien ou l'équipe adverse) — **à clarifier avec Romain, cf. questions en suspens**.
- **Contrainte de simplicité** : l'adjoint n'est pas forcément technophile — rejoindre un match en cours doit être aussi simple que possible (pas de création de compte complexe si évitable).

## 5. Vision (mise à jour)

FENIX Stats reste une app redoutablement simple à utiliser en plein match, sur iPad ou iPhone — mais elle peut désormais être utilisée à deux en même temps sur un même match, avec les données centralisées et sauvegardées automatiquement, sans jamais dépendre du réseau pour continuer à saisir.

## 6. Scope (mise à jour par rapport au cycle 1)

**Change de statut — devient dans le scope :**
- Stockage partagé/central (Supabase) en plus du stockage local existant.
- Saisie à deux (coach + adjoint) sur le même match.

**Reste dans le scope du cycle 1, inchangé :**
- Responsive iPhone (`docs/prd.md` F1), polish visuel (F2) — toujours valides, indépendants de ce pivot.

**Probablement obsolète avec ce pivot (à confirmer avec le PM) :**
- F3 du cycle 1 ("bandeau de rappel d'export manuel") — si Supabase sauvegarde automatiquement en continu, le rappel d'export manuel perd une partie de son utilité. À garder uniquement comme filet de secours si Supabase est indisponible.

**Reste hors scope :**
- Comptes utilisateurs multi-clubs, gestion d'organisation complexe (ligues, plusieurs équipes gérées par plusieurs coachs indépendants).
- Toute dépendance avec l'autre appli web CF (suivi CF) — Supabase est un projet backend **dédié à FENIX Stats**, pas un partage de base avec l'autre appli.

## 7. Critères de succès (mise à jour)

- Romain et un adjoint peuvent saisir des actions sur le même match, chacun sur son appareil, et voient (à quelques secondes près) les événements de l'autre.
- Une coupure réseau pendant la saisie ne bloque jamais l'enregistrement d'une action localement — la synchronisation se rattrape dès que le réseau revient.
- Aucune perte de donnée si un appareil plante ou perd le réseau en cours de match.
- Le mode solo (un seul appareil, pas d'adjoint) reste aussi simple qu'aujourd'hui — cette feature ne doit pas ajouter de friction quand elle n'est pas utilisée.

## 8. Questions en suspens (bloquantes pour la suite du squad)

1. **Répartition des rôles** : l'adjoint saisit-il exactement les mêmes types d'actions que Romain (les deux peuvent tout faire), ou y a-t-il une répartition (ex : Romain = équipe FENIX, adjoint = adversaire / gardiens) ? Ça change la conception de l'écran de saisie partagé.
2. **Comment l'adjoint rejoint un match** : un code/PIN de match à partager verbalement en bord de terrain (simple, pas de compte) ou un vrai compte Supabase Auth (email/mot de passe) par adjoint ? Vu le contexte (bord de terrain, dans le feu de l'action), un code de match simple semble plus réaliste, mais à confirmer.
3. **Combien d'adjoints simultanés** : toujours exactement 2 personnes (Romain + 1 adjoint), ou faut-il prévoir plus (staff élargi) ? Ça change le dimensionnement de la gestion de conflits.
4. **Devenir des matchs déjà stockés en local (IndexedDB) avant ce pivot** : faut-il les migrer vers Supabase, ou seuls les nouveaux matchs utilisent le nouveau système ?

Je recommande de trancher au moins les questions 1 et 2 avant que l'Architect ne fige le schéma Supabase — elles changent la structure des données.

## 9. Décisions actées (réponses de Romain)

Les réponses de Romain simplifient le sujet par rapport à ce que j'envisageais initialement :

- **D1 — Pas de répartition de rôle fixe.** L'aide vient souvent d'un bénévole non spécialiste handball, parfois âgé, qui saisit en direct de temps en temps quand il est disponible — pas une répartition FENIX/adverse ou coach/GK. N'importe qui a accès à l'app peut saisir n'importe quelle action pour n'importe quelle équipe. Conséquence : le vrai enjeu ici est **l'extrême simplicité et la lisibilité de l'interface de saisie** (pas de jargon, gros boutons, undo facile) pour que quelqu'un de non-initié et pas à l'aise avec le numérique puisse s'en servir sans formation — plus un sujet Designer qu'un sujet de structure de données.
- **D2 — Un seul accès partagé, pas de compte individuel.** "Pas besoin de compte utilisateur précis sauf pour ouvrir l'app" : un identifiant/mot de passe unique protège l'accès à l'app (pour que n'importe quel inconnu sur internet ne puisse pas y entrer), mais il n'y a pas de notion d'identité par personne à l'intérieur. Cet identifiant unique est partagé verbalement par Romain à qui l'aide ce jour-là.
- **D3 — Un projet Supabase par déploiement, pas un système multi-clubs.** Romain veut cloner l'app pour le coach des -18 avec **son propre GitHub et son propre projet Supabase**, justement pour ne pas mélanger les données/quotas. Ça confirme et renforce la contrainte "indépendant" du brief initial : ce projet Supabase est 100% dédié à FENIX/Romain, un seul "tenant". Conséquence pour l'Architect : garder la config Supabase (URL + clé) facilement isolable/remplaçable pour qu'un clonage futur soit trivial, mais ne pas concevoir de système multi-tenant dans une même base.
- **D4 — Un seul preneur de stats actif la plupart du temps, mais pas de verrou strict à concevoir.** "Il n'y a qu'une personne qui prend les stats mais elle peut changer" — pas un vrai besoin de co-édition simultanée façon document partagé, plutôt une **passation** (l'appareil qui saisit peut changer d'un moment à l'autre, ou d'un match à l'autre). L'Architect n'a donc pas besoin de concevoir une UI de gestion de conflit complexe — juste un mécanisme robuste (id unique + ordre chronologique) qui ne perd ni ne double aucun événement si jamais deux appareils écrivent au même moment.
- **D5 — Pas de migration de l'historique.** Seuls les nouveaux matchs utilisent Supabase ; les matchs déjà en local restent consultables tels quels (export CSV existant).

