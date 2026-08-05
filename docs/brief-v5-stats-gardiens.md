# Brief — Refonte Stats Gardiens

## Contexte
Romain (responsable du centre de formation, utilisateur unique de l'app) a exprimé une gêne de lecture sur l'onglet **Stats → Gardiens** (`renderStatGk()`, `app.js` ~ligne 2992) et formulé sa demande directement sous forme de solution de mise en page : une "feuille" par équipe, terrain + impacts à gauche, "Tous les GB" à droite sur la même ligne, avec un format de chiffres en `arrêt/total · % · hors cadre` plutôt que 5 chiffres séparés.

Un avis informel du Designer a déjà circulé (fusion des 2 cartes en une par équipe, ratio ~65/35 terrain/stats, empilement forcé sous 700px, table de détail par GB conservée plus bas) — mais rien n'est acté. Romain a ensuite demandé que toute l'équipe BMAD reprenne le sujet depuis le début, ce qui signifie qu'il faut re-questionner le besoin avant de valider cette solution, pas seulement l'habiller.

Le contexte projet plus large : chantier Supabase (STORY-10 à 17, aidant occasionnel) vient de se clore, tout est livré. Ce sujet Stats Gardiens est un nouveau cycle indépendant, purement UX/lecture — aucune donnée nouvelle n'est en jeu (`gkStats()`/`gkStatsCombined()` renvoient déjà `saves`, `total` (hors cadre exclu), `pct`, `offs` séparé — exactement les briques que Romain décrit).

## Problème
Ce que Romain ne peut pas faire aujourd'hui : **saisir d'un coup d'œil la performance d'un gardien**, que ce soit en bord de terrain ou en debrief. Ce que révèle le code actuel :

- **Trop de cartes empilées avant d'avoir l'image complète** : pour chaque équipe, une carte "résumé" (nom + filtre GB + 5 chiffres) puis une carte "tirs subis" (heatmap + terrain SVG + 3 chiffres) — soit 4 cartes avant même d'arriver à la table de détail par GB. Sur iPad comme sur iPhone, ça veut dire scroller pour relier "ce que dit le chiffre" à "où le tir a atterri".
- **Les 5 chiffres du résumé n'ont pas de hiérarchie visuelle** : ARRÊTS, ENCAISSÉS, H. CADRE, % ARRÊTS, TIRS CADRÉS sont affichés côte à côte avec le même poids visuel (même taille, même style), alors qu'ils ne se lisent pas au même niveau — `saves`/`total` est LA donnée de synthèse, `%` en est la traduction directe, et `offs` (hors cadre) est une info secondaire/contextuelle. Le code ne les groupe pas ainsi.
- **Incohérence de format avec le reste de l'app** : `CLAUDE.md` documente déjà la convention "les stats pen s'affichent en format `arrêts/total` (ex: `3/5`) pas en colonnes séparées" — mais c'est exactement l'inverse qui est fait aujourd'hui pour les tirs cadrés (colonnes séparées, pas de `X/Y`). La demande de Romain ("arrêt/tir total") n'introduit donc pas un nouveau concept : elle aligne cet écran sur une convention de lecture que l'app applique déjà ailleurs pour les pénaltys. C'est un signal fort que le vrai besoin est la **cohérence de format de lecture**, pas juste "faire tenir plus de choses sur l'écran".
- **Le terrain (où) est déconnecté du chiffre (combien)** : le terrain avec impacts est aujourd'hui la 2e carte, sous le résumé et sous la barre de filtres GB — visuellement loin du chiffre qu'il illustre.

Le pire résultat si mal fait : un écran plus dense visuellement mais toujours aussi long à parcourir, ou un format de chiffres qui semble cohérent en desktop/iPad mais redevient illisible en iPhone portrait (contrainte déjà rencontrée et corrigée pour d'autres écrans : STORY-02/03/18/19).

## Utilisateurs
Un seul utilisateur humain identifié à ce jour : **Romain**, mais dans (au moins) deux contextes d'usage distincts qu'il faut clarifier avant de concevoir — parce qu'ils n'ont pas la même contrainte de temps ni le même appareil probable :

1. **Bord de terrain, pendant ou juste après le match** (mi-temps, fin de match), sur **iPad**, debout, en train de suivre le jeu ou de parler au staff — consultation très rapide, coup d'œil, pas de lecture posée. C'est le contexte historique pour lequel toute l'app est pensée ("Optimisé iPad", "gros boutons, texte lisible").
2. **Debrief après-match** — moment probablement plus posé, où Romain a le temps de lire du détail. À clarifier : est-ce toujours sur iPad, ou parfois sur iPhone ("en dépannage", cf. mode Simple/Expert) ou même un ordinateur ? Est-ce que d'autres personnes (joueurs, staff) regardent l'écran avec lui à ce moment-là, ce qui changerait les exigences de lisibilité à distance ?

Pas d'aidant occasionnel concerné ici : l'onglet Stats est un usage de lecture/analyse par Romain, pas un point de saisie partagé.

## Vision
Permettre à Romain de lire la performance d'un gardien — la sienne et celle de l'adverse — en un seul regard, sans devoir relier mentalement plusieurs cartes empilées, avec un format de chiffres cohérent avec le reste de l'app.

## Scope

**Dedans (a priori, à confirmer par le PM) :**
- Réorganisation visuelle de `renderStatGk()` : regroupement des informations existantes (résumé, terrain/impacts, chiffres) en une unité de lecture plus courte par équipe.
- Reformat des chiffres de synthèse au format `arrêt/total · % · hors cadre` (ou équivalent), cohérent avec la convention déjà en place pour les stats pen.
- Adaptation responsive (iPad paysage/portrait, iPhone) — sans réintroduire les problèmes de largeur de terrain déjà rencontrés et corrigés (STORY-02/03/19/22).

**Dehors (a priori) :**
- Toute nouvelle donnée ou calcul (`gkStats()`/`gkStatsCombined()` ne changent pas — le besoin est 100% présentation).
- Le filtre par GB individuel (Tout/GB1/GB2/GB3) et la table de détail par GB (`renderGkDetailTables()`) — sauf si le PM/Designer jugent qu'ils doivent être repensés en conséquence de la réorganisation (cf. questions en suspens).
- La page Gardiens du PDF exporté (jsPDF) — sauf décision explicite de l'aligner aussi, ce sujet n'est pas mentionné par Romain.
- Les autres onglets Stats (Comparaison, Joueurs, Analyse).

## Critères de succès
- Romain peut lire la performance d'un gardien (arrêts/total, %, hors cadre) et voir où les tirs ont atterri **sans scroller** sur iPad, dans les deux orientations.
- Le format des chiffres est cohérent avec celui déjà utilisé pour les stats pen ailleurs dans l'app.
- Aucune régression sur iPhone portrait (pas de terrain écrasé/illisible sous 700px, cf. contraintes déjà documentées).
- Le détail par GB individuel reste accessible pour qui veut aller plus loin, mais n'alourdit plus la première lecture.
- Romain confirme, en conditions réelles (bord de terrain ET debrief), que la nouvelle version répond mieux à son usage que l'actuelle.

## Questions en suspens
- **Quel contexte prime** entre "bord de terrain" (coup d'œil, iPad, contrainte de temps forte) et "debrief" (lecture posée, appareil et audience à confirmer) ? Si les deux ont des besoins différents, faut-il une seule mise en page qui sert les deux, ou accepter un compromis explicite ?
- **Le filtre "Tout/GB1/GB2/GB3" sur la carte résumé a-t-il encore sa place** si la "feuille" affiche par défaut "Tous les GB" et que le détail par GB existe déjà plus bas sous forme de table ? Risque de redondance entre deux façons de voir le détail par gardien.
- **La demande "l'un en dessous de l'autre" pour les chiffres** (alternative proposée par Romain lui-même) est-elle un simple repli mobile (comme le suggère l'avis informel du Designer, breakpoint <700px), ou une préférence de lecture indépendante de l'appareil, à tester dans les deux cas avant de trancher ?
- **Le mot "feuille"** employé par Romain fait-il écho, consciemment ou non, à la page Gardiens du rapport PDF déjà généré (jsPDF, 3 pages) ? Si oui, faut-il aligner les deux plutôt que ne traiter que l'écran ?
- **Qui d'autre que Romain regarde cet écran en debrief** (joueurs, staff) ? Si l'écran est parfois partagé/projeté, la contrainte de lisibilité à distance (taille de police, contraste) doit être challengée au-delà du seul usage solo sur iPad tenu en main.
- **Priorité relative** : ce chantier passe-t-il avant ou après d'autres sujets en attente (migration d'hébergement Netlify→GitHub Pages en cours de validation) ? À trancher par le PM, pas par ce Brief.
