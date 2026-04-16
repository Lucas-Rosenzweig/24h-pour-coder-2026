(local enemie {})
(local astar (include :astar))
(local abilities (include :abilities))
;; =========================
;; Création d'un ennemi
;; =========================
(fn enemie.new [x y]
  {:x x
   :y y
   :size 8
   :speed 0.5
   :color 8
   :hp 3
   :attack-timer 0
   :stun-timer 0
   :dot-timer 0
   :dot-dmg 0
   :dot-tick 0
   ;; Animations
   :anim-timer (math.random 0 10)
   :anim-frame 1
   :direction :down
   :moving? false})

;; =========================
;; Distance
;; =========================
(fn enemie.distance [e joueur]
  (math.sqrt
    (+ (* (- joueur.x e.x) (- joueur.x e.x))
       (* (- joueur.y e.y) (- joueur.y e.y)))))

;; =========================
;; IA : Pathfinding A-Star "Pixe-Perfect"
;; =========================
(fn enemie.update [e joueur world enemies]
  ;; DoT processing
  (when (> e.dot-timer 0)
    (set e.dot-timer (- e.dot-timer 1))
    (set e.dot-tick (+ e.dot-tick 1))
    (when (>= e.dot-tick 60)
      (set e.dot-tick 0)
      (set e.hp (- e.hp e.dot-dmg)))
    (when (<= e.dot-timer 0)
      (set e.dot-dmg 0)
      (set e.dot-tick 0)))

  ;; Stun processing
  (when (> e.stun-timer 0)
    (set e.stun-timer (- e.stun-timer 1))
    (set e.moving? false))

  ;; Mouvement seulement si pas stun
  (when (<= e.stun-timer 0)
    ;; Variables d'état pour le pathfinding cache
    (when (not e.path) (set e.path []))
    (when (not e.path-timer) (set e.path-timer 0))

    (set e.path-timer (- e.path-timer 1))

    ;; Recalculer le chemin complet toutes les 60 frames (~ 1 sec)
    (when (<= e.path-timer 0)

      (local custom-wall-fn
        (fn [px py]
          (var is-wall (world.wall? px py))
          ;; Si ce n'est pas un mur classique, on regarde s'il y a un autre ennemi sur cette case
          (when (not is-wall)
            (each [_ other (ipairs enemies)]
              (when (and (not= other e)
                         (>= px other.x) (<= px (+ other.x other.size))
                         (>= py other.y) (<= py (+ other.y other.size)))
                (set is-wall true))))
          is-wall))

      ;; On passe le CENTRE (+4) des entités pour éviter que le coin mathématique déborde sur un mur
      (set e.path (astar.find-path (+ e.x 4) (+ e.y 4) (+ joueur.x 4) (+ joueur.y 4) custom-wall-fn))

      ;; Ajout d'une petite variation aléatoire au timer pour désynchroniser les calculs des monstres
      (set e.path-timer (+ 60 (math.random 0 10))))

    (var dx 0)
    (var dy 0)

    ;; S'il y a un chemin valide, pointer vers le prochain "checkpoint" (pixel précis visé)
    (if (> (length e.path) 0)
        (let [target (. e.path 1)
              tx (. target 1)
              ty (. target 2)]

          ;; Distance vers ce noeud
          (var diff-x (- tx e.x))
          (var diff-y (- ty e.y))
          (local dist (math.sqrt (+ (* diff-x diff-x) (* diff-y diff-y))))

          ;; Tolérance d'arrivée
          (if (<= dist e.speed)
              (do
                (set e.x tx)
                (set e.y ty)
                (table.remove e.path 1))
              (do
                ;; Direction normalisée
                (set dx (/ diff-x dist))
                (set dy (/ diff-y dist))))))

    ;; Fonction pour vérifier si on touche un AUTRE ennemi
    (fn hit-other-enemie? [nx ny]
      (var hit false)
      (let [soft-size (- e.size 2)]
        (each [_ other (ipairs enemies)]
          (when (and (not= other e)
                     (world.collide? (+ nx 1) (+ ny 1) soft-size other.x other.y other.size))
            (set hit true))))
      hit)

    ;; Test des déplacements futurs
    (let [nx (+ e.x (* dx e.speed))
          ny (+ e.y (* dy e.speed))]

      ;; Mouvement X
      (when (and (not= dx 0)
                 (world.can-move? nx e.y e.size)
                 (not (world.collide? nx e.y e.size joueur.x joueur.y joueur.size))
                 (not (hit-other-enemie? nx e.y)))
        (set e.x nx))

      ;; Mouvement Y
      (when (and (not= dy 0)
                 (world.can-move? e.x ny e.size)
                 (not (world.collide? e.x ny e.size joueur.x joueur.y joueur.size))
                 (not (hit-other-enemie? e.x ny)))
        (set e.y ny))
        
      ;; Mise à jour état d'animation
      (let [moving? (or (not= dx 0) (not= dy 0))]
        (set e.moving? moving?)
        (when moving?
          (if (> dx 0) (set e.direction :right)
              (< dx 0) (set e.direction :left)
              (> dy 0) (set e.direction :down)
              (< dy 0) (set e.direction :up)))
        
        (set e.anim-timer (+ e.anim-timer 1))
        (if moving?
          (do
            (when (> e.anim-timer 8)
              (set e.anim-timer 0)
              (set e.anim-frame (+ e.anim-frame 1))
              (when (> e.anim-frame 3) (set e.anim-frame 1))))
          (do
            (when (> e.anim-timer 20)
              (set e.anim-timer 0)
              (set e.anim-frame (+ e.anim-frame 1))
              (when (> e.anim-frame 2) (set e.anim-frame 1))))))))

  ;; cooldown attaque
  (when (> e.attack-timer 0)
    (set e.attack-timer (- e.attack-timer 1))))




