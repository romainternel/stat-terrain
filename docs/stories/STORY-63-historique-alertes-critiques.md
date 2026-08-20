# STORY-63 — Historique des alertes critiques ratées

**En tant que** Romain,
**Je veux** pouvoir consulter les dernières alertes (TM conseillé, changez de GB) même après leur disparition,
**Afin de** ne pas les rater définitivement si j'ai les yeux sur le terrain au mauvais moment.

Suggestion de l'Audit Final du 2026-08-20 (`docs/audit-final/AUDIT-2026-08-20.md`) : les toasts durent 2,5 à 4 secondes et ne laissent aucune trace, contrairement au bandeau de rappel GB (STORY-53) qui reste affiché.

## Contexte technique
- Zone concernée : `showToast()` (`app.js:1359`) pour l'enregistrement ; nouveau bloc de rendu calqué sur `launchWarningBannerHtml` (`app.js:2256`) pour l'affichage ; bindings calqués sur `app.js:4948-4950`
- Nouvelles structures : `S.alertHistory:[]` (objets `{time, msg}`, 3 entrées max, plus récent en premier), `S.alertHistoryCollapsed:false`, `S.alertHistoryDismissed:false` — voir `docs/arch/audit-corrections-et-mode-simple.md` section F2
- Maquette : `docs/design/audit-corrections-et-mode-simple.md` section F2 ; specs visuelles exactes : `docs/visual/audit-corrections-et-mode-simple.md` section F2
- Impact sur l'existant : `showToast()` gagne un effet de bord (push en historique) uniquement quand `isAlert===true` — couvre automatiquement tous les appels existants (demi-temps, TM conseillé ×3 variantes, changez de GB ×2 variantes, plus de TM disponible, tireur indisponible, PDF non chargée) sans les modifier individuellement

## Critères d'acceptation
- [ ] Toute alerte critique (`showToast(msg, true)`) est ajoutée à `S.alertHistory`, horodatée (`fmtTime(S.time)`), la plus récente en premier
- [ ] `S.alertHistory` ne dépasse jamais 3 entrées (la plus ancienne est retirée quand une 4e arrive)
- [ ] Un nouveau bandeau "🔔 Dernières alertes" s'affiche sur l'écran Match dès qu'il y a au moins une entrée, sous le bandeau GB existant s'il est aussi présent — jamais affiché s'il n'y a aucune alerte dans la session
- [ ] Ce bandeau est réductible en pastille `[🔔N]` (même pattern que `[–]` du bandeau GB) et fermable définitivement pour la session (`[✕]`), indépendamment du bandeau GB (les deux états de collapse/dismiss sont indépendants)
- [ ] `newMatch()` réinitialise `S.alertHistory=[]`, `S.alertHistoryCollapsed=false`, `S.alertHistoryDismissed=false`
- [ ] `loadMatchAsCurrent()` réinitialise également `S.alertHistory=[]` (le match archivé chargé ne doit jamais hériter de l'historique d'alertes du match précédent — cf. `docs/risks/audit-corrections-et-mode-simple.md` R3)
- [ ] Aucun changement de comportement des toasts existants (durée, style, déclenchement) — uniquement un effet de bord supplémentaire ajouté
- [ ] Mode lecteur : le bandeau reste visible en lecture seule, comme le bandeau GB (pas de garde `readOnly` à ajouter, c'est un affichage, pas une écriture)
- [ ] `new Function()` passe sur `app.js` modifié

## Hors scope
- Historique persistant au-delà de la session en cours (pas de sauvegarde IndexedDB/Supabase de l'historique d'alertes)
- Un centre de notifications séparé ou une icône cloche dans le header
- Modifier le contenu/seuil des alertes elles-mêmes (déjà couvert par STORY-52/60, inchangé ici)

## Dépend de
Aucune

## Taille
S
