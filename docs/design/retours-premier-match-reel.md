# Design — Retours du premier match réel

## M2 — Couleur du highlight de sélection d'action
`--accent: #F0C75E` (jaune, déjà la couleur "attention/en cours" de la palette — TM, PD, pénaltys) et `--accent-rgb: 240,199,94` (mêmes valeurs que `--yellow`, réutilisées explicitement plutôt qu'une nouvelle teinte) sur `:root`. Une action "armée, en attente d'un joueur" est un état transitoire d'attention, cohérent avec le sens déjà donné au jaune ailleurs dans l'app.

## M4 — Rendre la mi-temps impossible à manquer
Deux niveaux, cohérents avec le système d'alertes déjà en place :
1. **Rappel actif** (nouveau) : à `S.period===1` et `S.time>=1800` (30min), un `showToast("⏰ Fin de la 1ère mi-temps réglementaire — pense à basculer sur MT2", true)` — anti-spam dédié (pas le même timestamp que les alertes TM, pour ne pas se bloquer mutuellement), répété toutes les 2 minutes tant que la transition n'a pas eu lieu (plus insistant qu'un rappel TM ponctuel, puisque l'oubli casse des données, pas juste une opportunité manquée).
2. **Bouton `per-btn` plus visible** une fois ce seuil dépassé : passe d'un style neutre à un style "attention" (bordure jaune, léger effet de pulsation déjà utilisé ailleurs dans l'app pour signaler une action recommandée — pas un nouvel effet inventé) — redevient neutre après la bascule.

## M5 — Fenêtre de validation au lancement
Bandeau non bloquant (pas une modale plein écran — Romain insiste sur "petite fenêtre", cohérent avec le ton du reste de l'app qui évite les interruptions). Apparaît en haut de l'écran Match, juste sous le header, dès l'arrivée sur `S.view="match"` si au moins un manque est détecté :
```
⚠️ À vérifier avant de commencer          [–] [✕]
• GB non sélectionné pour IVRY
• Aucun effectif sélectionné pour FENIX Toulouse
```
- **`[–]` (réduire)** : masque le bandeau mais garde l'information disponible (petit badge discret réapparaît, ex. une pastille ⚠️ à côté du bouton Réglages, cliquable pour rouvrir le détail) — jamais perdu, juste replié.
- **`[✕]` (fermer)** : masque définitivement pour cette session de match (pas de reconfirmation), cohérent avec "on démarre quand même".
- **Détection** : GB non sélectionné (`!S.home.gkId`/`!S.away.gkId`, uniquement si `S.trackGK` actif), effectif vide (`S.home.players.filter(p=>p.selected).length===0`) — par équipe, chaque manque sur sa propre ligne.
- Ne réapparaît jamais après avoir été explicitement fermé (`✕`) ou après le premier événement enregistré (une fois le match commencé pour de vrai, le moment est passé) — seul `[–]` permet un retour ultérieur, pas un réaffichage automatique.

## Mode "équipe générale" — abandonné
Romain a explicitement demandé d'abandonner cette piste après lecture du résumé du cycle : pas besoin de pouvoir continuer à saisir sans joueur sélectionné, juste être prévenu. Le bandeau M5 ci-dessus (qui liste déjà "GB non sélectionné" et "Aucun effectif sélectionné" par équipe) couvre entièrement le besoin réel — aucun composant/flux supplémentaire à concevoir.
