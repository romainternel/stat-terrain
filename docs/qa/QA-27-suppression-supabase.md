# QA-27 — Suppression réelle d'un match sur Supabase

## Contexte
Story : `docs/stories/STORY-27-suppression-match-supabase.md`
Code Review : `docs/code-review/STORY-27.md` — **APPROUVÉ**
Security Audit : `docs/security/story-27-suppression-supabase.md` — **feu vert**, un point Mineur déjà corrigé (texte de confirmation enrichi : caractère définitif + portée multi-appareil).

Environnement de test : app servie en local (`http://localhost:8990/index.html`), Chrome headless piloté via CDP (`--headless=new --remote-debugging-port=9713`, profil dédié `chrome-profile-qa27`), `S.authOk=true` injecté pour contourner l'écran d'accès. Pas de vrai compte Supabase authentifié disponible pour ce test : les tentatives d'écriture/suppression réelles échouent en 401 (RLS), ce qui est attendu — la validation porte donc sur la **logique** de la fonctionnalité (garde-fous, ordre des opérations, absence d'exception), pas sur la confirmation d'une vraie suppression serveur.

Chrome de test nettoyé en fin de session (process du port 9713 tué, profil `chrome-profile-qa27` supprimé).

## Critères validés ✅

1. **Match sauvegardé avec `S.currentMatchId` défini → `supabaseMatchId` correspondant persisté.**
   Test : `S.currentMatchId='fake-uuid-test-1111-1111-111111111111'` puis `saveMatch()` → l'objet le plus récent retourné par `dbGetAll()` a bien `supabaseMatchId:'fake-uuid-test-1111-1111-111111111111'`. Conforme.

2. **Match sauvegardé sans `S.currentMatchId` → `supabaseMatchId:null`, aucune exception.**
   Test : `S.currentMatchId=null` puis `saveMatch()` → `supabaseMatchId:null` sur l'objet persisté. Appel explicite de `deleteSupabaseMatch(null)` (valeur `supabaseMatchId` du match sans Supabase) : aucune exception levée (`threw:false`), la fonction fait bien un early-return via `if(!client||!matchId) return;`. Conforme.

3. **`deleteSupabaseMatch('un-faux-uuid-de-test')` appelée directement échoue proprement.**
   Test : appel direct avec un uuid inexistant côté serveur. Résultat : pas d'exception remontée (`threw:false`), l'app reste réactive juste après (`document.body` accessible, aucun blocage). Vérification complémentaire : le client Supabase réel est bien initialisé dans cet environnement (`typeof supabase!=="undefined"`, `SUPABASE_URL` défini, `initSupabaseClient()` non-null) — l'appel a donc bien déclenché une vraie tentative réseau (résolue en ~450ms, cohérente avec un aller-retour réseau/401 absorbé par le `try/catch`), et non un early-return trivial. Le `try/catch` de `deleteSupabaseMatch` absorbe correctement l'échec réseau/RLS sans exception non gérée. Conforme.

4. **Bouton 🗑 → `safeConfirm` avec le nouveau texte ; annuler n'entraîne aucune suppression.**
   Texte de dialogue intercepté lors du clic : *"Supprimer ce match ? Action définitive, y compris sur les autres appareils synchronisés."* — conforme au correctif du Security Auditor. En rejetant la confirmation (dismiss), le nombre de matchs en IndexedDB reste inchangé avant/après (4 → 4). Aucune tentative de suppression locale ni Supabase déclenchée. Conforme.

5. **Non-régression : sauvegarde → apparition dans l'historique → suppression → disparition.**
   Séquence complète : deux matchs sauvegardés (cas avec et sans `supabaseMatchId`) apparaissent dans `S.matchHistory` et dans le rendu (`renderHistory()`, vue `history`). Clic sur 🗑 avec confirmation acceptée : le match ciblé disparaît de `dbGetAll()` (4 → 3), de `S.matchHistory` (id retiré de la liste), et du nombre de lignes `[data-del-match]` affichées à l'écran (3, cohérent avec le nouveau total). Conforme.

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune. La logique de sauvegarde (`saveMatch()`), l'apparition dans l'historique (`renderHistory()`) et la suppression locale (`dbDelete`/`dbGetAll`) fonctionnent comme avant l'ajout de la story, avec la nouvelle capacité de nettoyage Supabase ajoutée sans effet de bord observé.

## Points déjà couverts par les autres agents (non retestés en détail)
- Ordre `match_events` avant `matches` (contrainte FK sans `ON DELETE CASCADE`) : vérifié dans le code par le Code Reviewer, cohérent avec `docs/supabase-setup.sql`. Non re-vérifiable en environnement de test sans vrai compte authentifié (les deux `delete()` échouent en 401 avant d'atteindre la question d'ordre réel côté serveur) — confiance placée dans la revue de code.
- Modèle de permission RLS `for all`/compte partagé : hors périmètre QA fonctionnel, déjà tranché et audité par le Security Auditor (feu vert, pas de Majeur/Critique ouvert).
- `sw.js` : vérifié à jour (`CACHE_NAME='fenix-stats-v72'`), le point "Recommandé" du Code Reviewer (bump de version avant push) est déjà satisfait.

## Limite acceptée (rappel, pas un bug)
Les matchs sauvegardés avant ce correctif n'ont pas de `supabaseMatchId` et ne peuvent pas être nettoyés côté serveur automatiquement — comportement voulu et documenté dans la story, confirmé sans risque de plantage (`m?.supabaseMatchId` falsy → `deleteSupabaseMatch` jamais appelée).

## Verdict

**PASSED**

Les 5 critères de validation demandés sont satisfaits sans exception ni blocage. Aucun bug, aucune régression détectée. Le texte de confirmation intègre bien la mention du caractère définitif et multi-appareil exigée par l'Audit Sécurité. Feu vert pour la mise en production, sous réserve du passage habituel du Regression Guardian avant déploiement.
