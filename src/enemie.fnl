(local enemie {})
(local astar (include :astar))
(local abilities (include :abilities))

(local LASER-SPRITE-ID 10)
(local KAMIKAZE-SPRITE-ID 10)
(local LASER-RANGE 96)
(local LASER-WINDUP 48)
(local LASER-COOLDOWN 70)
(local LASER-DAMAGE 1)
(local KAMIKAZE-TRIGGER-DIST 24)
(local KAMIKAZE-ARMING-TIME 45)
(local KAMIKAZE-EXPLOSION-RADIUS 18)
(local KAMIKAZE-EXPLOSION-DAMAGE 1)
(local KAMIKAZE-EXPLOSION-FLASH 8)
(local HURT-FLASH-DURATION 8)
(local SWORD-KNOCKBACK-DURATION 7)
(local SWORD-KNOCKBACK-FRICTION 0.72)

;; =========================
;; Utilitaires internes
;; =========================
(fn center-x [e]
  (+ e.x (/ e.size 2)))

(fn center-y [e]
  (+ e.y (/ e.size 2)))

(fn normalize [dx dy]
  (let [len (math.sqrt (+ (* dx dx) (* dy dy)))]
    (if (> len 0.001)
        [(/ dx len) (/ dy len)]
        [1 0])))

(fn point-in-player? [px py joueur]
  (and (>= px joueur.x)
       (< px (+ joueur.x joueur.size))
       (>= py joueur.y)
       (< py (+ joueur.y joueur.size))))

(fn trace-laser [sx sy dx dy world joueur]
  (var end-x sx)
  (var end-y sy)
  (var hit-player false)
  (var step 1)
  (var done false)

  (while (and (<= step LASER-RANGE) (not done))
    (let [px (+ sx (* dx step))
          py (+ sy (* dy step))]
      (if (world.wall? px py)
          (set done true)
          (do
            (set end-x px)
            (set end-y py)
            (when (and joueur (point-in-player? px py joueur))
              (set hit-player true)))))
    (set step (+ step 1)))

  [end-x end-y hit-player])

(fn process-dot [e]
  (when (> e.dot-timer 0)
    (set e.dot-timer (- e.dot-timer 1))
    (set e.dot-tick (+ e.dot-tick 1))
    (when (>= e.dot-tick 60)
      (set e.dot-tick 0)
      (set e.hp (- e.hp e.dot-dmg))
      (set e.hurt-timer HURT-FLASH-DURATION))
    (when (<= e.dot-timer 0)
      (set e.dot-dmg 0)
      (set e.dot-tick 0))))

(fn process-stun [e]
  (when (> e.stun-timer 0)
    (set e.stun-timer (- e.stun-timer 1))))

(fn tick-attack-cooldown [e]
  (when (> e.attack-timer 0)
    (set e.attack-timer (- e.attack-timer 1))))

(fn ensure-path-state [e]
  (when (not e.path) (set e.path []))
  (when (not e.path-timer) (set e.path-timer 0)))

(fn apply-knockback-motion [e world enemies joueur]
  (when (> e.knockback-timer 0)
    (set e.knockback-timer (- e.knockback-timer 1))
    (let [nx (+ e.x e.knockback-vx)
          ny (+ e.y e.knockback-vy)]
      (when (and (world.can-move? nx e.y e.size)
                 (not (world.collide? nx e.y e.size joueur.x joueur.y joueur.size)))
        (set e.x nx))
      (when (and (world.can-move? e.x ny e.size)
                 (not (world.collide? e.x ny e.size joueur.x joueur.y joueur.size)))
        (set e.y ny)))
    (set e.knockback-vx (* e.knockback-vx SWORD-KNOCKBACK-FRICTION))
    (set e.knockback-vy (* e.knockback-vy SWORD-KNOCKBACK-FRICTION))))

(fn move-with-path [e joueur world enemies]
  (ensure-path-state e)

  ;; Variables d'état pour le pathfinding cache
  (set e.path-timer (- e.path-timer 1))

  ;; Recalculer le chemin complet toutes les 60 frames (~1 sec)
  (when (<= e.path-timer 0)
    (local custom-walkable-fn
      (fn [px py]
        ;; On vérifie si la hitbox complète [px, py, size, size] passe
        (var valid (world.can-move? px py e.size))

        ;; Vérifier l'évitement des autres monstres
        (when valid
          (each [_ other (ipairs enemies)]
            (when (and (not= other e)
                       ;; AABB classique entre le test et l'autre ennemi
                       (world.collide? px py e.size other.x other.y other.size))
              (set valid false))))
        valid))

    ;; On passe la vraie position sans l'offset du centre, puisque on teste la hitbox complète
    (set e.path (astar.find-path e.x e.y joueur.x joueur.y custom-walkable-fn))

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
      (set e.y ny))))

