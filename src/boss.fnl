(local boss {})

(local BOSS-SIZE 16)
(local CONTACT-DAMAGE 1)
(local CONTACT-COOLDOWN 26)
(local CHARGE-SPEED 2.5)
(local DODGE-SPEED 2.0)

(fn clamp [v lo hi]
  (math.max lo (math.min hi v)))

(fn normalize [dx dy]
  (let [len (math.sqrt (+ (* dx dx) (* dy dy)))]
    (if (> len 0.001)
        [(/ dx len) (/ dy len)]
        [1 0])))

(fn move-safe [e world dx dy]
  (let [nx (+ e.x dx)
        ny (+ e.y dy)]
    (if (world.can-move? nx e.y e.size)
        (set e.x nx))
    (if (world.can-move? e.x ny e.size)
        (set e.y ny))))

(fn center-x [e]
  (+ e.x (/ e.size 2)))

(fn center-y [e]
  (+ e.y (/ e.size 2)))

(fn new-radial-burst [e]
  (local count 12)
  (local speed 1.3)
  (for [i 0 (- count 1)]
    (let [a (* (/ i count) 2 math.pi)
          vx (* speed (math.cos a))
          vy (* speed (math.sin a))]
      (table.insert e.projectiles
        {:x (center-x e)
         :y (center-y e)
         :vx vx
         :vy vy
         :life 140
         :radius 3
         :damage 1}))))

(fn begin-windup [e joueur]
  (set e.phase :windup)
  (set e.phase-timer 30)
  (set e.did-impact false)
  (set e.impact-flash 0)
  (set e.pattern-data {})
  (if (= e.pattern-index 1)
      (let [tx (+ joueur.x (/ joueur.size 2))
            ty (+ joueur.y (/ joueur.size 2))
            [nx ny] (normalize (- tx (center-x e)) (- ty (center-y e)))
            line-len 96]
        (set e.pattern-data
          {:vx (* nx CHARGE-SPEED)
           :vy (* ny CHARGE-SPEED)
           :line-x2 (+ (center-x e) (* nx line-len))
           :line-y2 (+ (center-y e) (* ny line-len))}))
      (= e.pattern-index 2)
      (set e.pattern-data {:burst-radius 26})
      (= e.pattern-index 3)
      (let [tx (clamp (+ joueur.x (/ joueur.size 2)) 20 220)
            ty (clamp (+ joueur.y (/ joueur.size 2)) 36 124)]
        (set e.pattern-data {:target-x tx :target-y ty :radius 18}))))

(fn begin-action [e]
  (set e.phase :action)
  (if (= e.pattern-index 1)
      (set e.phase-timer 22)
      (= e.pattern-index 2)
      (do
        (set e.phase-timer 24)
        (new-radial-burst e))
      (= e.pattern-index 3)
      (set e.phase-timer 12)))

(fn begin-recover [e]
  (set e.phase :recover)
  (set e.phase-timer 18))

(fn begin-dodge [e world]
  (var tries 0)
  (var picked false)
  (set e.dodge-vx 0)
  (set e.dodge-vy 0)
  (while (and (< tries 8) (not picked))
    (let [a (* (/ (math.random 0 360) 180) math.pi)
          vx (* (math.cos a) DODGE-SPEED)
          vy (* (math.sin a) DODGE-SPEED)
          tx (+ e.x vx)
          ty (+ e.y vy)]
      (set tries (+ tries 1))
      (when (world.can-move? tx ty e.size)
        (set picked true)
        (set e.dodge-vx vx)
        (set e.dodge-vy vy))))
  (set e.phase :dodge)
  (set e.phase-timer 12)
  (set e.invuln-timer 8))

(fn update-dot [e]
  (when (> e.dot-timer 0)
    (set e.dot-timer (- e.dot-timer 1))
    (set e.dot-tick (+ e.dot-tick 1))
    (when (>= e.dot-tick 60)
      (set e.dot-tick 0)
      (set e.hp (- e.hp e.dot-dmg)))
    (when (<= e.dot-timer 0)
      (set e.dot-dmg 0)
      (set e.dot-tick 0))))

(fn projectile-hit-player? [proj joueur world]
  (world.collide? (- proj.x proj.radius)
                  (- proj.y proj.radius)
                  (* proj.radius 2)
                  joueur.x
                  joueur.y
                  joueur.size))

