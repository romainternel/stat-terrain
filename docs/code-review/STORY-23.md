# Code Review — STORY-23 : Fondation du mode Simple/Expert

## Périmètre revu
- `app.js` : nouvel état `S.mode`, chargement/détection au démarrage, `setMode()`, `renderModeToggle()`, intégration dans `renderSetup()` et le panneau `.settings-panel` du Match, binding `[data-mode]` dans `bind()`.
- `sw.js` : `CACHE_NAME` v57 → v58.

## Conformité architecture
- Respecte exactement la décision de l'Architect : `S.mode` est un flag d'état simple, persisté sous `hb2_mode` (cohérent avec le préfixe `hb2_*` déjà en usage), aucune nouvelle structure de données.
- Seuil de détection (`innerWidth<700`) réutilise la constante 700px déjà présente dans les media queries CSS — pas de nouveau seuil inventé, conforme à la recommandation de l'Architecte.
- Garde-fou anti-reset conforme : la lecture de `hb2_mode` précède le calcul de détection par largeur, donc un choix explicite existant n'est jamais recalculé.

## Conventions de code
- Style cohérent avec le reste du fichier (template literals, pas de framework).
- `setMode()` suit le pattern déjà en place pour les autres setters d'état simples du projet (ex: `S.trackGK=!S.trackGK;R();` inline) tout en étant justifiée en fonction séparée ici, car elle porte une logique conditionnelle (confirmation) — bon appel, une inline aurait été illisible.

## Réutilisation vs duplication
- **Point à trancher explicitement** : la story demandait une fonction de rendu unique `renderModeToggle()` partagée aux deux emplacements. Le Developer a délibérément dévié (markup compact différent dans le panneau Réglages Match) et l'a documenté dans les notes Developer avec une justification concrète (largeur de panneau ~180px vs pleine largeur sur Équipes). Vérifié : la logique de clic, elle, est bien unique (`setMode()` + un seul binding `[data-mode]` dans `bind()`, pas deux). **Accepté** — dupliquer le markup complet aurait produit un rendu visuellement cassé dans le panneau étroit, ce que la story ne pouvait pas anticiper avant que le Developer ne le constate concrètement. C'est le bon type de déviation (documentée, justifiée, ne duplique pas la partie qui compte).
- Le pattern toggle (`S.trackGK`) déjà existant est bien réutilisé comme modèle, pas réinventé.

## Scope
- Diff strictement contenu au périmètre de la story (état + toggle). Aucun rendu de l'écran Match modifié — vérifié dans le diff, `renderMatchSimple()` n'existe pas encore, conforme au séquencement STORY-23/STORY-24.
- Petite anecdote positive relevée dans les notes Developer : une faute de frappe accidentelle introduite en cours d'édition (couleur RGB) a été détectée et corrigée par le Developer lui-même avant livraison — bon réflexe, rien à signaler ici.

## Gestion d'erreurs
- Le bloc de détection au démarrage est dans un `try/catch` existant (cohérent avec les autres lectures `localStorage` du fichier, qui échouent silencieusement en environnement restreint — ex. Claude HTML viewer).
- `safeConfirm()` réutilisé tel quel (déjà résilient, retourne `true` par défaut si `window.confirm` indisponible).

## Sécurité basique
- Aucune donnée utilisateur interpolée sans échappement ; `S.mode` ne peut valoir que `'simple'`/`'expert'` (contrôlé par le code, jamais par une saisie libre). Pas de saisine du Security Auditor nécessaire.

## Verdict
**APPROUVÉ**

Aucune remarque bloquante. La déviation sur le markup du toggle est documentée et justifiée — à surveiller uniquement si un 3e emplacement de toggle apparaît un jour (auquel cas factoriser deviendrait plus rentable).