(fn update-grunt [e joueur world enemies _]
  (let [prev-x e.x
        prev-y e.y]
    (move-with-path e joueur world enemies)
    (let [dx (- e.x prev-x)
          dy (- e.y prev-y)
          moving? (or (not= dx 0) (not= dy 0))]
      (set e.moving? moving?)
      (when moving?
        (if (> dx 0) (set e.direction :right)
            (< dx 0) (set e.direction :left)
            (> dy 0) (set e.direction :down)
            (< dy 0) (set e.direction :up)))
      (set e.anim-timer (+ (or e.anim-timer 0) 1))
      (if moving?
          (when (> e.anim-timer 8)
            (set e.anim-timer 0)
            (set e.anim-frame (+ e.anim-frame 1))
            (when (> e.anim-frame 3) (set e.anim-frame 1)))
          (when (> e.anim-timer 20)
            (set e.anim-timer 0)
            (set e.anim-frame (+ e.anim-frame 1))
            (when (> e.anim-frame 2) (set e.anim-frame 1)))))))

(fn begin-laser-windup [e joueur world]
  (let [dx (- (+ joueur.x (/ joueur.size 2)) (center-x e))
        dy (- (+ joueur.y (/ joueur.size 2)) (center-y e))
        [nx ny] (normalize dx dy)
        sx (center-x e)
        sy (center-y e)
        [end-x end-y _] (trace-laser sx sy nx ny world nil)]
    (set e.laser-dir-x nx)
    (set e.laser-dir-y ny)
    (set e.laser-windup LASER-WINDUP)
    (set e.laser-end-x end-x)
    (set e.laser-end-y end-y)
    (set e.path [])))

(fn fire-laser [e joueur world take-damage]
  (let [sx (center-x e)
        sy (center-y e)
        [end-x end-y hit-player] (trace-laser sx sy e.laser-dir-x e.laser-dir-y world joueur)]
    (set e.laser-end-x end-x)
    (set e.laser-end-y end-y)
    (set e.laser-flash 6)
    (when hit-player
      (take-damage joueur LASER-DAMAGE sx sy))))

(fn track-movement [e prev-x prev-y]
  (let [dx (- e.x prev-x)
        dy (- e.y prev-y)
        moving? (or (not= dx 0) (not= dy 0))]
    (set e.moving? moving?)
    (when moving?
      (if (> (math.abs dx) (math.abs dy))
          (if (> dx 0) (set e.direction :right) (set e.direction :left))
          (> dy 0) (set e.direction :down)
          (< dy 0) (set e.direction :up)))))

(fn tick-anim-2 [e]
  (set e.anim-timer (+ (or e.anim-timer 0) 1))
  (let [threshold (if e.moving? 8 20)]
    (when (> e.anim-timer threshold)
      (set e.anim-timer 0)
      (set e.anim-frame (if (= e.anim-frame 1) 2 1)))))

(fn update-laser [e joueur world enemies take-damage]
  (when (> e.laser-flash 0)
    (set e.laser-flash (- e.laser-flash 1)))

  (let [prev-x e.x
        prev-y e.y]
    (if (> e.laser-windup 0)
        (do
          (set e.moving? false)
          ;; Orienter le tireur vers le joueur pendant le windup
          (if (> (math.abs e.laser-dir-x) (math.abs e.laser-dir-y))
              (if (> e.laser-dir-x 0) (set e.direction :right) (set e.direction :left))
              (> e.laser-dir-y 0) (set e.direction :down)
              (< e.laser-dir-y 0) (set e.direction :up))
          (set e.laser-windup (- e.laser-windup 1))
          (when (<= e.laser-windup 0)
            (fire-laser e joueur world take-damage)
            (set e.laser-cooldown LASER-COOLDOWN)))
        (do
          (move-with-path e joueur world enemies)
          (track-movement e prev-x prev-y)
          (set e.laser-cooldown (- e.laser-cooldown 1))
          (when (<= e.laser-cooldown 0)
            (begin-laser-windup e joueur world)))))
  (tick-anim-2 e))

(fn in-kamikaze-radius? [e joueur]
  (let [dx (- (+ joueur.x (/ joueur.size 2)) (center-x e))
        dy (- (+ joueur.y (/ joueur.size 2)) (center-y e))
        dist (math.sqrt (+ (* dx dx) (* dy dy)))]
    (<= dist (+ KAMIKAZE-EXPLOSION-RADIUS (/ joueur.size 2)))))

