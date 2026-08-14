# Risques — Synchronisation de l'historique des matchs entre appareils

## R1 — Migration non exécutée avant le déploiement du code (P1, déjà mitigé au Design d'architecture)
Si Romain déploie le code sans avoir d'abord exécuté `docs/supabase-migration-season-journee-notes.sql`, l'appel `.update({season, journee, coach_notes})` échouerait (colonnes inconnues pour PostgREST). **Risque initial identifié** : si cet appel avait été fusionné avec `.update({status:'finished'})` (comme rédigé dans un premier temps par l'Architecture), l'échec aurait cassé le comportement déjà en production (un match resterait indéfiniment `in_progress`, donc listé comme "reprenable" sur d'autres appareils — régression sur STORY-14). **Corrigé avant la story** : les deux `update()` séparés en deux appels indépendants, chacun dans son propre `try/catch` — un oubli de migration dégrade seulement l'enrichissement (pas de saison/journée sur les matchs rapatriés), jamais le comportement critique existant.
**Reste à faire, non négociable** : signaler très explicitement à Romain, dans le résumé de livraison, qu'il doit exécuter le script SQL avant que le rapatriement produise des matchs avec saison/journée correctes — sans bloquer techniquement le reste (fail-open volontaire).

## R2 — Performance : première synchronisation sur un nouvel appareil (P2)
Si Romain n'a jamais ouvert l'écran Matchs sur son iPhone, la première ouverture après cette story peut déclencher le rapatriement de **tout** l'historique de la saison en une fois (potentiellement plusieurs dizaines de matchs, chacun avec sa propre requête `match_events`). Boucle séquentielle (pas `Promise.all`) déjà choisie par l'Architecture pour limiter la charge simultanée sur Supabase — au prix d'un temps de première synchronisation plus long (quelques secondes à quelques dizaines de secondes selon le volume), acceptable pour une opération ponctuelle qui ne se reproduit plus une fois les matchs rapatriés (déduplication par `supabaseMatchId`). Pas de barre de progression détaillée prévue (juste l'indicateur "Recherche..." puis le toast final) — jugé suffisant pour une opération qui reste rare (une fois par nouvel appareil).

## R3 — `S._historySyncedThisLoad` : un seul essai par chargement de page (P3)
Si la première tentative échoue (réseau coupé pile à ce moment), aucune retentative n'est prévue avant un rechargement complet de la page — cohérent avec "automatique à l'ouverture" (pas "en continu"), et le fail-open garantit qu'aucune erreur visible n'en résulte (la liste locale reste utilisable normalement). Accepté comme limite connue plutôt que traité par un mécanisme de retry dédié — même logique déjà acceptée pour l'outbox de sync sortante (STORY-12, limite documentée).

## R4 — Matchs très anciens sans `supabaseMatchId` (P3, déjà couvert par le PRD)
Des matchs sauvegardés avant même STORY-27 (introduction de `supabaseMatchId`) n'ont jamais été liés à un match Supabase — non concernés par ce rapatriement (ils n'existent que localement, pas de duplication possible puisqu'ils n'ont jamais été poussés en tant que ligne `matches` identifiable). Comportement neutre, pas un risque actif.

## Sécurité — Security Auditor non convoqué (confirmé)
Aucune nouvelle table, aucun nouveau rôle, même policy `authenticated full access` déjà auditée en STORY-10 appliquée à la même table `matches`/`match_events` — cette story élargit un filtre (`status='finished'` au lieu de `'in_progress'`) sur une lecture déjà permise à tout utilisateur authentifié du compte partagé. Pas de nouvelle surface d'exposition de données entre utilisateurs (modèle "un compte = une équipe", déjà accepté depuis STORY-10). Recommandation : ne pas convoquer le Security Auditor pour cette story.

## Recommandation de découpage
Une seule story — migration SQL et code applicatif fortement couplés (le code ne peut pas être testé sans la migration), pas de découpage utile.
