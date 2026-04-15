;; -- Module Capacites --
(local abilities {})

;; ============================================================
;; EPEE -- Stats de base et pool d'upgrades
;; ============================================================

(local SWORD-BASE
  {:damage 10
   :cooldown 20
   :range 12
   :arc 0 ;; Correspond a l'angle d'attaque en degres (0 = ligne droite), avec arc = 120, l'attaque couvre un cone de 120 degres devant le joueur
   :hits 1})

;; Types : :stat (stackable infini) | :behavior (rules specifiques)
;; stack? : true = proposable plusieurs fois, false = une seule fois
(local sword-upgrades
  {1 {:name "Degats+"       :type :stat     :stack? true  :effects {:damage 3}}
   2 {:name "Vitesse+"      :type :stat     :stack? true  :effects {:cooldown -3}}
   3 {:name "Portee+"       :type :stat     :stack? true  :effects {:range 4}}
   4 {:name "Arc tranchant" :type :behavior :stack? true  :effects {:arc 60}}
   5 {:name "Double frappe" :type :behavior :stack? true  :effects {:hits 1}}})

;; Calcule les stats effectives de l'epee a partir de la liste d'upgrade IDs
(fn abilities.compute-sword-stats [upgrade-ids]
  (local stats {:damage   SWORD-BASE.damage
                :cooldown SWORD-BASE.cooldown
                :range    SWORD-BASE.range
                :arc      SWORD-BASE.arc
                :hits     SWORD-BASE.hits})
  (each [_ id (ipairs upgrade-ids)]
    (when (not= id 0) ;; 0 = sentinelle "epee de base, pas d'upgrade"
      (let [upg (. sword-upgrades id)]
        (each [k v (pairs upg.effects)]
          (if (= (type v) "boolean")
            (tset stats k v)
            (tset stats k (+ (. stats k) v)))))))
  ;; Cooldown plancher : 6 frames minimum
  (when (< stats.cooldown 6)
    (set stats.cooldown 6))
  stats)

;; ============================================================
;; SORTS -- 2 sorts de base, upgrades propres a chacun
;; ============================================================

(local spells
  {1 {:name "Boule de feu"
      :desc "Projectile droit, degats de zone"
      :base {:damage 15 :cooldown 40 :speed 3 :radius 8
             :aoe 0 :dot 0 :dot-dur 0 :projectiles 1 :spread 0}
      :upgrades
        {1 {:name "Explosion"
            :desc "Zone de degats a l'impact (+16px)"
            :effects {:aoe 16}}
         2 {:name "Brulure"
            :desc "3 degats/sec pendant 3 sec"
            :effects {:dot 3 :dot-dur 180}}
         3 {:name "Triple boule"
            :desc "3 boules en eventail (15 deg)"
            :effects {:projectiles 2 :spread 15}}}}

   2 {:name "Foudre"
      :desc "Frappe instantanee, peut chainer entre ennemis"
      :base {:damage 20 :cooldown 50 :chain 0 :stun 0}
      :upgrades
        {1 {:name "Chaine"
            :desc "Rebondit sur 2 ennemis proches"
            :effects {:chain 2}}
         2 {:name "Paralysie"
            :desc "Etourdit l'ennemi pendant 1 sec"
            :effects {:stun 60}}}}})

;; Calcule les stats effectives du sort equipe
;; spell-state : {:id N :applied-upgrades [...]} ou -1
(fn abilities.compute-spell-stats [spell-state]
  (when (= spell-state -1) (lua "return nil"))
  (let [def (. spells spell-state.id)
        stats {}]
    (each [k v (pairs def.base)]
      (tset stats k v))
    (each [_ sub-id (ipairs spell-state.applied-upgrades)]
      (let [upg (. def.upgrades sub-id)]
        (each [k v (pairs upg.effects)]
          (tset stats k (+ (or (. stats k) 0) v)))))
    stats))

;; ============================================================
;; UTILITAIRES -- 3 options, remplacement uniquement
;; ============================================================

(local utilities
  {1 {:name "Dash"
      :type :active
      :desc "Teleportation 32px dans la direction du mouvement"
      :stats {:distance 32 :cooldown 90 :i-frames 10}}

   2 {:name "Bouclier d'epines"
      :type :passive
      :desc "Renvoie 5 degats aux ennemis au contact"
      :stats {:reflect-damage 5}}

   3 {:name "Aimant a or"
      :type :passive
      :desc "L'or est attire vers le joueur (rayon 40px)"
      :stats {:magnet-radius 40}}})

;; ============================================================
;; ACCESSEURS PUBLICS
;; ============================================================

(fn abilities.get-sword-upgrade [id]
  (. sword-upgrades id))

(fn abilities.get-spell [id]
  (. spells id))

(fn abilities.get-utility [id]
  (. utilities id))

(fn abilities.get-spell-upgrade [spell-id sub-id]
  (let [spell (. spells spell-id)]
    (when spell (. spell.upgrades sub-id))))

;; Retourne le nombre d'upgrades restantes pour le sort equipe
(fn abilities.remaining-spell-upgrades [spell-state]
  (when (= spell-state -1) (lua "return 0"))
  (let [def (. spells spell-state.id)
        total (accumulate [n 0 _ _ (pairs def.upgrades)] (+ n 1))
        applied (# spell-state.applied-upgrades)]
    (- total applied)))

abilities