;; =========================
;; Attaque
;; =========================
(fn enemie.attack [e joueur take-damage world]
  ;; On "gonfle" la hitbox de 1 pixel de chaque côté pour détecter le contact (puisqu'ils ne se superposent plus)
  (when (and (world.collide? (- e.x 1) (- e.y 1) (+ e.size 2) joueur.x joueur.y joueur.size)
             (= e.attack-timer 0))
    (take-damage joueur 1)
    (set e.attack-timer 30) ;; cooldown (~0.5s)
    ;; Bouclier d'épines : renvoie des dégâts au moment de l'impact
    (when (= joueur.id-utility 2)
      (let [util (abilities.get-utility 2)]
        (enemie.take-damage e util.stats.reflect-damage)))))

;; =========================
;; Dégâts reçus
;; =========================
(fn enemie.take-damage [e dmg]
  (set e.hp (- e.hp dmg)))

(fn enemie.apply-dot [e dmg dur]
  (set e.dot-dmg dmg)
  (set e.dot-timer dur)
  (set e.dot-tick 0))

(fn enemie.apply-stun [e frames]
  (when (> frames e.stun-timer)
    (set e.stun-timer frames)))

(fn enemie.is-dead? [e]
  (<= e.hp 0))

;; =========================
;; Dessin
;; =========================
(fn enemie.draw [e]
  (let [x (math.floor e.x)
        y (math.floor e.y)
        base-spr (if (not e.moving?) 111
                     (or (= e.direction :right) (= e.direction :down)) 113
                     (= e.direction :left) 116
                     119) ;; fallback pour :up
        final-spr (+ base-spr (- e.anim-frame 1))]
    
    (spr final-spr x y 15)

    ;; petite barre de vie
    (rect x (- y 3) e.size 2 1)
    (rect x (- y 3)
          (* e.size (/ e.hp 3)) 2 11)))

;; =========================
;; Export
;; =========================
enemie