(fn update-kamikaze [e joueur world enemies take-damage]
  (set e.moving? false)
  (if (= e.kami-state :chase)
      (let [prev-x e.x
            prev-y e.y]
        (move-with-path e joueur world enemies)
        (track-movement e prev-x prev-y)
        (when (<= (enemie.distance e joueur) KAMIKAZE-TRIGGER-DIST)
          (set e.kami-state :arming)
          (set e.kami-arming-timer KAMIKAZE-ARMING-TIME)
          (set e.path [])))
      (= e.kami-state :arming)
      (do
        (set e.kami-arming-timer (- e.kami-arming-timer 1))
        (when (<= e.kami-arming-timer 0)
          (set e.kami-state :exploding)
          (set e.kami-explosion-timer KAMIKAZE-EXPLOSION-FLASH)
          (set e.kami-did-damage false)))
      (= e.kami-state :exploding)
      (do
        (when (not e.kami-did-damage)
          (set e.kami-did-damage true)
          (when (in-kamikaze-radius? e joueur)
            (take-damage joueur KAMIKAZE-EXPLOSION-DAMAGE (center-x e) (center-y e))))
        (set e.kami-explosion-timer (- e.kami-explosion-timer 1))
        (when (<= e.kami-explosion-timer 0)
          (set e.hp 0))))
  (tick-anim-2 e))

;; =========================
;; Création d'un ennemi
;; =========================
(fn enemie.new [x y enemy-type]
  (let [kind (or enemy-type :grunt)
        e {:x x
           :y y
           :size 8
           :speed 0.5
           :color 8
           :hp 3
           :max-hp 3
           :type kind
           :sprite-id nil
           :attack-timer 0
           :stun-timer 0
           :dot-timer 0
           :dot-dmg 0
           :dot-tick 0
           :hurt-timer 0
           :knockback-vx 0
           :knockback-vy 0
           :knockback-timer 0
           :path []
           :path-timer 0
           ;; Animations (grunt)
           :anim-timer (math.random 0 10)
           :anim-frame 1
           :direction :down
           :moving? false
           ;; Laser
           :laser-cooldown (+ 20 (math.random 0 20))
           :laser-windup 0
           :laser-dir-x 1
           :laser-dir-y 0
           :laser-end-x x
           :laser-end-y y
           :laser-flash 0
           ;; Kamikaze
           :kami-state :chase
           :kami-arming-timer 0
           :kami-explosion-timer 0
           :kami-did-damage false}]
    (if (= kind :laser)
        (do
          (set e.speed 0.45)
          (set e.hp 3)
          (set e.max-hp 3)
          (set e.sprite-id LASER-SPRITE-ID))
        (= kind :kamikaze)
        (do
          (set e.speed 0.7)
          (set e.hp 2)
          (set e.max-hp 2)
          (set e.sprite-id KAMIKAZE-SPRITE-ID))
        ;; grunt
        (do
          (set e.speed 0.5)
          (set e.hp 3)
          (set e.max-hp 3)
          (set e.sprite-id nil)))
    e))

;; =========================
;; Distance
;; =========================
(fn enemie.distance [e joueur]
  (math.sqrt
    (+ (* (- joueur.x e.x) (- joueur.x e.x))
       (* (- joueur.y e.y) (- joueur.y e.y)))))

;; =========================
;; IA
;; =========================
(fn enemie.update [e joueur world enemies take-damage]
  (local do-damage (or take-damage (fn [_ _] nil)))
  (process-dot e)
  (process-stun e)
  (tick-attack-cooldown e)
  (when (> e.hurt-timer 0)
    (set e.hurt-timer (- e.hurt-timer 1)))

  ;; Stun: reset animation
  (when (> e.stun-timer 0)
    (set e.moving? false))

  (if (> e.knockback-timer 0)
      (do
        (set e.moving? true)
        (apply-knockback-motion e world enemies joueur)
        (tick-anim-2 e))
      (when (<= e.stun-timer 0)
        (if (= e.type :laser)
            (update-laser e joueur world enemies do-damage)
            (= e.type :kamikaze)
            (update-kamikaze e joueur world enemies do-damage)
            (update-grunt e joueur world enemies do-damage)))))