(fn update-projectiles [e joueur world take-damage]
  (for [i (# e.projectiles) 1 -1]
    (let [proj (. e.projectiles i)]
      (set proj.x (+ proj.x proj.vx))
      (set proj.y (+ proj.y proj.vy))
      (set proj.life (- proj.life 1))
      (when (or (<= proj.life 0)
                (world.wall? proj.x proj.y))
        (set proj.dead true))
      (when (and (not proj.dead)
                 (projectile-hit-player? proj joueur world))
        (take-damage joueur proj.damage)
        (set proj.dead true))
      (when proj.dead
        (table.remove e.projectiles i)))))

(fn boss.new [x y]
  (let [e {:type :boss
           :x x
           :y y
           :size BOSS-SIZE
           :hp 55
           :max-hp 55
           :attack-timer 0
           :stun-timer 0
           :dot-timer 0
           :dot-dmg 0
           :dot-tick 0
           :invuln-timer 0
           :phase :windup
           :phase-timer 0
           :pattern-index 1
           :pattern-data {}
           :projectiles []
           :dodge-vx 0
           :dodge-vy 0
           :did-impact false
           :impact-flash 0}]
    (begin-windup e {:x (+ x 1) :y (+ y 1) :size 1})
    e))

(fn boss.update [e joueur world _ take-damage]
  (update-dot e)
  (update-projectiles e joueur world take-damage)

  (when (> e.attack-timer 0)
    (set e.attack-timer (- e.attack-timer 1)))
  (when (> e.invuln-timer 0)
    (set e.invuln-timer (- e.invuln-timer 1)))
  (when (> e.impact-flash 0)
    (set e.impact-flash (- e.impact-flash 1)))

  (when (> e.stun-timer 0)
    (set e.stun-timer (- e.stun-timer 1)))

  (when (<= e.stun-timer 0)
    (if (= e.phase :windup)
        (do
          (set e.phase-timer (- e.phase-timer 1))
          (when (<= e.phase-timer 0)
            (begin-action e)))
        (= e.phase :action)
        (do
          (if (= e.pattern-index 1)
              (move-safe e world e.pattern-data.vx e.pattern-data.vy)
              (= e.pattern-index 3)
              (when (and (not e.did-impact) (<= e.phase-timer 4))
                (set e.did-impact true)
                (set e.impact-flash 10)
                (let [dx (- (+ joueur.x (/ joueur.size 2)) e.pattern-data.target-x)
                      dy (- (+ joueur.y (/ joueur.size 2)) e.pattern-data.target-y)
                      dist (math.sqrt (+ (* dx dx) (* dy dy)))]
                  (when (<= dist e.pattern-data.radius)
                    (take-damage joueur 2)))))
          (set e.phase-timer (- e.phase-timer 1))
          (when (<= e.phase-timer 0)
            (begin-recover e)))
        (= e.phase :recover)
        (do
          (set e.phase-timer (- e.phase-timer 1))
          (when (<= e.phase-timer 0)
            (begin-dodge e world)))
        (= e.phase :dodge)
        (do
          (move-safe e world e.dodge-vx e.dodge-vy)
          (set e.phase-timer (- e.phase-timer 1))
          (when (<= e.phase-timer 0)
            (set e.pattern-index (+ e.pattern-index 1))
            (when (> e.pattern-index 3)
              (set e.pattern-index 1))
            (begin-windup e joueur))))))

(fn boss.attack [e joueur take-damage world]
  (when (and (world.collide? e.x e.y e.size joueur.x joueur.y joueur.size)
             (= e.attack-timer 0))
    (take-damage joueur CONTACT-DAMAGE)
    (set e.attack-timer CONTACT-COOLDOWN)))

(fn boss.take-damage [e dmg]
  (when (and (> dmg 0) (<= e.invuln-timer 0))
    (set e.hp (- e.hp dmg))))

(fn boss.apply-dot [e dmg dur]
  (set e.dot-dmg dmg)
  (set e.dot-timer dur)
  (set e.dot-tick 0))

(fn boss.apply-stun [e frames]
  (when (> frames e.stun-timer)
    (set e.stun-timer frames)))

(fn boss.is-dead? [e]
  (<= e.hp 0))

(fn draw-telegraph [e]
  (when (= e.phase :windup)
    (if (= e.pattern-index 1)
        (line (center-x e) (center-y e)
              e.pattern-data.line-x2 e.pattern-data.line-y2
              (if (< (% (// (time) 120) 2) 1) 12 8))
        (= e.pattern-index 2)
        (circb (center-x e) (center-y e) e.pattern-data.burst-radius 8)
        (= e.pattern-index 3)
        (do
          (circb e.pattern-data.target-x e.pattern-data.target-y e.pattern-data.radius 8)
          (circb e.pattern-data.target-x e.pattern-data.target-y 8 12))))
  (when (> e.impact-flash 0)
    (circ e.pattern-data.target-x e.pattern-data.target-y e.pattern-data.radius 6)))

(fn draw-projectiles [e]
  (each [_ proj (ipairs e.projectiles)]
    (circ (math.floor proj.x) (math.floor proj.y) proj.radius 8)
    (circb (math.floor proj.x) (math.floor proj.y) proj.radius 12)))

(fn boss.draw [e]
  (draw-telegraph e)
  (draw-projectiles e)
  (when (or (<= e.invuln-timer 0) (= (% e.invuln-timer 4) 0))
    (spr 27 e.x e.y 0)
    (spr 29 (+ e.x 8) e.y 0)
    (spr 28 e.x (+ e.y 8) 0)
    (spr 30 (+ e.x 8) (+ e.y 8) 0))

  ;; barre de vie boss
  (let [bar-w 28
        x (- e.x 6)
        y (- e.y 6)]
    (rect x y bar-w 3 1)
    (rect x y (math.floor (* bar-w (/ (math.max e.hp 0) e.max-hp))) 3 8)
    (rectb x y bar-w 3 0)))

boss
