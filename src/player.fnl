;; -- Module Joueur --
(local player {})
(local abilities (include :abilities))

(local SLOT-BUMP-DURATION 6)
(local SLOT-PULSE-DURATION 10)
(local SLOT-MISSING-PULSE-DURATION 10)
(local HP-HIT-DURATION 12)
(local HP-HEAL-DURATION 12)
(local GOLD-POP-DURATION 20)
(local GOLD-SPEND-DURATION 14)
(local PLAYER-HIT-KNOCKBACK 6)

(fn random-choice [xs]
  (when (> (# xs) 0)
    (. xs (math.random 1 (# xs)))))

;; -- Etat initial du joueur --
(fn player.new []
  {:x 24
   :y 64
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
   :sword-cooldown 0
   :sword-flash 0
   :gold 0
   :gold-pop-timer 0
   :gold-spend-timer 0
   :sword-hits-left 0
   :sword-hit-due false
   :hp-display 10
   :hp-hit-timer 0
   :hp-heal-timer 0
   :slot-bump-attack 0
   :slot-bump-spell 0
   :slot-bump-utility 0
   :slot-ready-pulse-attack 0
   :slot-ready-pulse-spell 0
   :slot-ready-pulse-utility 0
   :slot-missing-pulse-spell 0
   :slot-missing-pulse-utility 0
   :last-sword-cooldown 1
   :last-spell-cooldown 1
   :last-utility-cooldown 1
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

  ;; Cooldowns + pulse quand l'action redevient disponible
  (let [prev-spell p.spell-cooldown
        prev-sword p.sword-cooldown
        prev-util p.utility-cooldown]
    (when (> p.spell-cooldown 0)
      (set p.spell-cooldown (- p.spell-cooldown 1)))
    (when (> p.sword-cooldown 0)
      (set p.sword-cooldown (- p.sword-cooldown 1)))
    (when (> p.utility-cooldown 0)
      (set p.utility-cooldown (- p.utility-cooldown 1)))
    (when (and (> prev-spell 0) (= p.spell-cooldown 0))
      (set p.slot-ready-pulse-spell SLOT-PULSE-DURATION))
    (when (and (> prev-sword 0) (= p.sword-cooldown 0))
      (set p.slot-ready-pulse-attack SLOT-PULSE-DURATION))
    (when (and (> prev-util 0) (= p.utility-cooldown 0))
      (set p.slot-ready-pulse-utility SLOT-PULSE-DURATION)))

  ;; I-frames
  (when (> p.i-frames 0)
    (set p.i-frames (- p.i-frames 1)))

  ;; Timers UI
  (when (> p.hp-hit-timer 0)
    (set p.hp-hit-timer (- p.hp-hit-timer 1)))
  (when (> p.hp-heal-timer 0)
    (set p.hp-heal-timer (- p.hp-heal-timer 1)))
  (when (> p.gold-pop-timer 0)
    (set p.gold-pop-timer (- p.gold-pop-timer 1)))
  (when (> p.gold-spend-timer 0)
    (set p.gold-spend-timer (- p.gold-spend-timer 1)))
  (when (> p.slot-bump-attack 0)
    (set p.slot-bump-attack (- p.slot-bump-attack 1)))
  (when (> p.slot-bump-spell 0)
    (set p.slot-bump-spell (- p.slot-bump-spell 1)))
  (when (> p.slot-bump-utility 0)
    (set p.slot-bump-utility (- p.slot-bump-utility 1)))
  (when (> p.slot-ready-pulse-attack 0)
    (set p.slot-ready-pulse-attack (- p.slot-ready-pulse-attack 1)))
  (when (> p.slot-ready-pulse-spell 0)
    (set p.slot-ready-pulse-spell (- p.slot-ready-pulse-spell 1)))
  (when (> p.slot-ready-pulse-utility 0)
    (set p.slot-ready-pulse-utility (- p.slot-ready-pulse-utility 1)))
  (when (> p.slot-missing-pulse-spell 0)
    (set p.slot-missing-pulse-spell (- p.slot-missing-pulse-spell 1)))
  (when (> p.slot-missing-pulse-utility 0)
    (set p.slot-missing-pulse-utility (- p.slot-missing-pulse-utility 1)))

  ;; Lissage barre de vie (rattrapage progressif)
  (when (= p.hp-display nil)
    (set p.hp-display p.hp))
  (let [delta (- p.hp p.hp-display)]
    (when (not= delta 0)
      (set p.hp-display (+ p.hp-display (* delta 0.3)))
      (when (< (math.abs (- p.hp p.hp-display)) 0.1)
        (set p.hp-display p.hp))))

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
  (let [walk-base (if (or (= p.direction :right) (= p.direction :down)) 102
                      (= p.direction :left) 105
                      108) ;; fallback pour :up
        walk-spr (+ walk-base (- (math.min p.anim-frame 3) 1))
        idle-spr (+ 100 (- (math.min p.anim-frame 2) 1))
        final-spr (if p.moving? walk-spr idle-spr)]
    (when (or (<= p.i-frames 0) (= (% (// p.i-frames 4) 2) 0))
      (spr final-spr p.x p.y 15))))

(fn player.add-gold [p amount]
  (set p.gold (+ p.gold amount))
  (set p.gold-pop-timer GOLD-POP-DURATION)
  (set p.gold-spend-timer 0))

(fn player.spend-gold [p amount]
  (set p.gold (math.max 0 (- p.gold amount)))
  (set p.gold-spend-timer GOLD-SPEND-DURATION))

(fn player.draw-gold-icon [x y]
  (spr 206 x y 15))

(fn player.draw-gold-ui [p]
  (let [label (tostring p.gold)
        text-width (* (# label) 6)
        icon-x (- 240 10 text-width 12)
        text-x (+ icon-x 11)
        lift (if (> p.gold-pop-timer 0) (math.floor (/ p.gold-pop-timer 6)) 0)
        color (if (> p.gold-spend-timer 0)
                  6
                  (> p.gold-pop-timer 0)
                  (if (= (% (// p.gold-pop-timer 2) 2) 0) 9 12)
                  12)]
    (player.draw-gold-icon icon-x (- 4 lift))
    (print label text-x (- 5 lift) color false 1 true)))

(fn apply-hit-knockback [p hit-x hit-y world]
  (when (and hit-x hit-y)
    (let [cx (+ p.x (/ p.size 2))
          cy (+ p.y (/ p.size 2))
          dx (- cx hit-x)
          dy (- cy hit-y)
          len (math.sqrt (+ (* dx dx) (* dy dy)))]
      (when (> len 0.001)
        (let [knx (/ dx len)
              kny (/ dy len)
              nx (math.max 0 (math.min (+ p.x (* knx PLAYER-HIT-KNOCKBACK)) (- 240 p.size)))
              ny (math.max 16 (math.min (+ p.y (* kny PLAYER-HIT-KNOCKBACK)) (- 136 p.size)))]
          (if world
              (do
                (when (world.can-move? nx p.y p.size)
                  (set p.x nx))
                (when (world.can-move? p.x ny p.size)
                  (set p.y ny)))
              (do
                (set p.x nx)
                (set p.y ny))))))))

(fn player.take-damage [p dmg hit-x hit-y world]
  (if (<= p.i-frames 0)
      (do
        (set p.hp (- p.hp dmg))
        (set p.i-frames 40)
        (set p.hp-hit-timer HP-HIT-DURATION)
        (set p.hp-heal-timer 0)
        (apply-hit-knockback p hit-x hit-y world)
        (when (< p.hp 0)
          (set p.hp 0))
        true)
      false))

(fn slot-bump-offset [timer]
  (if (> timer 0)
      (if (= (% timer 2) 0) -1 0)
      0))

(fn pulse-color [timer a b]
  (if (> timer 0)
      (if (= (% (// timer 2) 2) 0) a b)
      a))

(fn draw-slot-cooldown [x y cooldown max-cooldown]
  (when (> cooldown 0)
    (let [ratio (math.min 1 (/ cooldown (math.max max-cooldown 1)))
          h (math.max 1 (math.floor (* 10 ratio)))
          top (+ y 11 (- h))]
      (rect (+ x 1) top 10 h 1))))

(fn player.draw-ui [p]
  ;; === Barre HP ===
  (let [hp-ratio (/ (math.max p.hp-display 0) p.max-hp)
        hp-color (if (> p.hp-hit-timer 0)
                     (pulse-color p.hp-hit-timer 6 11)
                     (> p.hp-heal-timer 0)
                     (pulse-color p.hp-heal-timer 10 11)
                     11)
        border-color (if (> p.hp-hit-timer 0) 6 12)]
    (rect 5 5 50 6 1)
    (rect 5 5 (math.floor (* 50 hp-ratio)) 6 hp-color)
    (rectb 5 5 50 6 border-color))

  ;; === Slot Attack (épée — toujours équipé) ===
  (let [oy (slot-bump-offset p.slot-bump-attack)
        y (+ 2 oy)
        border (pulse-color p.slot-ready-pulse-attack 12 9)]
    (rect 60 y 12 12 0)
    (draw-slot-cooldown 60 y p.sword-cooldown p.last-sword-cooldown)
    (rectb 60 y 12 12 border)
    (spr 203 62 (+ y 2) 15))

  ;; === Slot Spell ===
  (let [has-spell (not= p.id-spell-upgrades.id nil)
        spell-sprite (if (= p.id-spell-upgrades.id 1) 200 204)
        oy (slot-bump-offset p.slot-bump-spell)
        y (+ 2 oy)
        border-base (if has-spell 12 13)
        border (if (> p.slot-missing-pulse-spell 0)
                   (pulse-color p.slot-missing-pulse-spell 8 6)
                   (pulse-color p.slot-ready-pulse-spell border-base 9))]
    (rect 74 y 12 12 0)
    (when has-spell
      (draw-slot-cooldown 74 y p.spell-cooldown p.last-spell-cooldown))
    (rectb 74 y 12 12 border)
    (when has-spell
      (spr spell-sprite 76 (+ y 2) 15)))

  ;; === Slot Utility ===
  (let [has-util (not= p.id-utility -1)
        util-sprite (if (= p.id-utility 1) 205 209)
        oy (slot-bump-offset p.slot-bump-utility)
        y (+ 2 oy)
        border-base (if has-util 12 13)
        border (if (> p.slot-missing-pulse-utility 0)
                   (pulse-color p.slot-missing-pulse-utility 8 6)
                   (pulse-color p.slot-ready-pulse-utility border-base 9))]
    (rect 88 y 12 12 0)
    (when has-util
      (draw-slot-cooldown 88 y p.utility-cooldown p.last-utility-cooldown))
    (rectb 88 y 12 12 border)
    (when has-util
      (spr util-sprite 90 (+ y 2) 15))))

(fn player.heal [p amount]
  (local old-hp p.hp)
  (set p.hp (+ p.hp amount))
  
  ;; ne pas dépasser max
  (when (> p.hp p.max-hp)
    (set p.hp p.max-hp))
  (when (> p.hp old-hp)
    (set p.hp-heal-timer HP-HEAL-DURATION)
    (set p.hp-hit-timer 0)))

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
      (do
        (table.insert p.id-sword-upgrades reward.id)
        (set p.slot-bump-attack SLOT-BUMP-DURATION)
        (set p.slot-ready-pulse-attack SLOT-PULSE-DURATION))
      (if (= reward.kind :spell)
        (do
          (tset p.id-spell-upgrades :id reward.id)
          (tset p.id-spell-upgrades :applied-upgrades [])
          (set p.slot-bump-spell SLOT-BUMP-DURATION)
          (set p.slot-ready-pulse-spell SLOT-PULSE-DURATION))
        (if (= reward.kind :spell-upgrade)
          (do
            (table.insert p.id-spell-upgrades.applied-upgrades reward.id)
            (set p.slot-bump-spell SLOT-BUMP-DURATION)
            (set p.slot-ready-pulse-spell SLOT-PULSE-DURATION))
          (when (= reward.kind :utility)
            (do
              (set p.id-utility reward.id)
              (set p.slot-bump-utility SLOT-BUMP-DURATION)
              (set p.slot-ready-pulse-utility SLOT-PULSE-DURATION))))))))

(fn player.feedback-action-status [p slot status]
  (when status
    (match slot
      :attack
      (when (= status :cooldown)
        (set p.slot-bump-attack SLOT-BUMP-DURATION)
        (set p.slot-ready-pulse-attack SLOT-PULSE-DURATION))

      :spell
      (if (= status :cooldown)
          (do
            (set p.slot-bump-spell SLOT-BUMP-DURATION)
            (set p.slot-ready-pulse-spell SLOT-PULSE-DURATION))
          (= status :missing)
          (do
            (set p.slot-bump-spell SLOT-BUMP-DURATION)
            (set p.slot-missing-pulse-spell SLOT-MISSING-PULSE-DURATION)))

      :utility
      (if (= status :cooldown)
          (do
            (set p.slot-bump-utility SLOT-BUMP-DURATION)
            (set p.slot-ready-pulse-utility SLOT-PULSE-DURATION))
          (= status :missing)
          (do
            (set p.slot-bump-utility SLOT-BUMP-DURATION)
            (set p.slot-missing-pulse-utility SLOT-MISSING-PULSE-DURATION)))

      _ nil)
    status))

;; Dash (utilitaire actif, déclenché par Z)
(fn player.use-utility [p world]
  (if (= p.id-utility -1)
      :missing
      (> p.utility-cooldown 0)
      :cooldown
      (let [util (abilities.get-utility p.id-utility)]
        (if (not= util.type :active)
            :missing
            (= p.id-utility 1)
            (let [facing (or p.facing-angle 0)
                  dist util.stats.distance
                  dx (math.cos facing)
                  dy (math.sin facing)
                  ;; Cherche la position la plus loin possible sans entrer dans un mur
                  (safe-x safe-y)
                  (do
                    (var bx p.x)
                    (var by p.y)
                    (var i 1)
                    (while (<= i dist)
                      (let [tx (math.max 0 (math.min (+ p.x (* i dx)) (- 240 p.size)))
                            ty (math.max 20 (math.min (+ p.y (* i dy)) (- 136 p.size)))]
                        (if (world.can-move? tx ty p.size)
                          (do (set bx tx) (set by ty))
                          (set i (+ dist 1))))
                      (set i (+ i 1)))
                    (values bx by))]
              (set p.x safe-x)
              (set p.y safe-y)
              (set p.i-frames util.stats.i-frames)
              (set p.utility-cooldown util.stats.cooldown)
              (set p.last-utility-cooldown util.stats.cooldown)
              :ok)
            :missing))))


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
          13)
    ;; Sillage : arc de a1 jusqu'à cur-angle
    (for [i 0 5]
      (let [t1 (+ a1 (* (/ i 6) swept))
            t2 (+ a1 (* (/ (+ i 1) 6) swept))]
        (line (+ cx (* r (math.cos t1))) (+ cy (* r (math.sin t1)))
              (+ cx (* r (math.cos t2))) (+ cy (* r (math.sin t2)))
              13)))))

;; Applique 1 hit de l'épée (appelé à la fin de chaque sweep)
(fn player.do-sword-hit [p enemies enemie]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)
        facing (or p.facing-angle 0)
        half-arc (* (/ (math.max stats.arc 15) 2) (/ math.pi 180))
        cx (+ p.x (/ p.size 2))
        cy (+ p.y (/ p.size 2))]
    (fn point-in-sector? [px py]
      (let [dx (- px cx)
            dy (- py cy)
            dist (math.sqrt (+ (* dx dx) (* dy dy)))]
        (if (> dist stats.range)
            false
            (let [angle-to-point (math.atan2 dy dx)
                  diff (math.abs (- angle-to-point facing))
                  norm-diff (if (> diff math.pi) (- (* 2 math.pi) diff) diff)]
              (<= norm-diff half-arc)))))
    (each [_ e (ipairs enemies)]
      (let [x e.x
            y e.y
            s e.size
            x2 (+ x s)
            y2 (+ y s)
            mid-x (+ x (/ s 2))
            mid-y (+ y (/ s 2))
            points [[mid-x mid-y]
                    [x y] [x2 y] [x y2] [x2 y2]
                    [mid-x y] [mid-x y2]
                    [x mid-y] [x2 mid-y]]]
        (var hit? false)
        ;; Si le joueur est déjà dans la hitbox, on considère que le hit passe.
        (when (and (>= cx x) (<= cx x2) (>= cy y) (<= cy y2))
          (set hit? true))
        (when (not hit?)
          (each [_ pt (ipairs points)]
            (when (and (not hit?) (point-in-sector? (. pt 1) (. pt 2)))
              (set hit? true))))
        (when hit?
          (enemie.take-damage e stats.damage)
          (when enemie.apply-knockback
            (enemie.apply-knockback e cx cy 2.8)))))))

;; Lance l'animation — les dégâts sont appliqués à la fin de chaque sweep
(fn player.attack [p enemies enemie]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)]
    (if (> p.sword-cooldown 0)
        :cooldown
        (do
      (set p.sword-flash 8)
      (set p.sword-hits-left stats.hits)
      (set p.sword-cooldown stats.cooldown)
      (set p.last-sword-cooldown stats.cooldown)
      :ok))))

;; Attaque de sort (ex: boule de feu, foudre)
(fn player.spell-attack [p enemies enemie projectiles lightning-flashes]
  (if (= p.id-spell-upgrades.id nil)
      :missing
      (> p.spell-cooldown 0)
      :cooldown
      (let [stats (abilities.compute-spell-stats p.id-spell-upgrades)
            facing (or p.facing-angle 0)
            cx (+ p.x (/ p.size 2))
            cy (+ p.y (/ p.size 2))]
        (set p.spell-cooldown stats.cooldown)
        (set p.last-spell-cooldown stats.cooldown)

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
                      ddx (- ex cx)
                      ddy (- ey cy)]
                  (table.insert lightning-flashes
                    {:x1 cx :y1 cy :x2 ex :y2 ey
                     :jx (/ (- ddy) 4)
                     :jy (/ ddx 4)
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
                                ddx (- nx lx)
                                ddy (- ny ly)]
                            (table.insert lightning-flashes
                              {:x1 lx :y1 ly :x2 nx :y2 ny
                               :jx (/ (- ddy) 4)
                               :jy (/ ddx 4)
                               :timer 8}))
                          (tset hit-set next-e true)
                          (set last-target next-e)
                          (set chains-left (- chains-left 1)))
                        (set chains-left 0)))))))
        :ok)))

player