;; =========================
;; Attaque (contact)
;; =========================
(fn enemie.attack [e joueur take-damage world]
  ;; Les mobs spéciaux attaquent via leurs patterns (laser / explosion)
  (when (or (= e.type :grunt) (= e.type nil))
    ;; On "gonfle" la hitbox de 1 pixel de chaque côté pour détecter le contact
    (when (and (world.collide? (- e.x 1) (- e.y 1) (+ e.size 2) joueur.x joueur.y joueur.size)
               (= e.attack-timer 0))
      (take-damage joueur 1 (center-x e) (center-y e))
      (set e.attack-timer 30) ;; cooldown (~0.5s)
      ;; Bouclier d'épines : renvoie des dégâts au moment de l'impact
      (when (= joueur.id-utility 2)
        (let [util (abilities.get-utility 2)]
          (enemie.take-damage e util.stats.reflect-damage))))))

;; =========================
;; Dégâts reçus
;; =========================
(fn enemie.take-damage [e dmg]
  (when (> dmg 0)
    (set e.hp (- e.hp dmg))
    (set e.hurt-timer HURT-FLASH-DURATION)))

(fn enemie.apply-dot [e dmg dur]
  (set e.dot-dmg dmg)
  (set e.dot-timer dur)
  (set e.dot-tick 0))

(fn enemie.apply-stun [e frames]
  (when (> frames e.stun-timer)
    (set e.stun-timer frames)))

(fn enemie.apply-knockback [e from-x from-y power]
  (let [cx (center-x e)
        cy (center-y e)
        dx (- cx from-x)
        dy (- cy from-y)
        len (math.sqrt (+ (* dx dx) (* dy dy)))]
    (when (> len 0.001)
      (let [strength (or power 2.6)]
        (set e.knockback-vx (* (/ dx len) strength))
        (set e.knockback-vy (* (/ dy len) strength))
        (set e.knockback-timer SWORD-KNOCKBACK-DURATION)
        ;; Petit stagger pour rendre l'impact lisible.
        (set e.stun-timer (math.max e.stun-timer 3))))))

(fn enemie.is-dead? [e]
  (<= e.hp 0))

;; =========================
;; Dessin
;; =========================
(fn draw-health [e x y]
  (let [ratio (/ (math.max e.hp 0) (math.max e.max-hp 1))]
    (rect x (- y 3) e.size 2 1)
    (rect x (- y 3)
          (math.floor (* e.size ratio)) 2 11)))

(fn draw-laser-telegraph [e]
  (when (> e.laser-windup 0)
    (line (center-x e) (center-y e)
          e.laser-end-x e.laser-end-y
          (if (= (% (// e.laser-windup 4) 2) 0) 8 12)))
  (when (> e.laser-flash 0)
    (line (center-x e) (center-y e)
          e.laser-end-x e.laser-end-y
          6)))

(fn draw-kamikaze-telegraph [e]
  (if (= e.kami-state :arming)
      (let [blink-color (if (= (% (// e.kami-arming-timer 4) 2) 0) 6 8)]
        (circb (center-x e) (center-y e) KAMIKAZE-EXPLOSION-RADIUS blink-color))
      (= e.kami-state :exploding)
      (do
        (circ (center-x e) (center-y e) KAMIKAZE-EXPLOSION-RADIUS 6)
        (circb (center-x e) (center-y e) KAMIKAZE-EXPLOSION-RADIUS 15))))

(fn enemie.draw [e]
  (let [x (math.floor e.x)
        y (math.floor e.y)]
    (if (= e.type :laser)
        (let [f (or e.anim-frame 1)
              sprite (if (not e.moving?) 191
                         (= e.direction :right) (if (= f 1) 192 193)
                         (= e.direction :left)  (if (= f 1) 195 196)
                         (if (= f 1) 198 199))]
          (draw-laser-telegraph e)
          (spr sprite x y 15)
          (draw-health e x y))
        (= e.type :kamikaze)
        (let [f (or e.anim-frame 1)
              sprite (if (not e.moving?) (if (= f 1) 181 182)
                         (= e.direction :right) (if (= f 1) 183 184)
                         (= e.direction :left)  (if (= f 1) 186 187)
                         (if (= f 1) 189 190))]
          (draw-kamikaze-telegraph e)
          (spr sprite x y 15)
          (draw-health e x y))
        ;; grunt : sprite animé
        (let [base-spr (if (not e.moving?) 111
                           (or (= e.direction :right) (= e.direction :down)) 113
                           (= e.direction :left) 116
                           119)
              final-spr (+ base-spr (- (or e.anim-frame 1) 1))]
          (spr final-spr x y 15)
          (draw-health e x y)))))

;; =========================
;; Export
;; =========================
enemie
