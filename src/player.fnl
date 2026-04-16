;; -- Module Joueur --
(local player {})
(local abilities (include :abilities))

(fn random-choice [xs]
  (when (> (# xs) 0)
    (. xs (math.random 1 (# xs)))))

;; -- Etat initial du joueur --
(fn player.new []
  {:x 120
   :y 38
   :size 8
   :speed 2
   :color 12
   :hp 10
   :max-hp 10
   ;; Si id = -1 vide
   :id-sword-upgrades [0]
   :id-spell-upgrades {:id nil :applied-upgrades []}
   :id-utility -1
   :utility-cooldown 0
   :i-frames 0
   :spell-cooldown 0
   :sword-flash 0
   :sword-hits-left 0
   :sword-hit-due false
   ;; Animations
   :anim-timer 0
   :anim-frame 1
   :moving? false
   :direction :down})

;; -- Logique de déplacement avec collisions --
(fn player.update [p world enemies]
  
  ;; Petite fonction locale pour vérifier si on tape un ennemi
  (fn hit-enemy? [nx ny]
    (var hit false)
    (let [soft-size (- p.size 2)]
      (each [_ e (ipairs enemies)]
        (when (world.collide? (+ nx 1) (+ ny 1) soft-size e.x e.y e.size)
          (set hit true))))
    hit)

  ;; On teste le mouvement sur chaque axe indépendamment pour glisser contre les murs
  
  ;; Axe Y (Haut/Bas)
  (let [dy (if (btn 0) (- p.speed) (if (btn 1) p.speed 0))]
    (when (not= dy 0)
      (if (and (world.can-move? p.x (+ p.y dy) p.size)
               (not (hit-enemy? p.x (+ p.y dy))))
          (set p.y (+ p.y dy)))))
          
  ;; Axe X (Gauche/Droite)
  (let [dx (if (btn 2) (- p.speed) (if (btn 3) p.speed 0))]
    (when (not= dx 0)
      (if (and (world.can-move? (+ p.x dx) p.y p.size)
               (not (hit-enemy? (+ p.x dx) p.y)))
          (set p.x (+ p.x dx)))))

  ;; Limites de l'écran (Optionnel si la map est entourée de murs)
  (when (< p.x 0) (set p.x 0))
  (when (< p.y 16) (set p.y 16))
  (when (> p.x (- 240 p.size)) (set p.x (- 240 p.size)))
  (when (> p.y (- 136 p.size)) (set p.y (- 136 p.size)))

  ;; Mémoriser la direction de déplacement pour l'attaque
  (let [dx (if (btn 2) -1 (if (btn 3) 1 0))
        dy (if (btn 0) -1 (if (btn 1) 1 0))]
    (when (or (not= dx 0) (not= dy 0))
      (set p.facing-angle (math.atan2 dy dx))))

  ;; Décrémentation sword-flash, hit à la fin de chaque sweep
  (when (> p.sword-flash 0)
    (set p.sword-flash (- p.sword-flash 1))
    (when (= p.sword-flash 0)
      (set p.sword-hit-due true)
      (when (> p.sword-hits-left 1)
        (set p.sword-hits-left (- p.sword-hits-left 1))
        (set p.sword-flash 8))))

  ;; Cooldown sort
  (when (> p.spell-cooldown 0)
    (set p.spell-cooldown (- p.spell-cooldown 1)))

  ;; Cooldown utilitaire
  (when (> p.utility-cooldown 0)
    (set p.utility-cooldown (- p.utility-cooldown 1)))

  ;; I-frames
  (when (> p.i-frames 0)
    (set p.i-frames (- p.i-frames 1)))

  ;; Mise à jour animation
  (set p.anim-timer (+ p.anim-timer 1))
  (let [dx (if (btn 2) -1 (if (btn 3) 1 0))
        dy (if (btn 0) -1 (if (btn 1) 1 0))
        moving? (or (not= dx 0) (not= dy 0))]
    (set p.moving? moving?)
    (when moving?
      (if (> dx 0) (set p.direction :right)
          (< dx 0) (set p.direction :left)
          (> dy 0) (set p.direction :down)
          (< dy 0) (set p.direction :up)))

    (if moving?
        ;; Animation de marche -> 3 frames, vitesse 8
        (do
          (when (> p.anim-timer 8)
            (set p.anim-timer 0)
            (set p.anim-frame (+ p.anim-frame 1))
            (when (> p.anim-frame 3) (set p.anim-frame 1))))
        ;; Animation Idle (100, 101) -> 2 frames, vitesse 20
        (do
          (when (> p.anim-timer 20)
            (set p.anim-timer 0)
            (set p.anim-frame (+ p.anim-frame 1))
            (when (> p.anim-frame 2) (set p.anim-frame 1)))))))


;; -- Dessin du sprite joueur animé --
(fn player.draw [p]
  (let [base-spr (if (not p.moving?) 100
                     (or (= p.direction :right) (= p.direction :down)) 102
                     (= p.direction :left) 105
                     108) ;; fallback pour :up
        final-spr (+ base-spr (- p.anim-frame 1))]
    (when (or (<= p.i-frames 0) (= (% (// p.i-frames 4) 2) 0))
      (spr final-spr p.x p.y 15))))

(fn player.take-damage [p dmg]
  (when (<= p.i-frames 0)
    (set p.hp (- p.hp dmg))
    (set p.i-frames 30)
    (when (< p.hp 0)
      (set p.hp 0))))

(fn player.draw-ui [p]
  ;; fond
  (rect 5 5 50 6 1)
  
  ;; vie actuelle
  (rect 5 5 (* 50 (/ p.hp p.max-hp)) 6 11)
  
  ;; contour
  (rectb 5 5 50 6 12))

(fn player.heal [p amount]
  (set p.hp (+ p.hp amount))
  
  ;; ne pas dépasser max
  (when (> p.hp p.max-hp)
    (set p.hp p.max-hp)))

(fn player.get-random-reward [p]
  (let [choices []
        sword-id (random-choice (abilities.get-all-sword-upgrade-ids))
        spell-id p.id-spell-upgrades.id
        spell-upgrade-ids (abilities.get-available-spell-upgrade-ids p.id-spell-upgrades)
        utility-ids []]
    (when sword-id
      (table.insert choices
        {:kind :sword-upgrade
         :id sword-id
         :data (abilities.get-sword-upgrade sword-id)}))
    (if (= spell-id nil)
      (let [new-spell-id (random-choice (abilities.get-all-spell-ids))]
        (when new-spell-id
          (table.insert choices
            {:kind :spell
             :id new-spell-id
             :data (abilities.get-spell new-spell-id)})))
      (let [spell-upgrade-id (random-choice spell-upgrade-ids)]
        (when spell-upgrade-id
          (table.insert choices
            {:kind :spell-upgrade
             :spell-id spell-id
             :id spell-upgrade-id
             :data (abilities.get-spell-upgrade spell-id spell-upgrade-id)}))))
    (each [_ id (ipairs (abilities.get-all-utility-ids))]
      (when (not= id p.id-utility)
        (table.insert utility-ids id)))
    (let [utility-id (random-choice utility-ids)]
      (when utility-id
        (table.insert choices
          {:kind :utility
           :id utility-id
           :data (abilities.get-utility utility-id)})))
    (random-choice choices)))

(fn player.apply-reward [p reward]
  (when reward
    (if (= reward.kind :sword-upgrade)
      (table.insert p.id-sword-upgrades reward.id)
      (if (= reward.kind :spell)
        (do
          (tset p.id-spell-upgrades :id reward.id)
          (tset p.id-spell-upgrades :applied-upgrades []))
        (if (= reward.kind :spell-upgrade)
          (table.insert p.id-spell-upgrades.applied-upgrades reward.id)
          (when (= reward.kind :utility)
            (set p.id-utility reward.id)))))))

;; Dash (utilitaire actif, déclenché par Z)
(fn player.use-utility [p world]
  (when (and (not= p.id-utility -1) (<= p.utility-cooldown 0))
    (let [util (abilities.get-utility p.id-utility)]
      (when (= util.type :active)
        (when (= p.id-utility 1)
          (let [facing (or p.facing-angle 0)
                dist util.stats.distance
                nx (+ p.x (* dist (math.cos facing)))
                ny (+ p.y (* dist (math.sin facing)))]
            (set p.x (math.max 0 (math.min nx (- 240 p.size))))
            (set p.y (math.max 20 (math.min ny (- 136 p.size))))
            (set p.i-frames util.stats.i-frames)
            (set p.utility-cooldown util.stats.cooldown)))))))


;; -- Debug : affiche le cône d'attaque --
;; -- Animation sweep épée --
(fn player.draw-attack-cone [p]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)
        facing (or p.facing-angle 0)
        half-arc (* (/ (math.max stats.arc 15) 2) (/ math.pi 180))
        cx (+ p.x (/ p.size 2))
        cy (+ p.y (/ p.size 2))
        r stats.range
        a1 (- facing half-arc)
        ;; progression 0→1 au fil des frames (sword-flash décroit de 8 à 0)
        progress (/ (- 8 p.sword-flash) 8)
        swept (* progress 2 half-arc)
        cur-angle (+ a1 swept)]
    ;; Ligne principale qui balaie
    (line cx cy
          (+ cx (* r (math.cos cur-angle)))
          (+ cy (* r (math.sin cur-angle)))
          12)
    ;; Sillage : arc de a1 jusqu'à cur-angle
    (for [i 0 5]
      (let [t1 (+ a1 (* (/ i 6) swept))
            t2 (+ a1 (* (/ (+ i 1) 6) swept))]
        (line (+ cx (* r (math.cos t1))) (+ cy (* r (math.sin t1)))
              (+ cx (* r (math.cos t2))) (+ cy (* r (math.sin t2)))
              12)))))

;; Applique 1 hit de l'épée (appelé à la fin de chaque sweep)
(fn player.do-sword-hit [p enemies enemie]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)
        facing (or p.facing-angle 0)
        half-arc (* (/ (math.max stats.arc 15) 2) (/ math.pi 180))
        cx (+ p.x (/ p.size 2))
        cy (+ p.y (/ p.size 2))]
    (each [_ e (ipairs enemies)]
      (let [dx (- (+ e.x (/ e.size 2)) cx)
            dy (- (+ e.y (/ e.size 2)) cy)
            dist (math.sqrt (+ (* dx dx) (* dy dy)))]
        (when (< dist stats.range)
          (let [angle-to-enemy (math.atan2 dy dx)
                diff (math.abs (- angle-to-enemy facing))
                norm-diff (if (> diff math.pi) (- (* 2 math.pi) diff) diff)]
            (when (<= norm-diff half-arc)
              (enemie.take-damage e stats.damage))))))))

;; Lance l'animation — les dégâts sont appliqués à la fin de chaque sweep
(fn player.attack [p enemies enemie]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)]
    (set p.sword-flash 8)
    (set p.sword-hits-left stats.hits)))

;; Attaque de sort (ex: boule de feu, foudre)
(fn player.spell-attack [p enemies enemie projectiles lightning-flashes]
  (when (and (not= p.id-spell-upgrades.id nil)
             (<= p.spell-cooldown 0))
    (let [stats (abilities.compute-spell-stats p.id-spell-upgrades)
          facing (or p.facing-angle 0)
          cx (+ p.x (/ p.size 2))
          cy (+ p.y (/ p.size 2))]
      (set p.spell-cooldown stats.cooldown)

      (if (= p.id-spell-upgrades.id 1)
        ;; === BOULE DE FEU ===
        (let [total stats.projectiles
              spread-rad (* (or stats.spread 0) (/ math.pi 180))
              start-angle (if (> total 1)
                            (- facing (* spread-rad 0.5))
                            facing)
              step (if (> total 1)
                     (/ spread-rad (- total 1))
                     0)]
          (for [i 0 (- total 1)]
            (let [angle (+ start-angle (* i step))]
              (table.insert projectiles
                {:x cx :y cy
                 :vx (* stats.speed (math.cos angle))
                 :vy (* stats.speed (math.sin angle))
                 :damage stats.damage
                 :radius stats.radius
                 :aoe (or stats.aoe 0)
                 :dot (or stats.dot 0)
                 :dot-dur (or stats.dot-dur 0)
                 :alive true
                 :lifetime 120}))))

        ;; === FOUDRE ===
        (do
          (local range 80)
          (var best-e nil)
          (var best-dist 9999)
          (each [_ e (ipairs enemies)]
            (let [dx (- e.x cx)
                  dy (- e.y cy)
                  dist (math.sqrt (+ (* dx dx) (* dy dy)))]
              (when (and (< dist range) (< dist best-dist))
                (set best-e e)
                (set best-dist dist))))
          (when best-e
            (enemie.take-damage best-e stats.damage)
            (when (> stats.stun 0)
              (enemie.apply-stun best-e stats.stun))
            ;; Flash joueur → premier ennemi
            (let [ex (+ best-e.x (/ best-e.size 2))
                  ey (+ best-e.y (/ best-e.size 2))
                  ddx (- ex cx) ddy (- ey cy)]
              (table.insert lightning-flashes
                {:x1 cx :y1 cy :x2 ex :y2 ey
                 :jx (/ (- ddy) 4) :jy (/ ddx 4)
                 :timer 8}))
            (when (> stats.chain 0)
              (local hit-set {})
              (tset hit-set best-e true)
              (var last-target best-e)
              (var chains-left stats.chain)
              (while (> chains-left 0)
                (var next-e nil)
                (var next-dist 9999)
                (each [_ e (ipairs enemies)]
                  (when (not (. hit-set e))
                    (let [dx (- e.x last-target.x)
                          dy (- e.y last-target.y)
                          dist (math.sqrt (+ (* dx dx) (* dy dy)))]
                      (when (and (< dist 40) (< dist next-dist))
                        (set next-e e)
                        (set next-dist dist)))))
                (if next-e
                  (do
                    (enemie.take-damage next-e stats.damage)
                    (when (> stats.stun 0)
                      (enemie.apply-stun next-e stats.stun))
                    ;; Flash ennemi → ennemi (chain)
                    (let [lx (+ last-target.x (/ last-target.size 2))
                          ly (+ last-target.y (/ last-target.size 2))
                          nx (+ next-e.x (/ next-e.size 2))
                          ny (+ next-e.y (/ next-e.size 2))
                          ddx (- nx lx) ddy (- ny ly)]
                      (table.insert lightning-flashes
                        {:x1 lx :y1 ly :x2 nx :y2 ny
                         :jx (/ (- ddy) 4) :jy (/ ddx 4)
                         :timer 8}))
                    (tset hit-set next-e true)
                    (set last-target next-e)
                    (set chains-left (- chains-left 1)))
                  (set chains-left 0))))))))))

player

