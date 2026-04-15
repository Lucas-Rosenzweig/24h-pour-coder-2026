# Spécifications techniques (format exploitable LLM)

## 1) Scope
- Type de jeu: roguelike 2D en salles.
- Objectif de ce document: définir des règles non ambiguës pour implémentation gameplay.
- Hors scope actuel: narration, sauvegarde long terme, multijoueur, meta-progression.

## 2) Définitions
- `run`: une partie complète du début jusqu'au game over.
- `étage`: bloc de progression composé de salles de combat, puis shop, puis boss.
- `salle de combat`: salle verrouillée jusqu'à élimination de tous les ennemis.
- `salle de shop`: salle sans combat, dédiée aux achats.
- `salle de boss`: dernière salle de l'étage.

## 3) Paramètres globaux (MVP v1)
- `MAX_HP_JOUEUR = 100`
- `HP_DEPART_JOUEUR = 100`
- `OR_DEPART = 0`
- `NB_SALLES_COMBAT_PAR_ETAGE = 4`
- `OR_PAR_ENNEMI = 10`
- `SOIN_SHOP = +30 HP` (cap à `MAX_HP_JOUEUR`)
- `PRIX_SOIN_SHOP = 30 or`
- `PRIX_AMELIORATION_SHOP = 50 or`
- `NB_CHOIX_RECOMPENSE_FIN_SALLE = 3`
- `NB_CHOIX_SHOP_MAX = 3`

## 4) Capacités joueur
- Déplacement: 4 directions (`haut`, `bas`, `gauche`, `droite`).
- Slot `attaque principale`:
  - Toujours disponible.
  - Peut être améliorée.
- Slot `sort`:
  - Système implémenté, mais le joueur commence sans sort équipé.
  - Un premier choix `sort` équipe un sort de base.
  - Une fois un sort équipé, les récompenses futures peuvent proposer des améliorations de ce sort.
- Slot `utilitaire`:
  - Système implémenté, mais le joueur commence sans utilitaire équipé.
  - Une récompense `utilitaire` peut attribuer un nouvel utilitaire si le slot est vide.
  - Si un utilitaire est déjà équipé, une récompense `utilitaire` le remplace.
  - Pas de système d'amélioration d'utilitaire en MVP (remplacement uniquement).

## 5) Boucle de gameplay
1. Initialiser une `run` à l'étage 1.
2. Générer et jouer `NB_SALLES_COMBAT_PAR_ETAGE` salles de combat.
3. Après ces 4 salles: générer une salle de shop.
4. Après le shop: générer la salle de boss.
5. Si boss vaincu: passer à l'étage suivant et répéter.
6. Si HP joueur <= 0 à n'importe quel moment: fin de run.

## 6) Règles de salle de combat
- À l'entrée:
  - Spawn des ennemis selon le pool de l'étage.
  - Portes verrouillées.
- Pendant:
  - Le joueur peut se déplacer et attaquer.
  - Chaque ennemi vaincu donne `OR_PAR_ENNEMI`.
- Fin de salle:
  - Condition: tous les ennemis sont vaincus.
  - Action: déverrouiller la sortie.
  - Récompense: proposer 1 amélioration (voir section 8).

## 7) Génération des salles
- Chaque étage possède un `pool` de salles prédéfinies.
- À chaque transition vers une nouvelle salle de combat:
  - Tirer aléatoirement une salle dans le pool de l'étage.
  - Règle anti-répétition immédiate: ne pas reprendre la même salle deux fois d'affilée si une alternative existe.
- Ordre forcé par étage:
  - 4 salles de combat -> 1 shop -> 1 boss.

## 8) Système de récompenses (fin de salle)
- À la fin de chaque salle de combat gagnée:
  - Le jeu propose un écran avec 3 choix (1 par catégorie: `attaque`, `sort`, `utilitaire`).
  - Le joueur choisit exactement 1 option.
- Règles MVP:
  - Les améliorations d'attaque s'appliquent immédiatement.
  - Gestion du choix `sort`:
    - Si aucun sort n'est équipé: le choix équipe un nouveau sort.
    - Si un sort est équipé: le choix applique une amélioration du sort équipé.
  - Gestion du choix `utilitaire`:
    - Si aucun utilitaire n'est équipé: le choix attribue un nouvel utilitaire.
    - Si un utilitaire est équipé: le choix le remplace.
  - Pool conditionnel des propositions:
    - Les upgrades de sort ne peuvent être proposées que si un sort est déjà équipé.
    - Tant qu'aucun sort n'est équipé, la proposition `sort` doit être un "nouveau sort".

## 9) Shop
- Entrée shop: pas d'ennemis, pas de verrouillage.
- Offre minimale:
  - Acheter `soin` pour `PRIX_SOIN_SHOP`.
  - Acheter `amélioration` pour `PRIX_AMELIORATION_SHOP`.
- Contraintes:
  - L'achat est refusé si `or` insuffisant.
  - L'achat retire le coût du solde.
  - Le soin ne dépasse jamais `MAX_HP_JOUEUR`.

## 10) États et transitions (référence implémentation)
- `IN_ROOM_COMBAT`
- `ROOM_CLEARED_REWARD`
- `IN_SHOP`
- `IN_BOSS`
- `FLOOR_COMPLETE`
- `RUN_OVER`

Transitions autorisées:
- `IN_ROOM_COMBAT -> ROOM_CLEARED_REWARD` (si tous ennemis vaincus)
- `ROOM_CLEARED_REWARD -> IN_ROOM_COMBAT` (si salles combat restantes)
- `ROOM_CLEARED_REWARD -> IN_SHOP` (si 4 salles combat terminées)
- `IN_SHOP -> IN_BOSS` (quand le joueur quitte le shop)
- `IN_BOSS -> FLOOR_COMPLETE` (si boss vaincu)
- `FLOOR_COMPLETE -> IN_ROOM_COMBAT` (étage +1)
- `* -> RUN_OVER` (si HP joueur <= 0)

## 11) Critères d'acceptation (DoD)
- Le joueur peut se déplacer dans 4 directions.
- Les portes d'une salle de combat restent fermées tant qu'il reste au moins 1 ennemi.
- Chaque ennemi vaincu augmente l'or du joueur de 10.
- Une récompense est proposée après chaque salle de combat gagnée.
- La progression d'étage suit strictement: 4 combats, puis shop, puis boss.
- Le shop permet d'acheter au moins un soin et une amélioration, avec vérification du coût.
- Le game over se déclenche toujours quand HP <= 0.

## 12) Notes d'implémentation
- Les valeurs numériques ci-dessus sont des constantes MVP, ajustables en balancing.
- Le système est conçu pour être déterministe par seed (recommandé), mais la seed n'est pas obligatoire en MVP.
