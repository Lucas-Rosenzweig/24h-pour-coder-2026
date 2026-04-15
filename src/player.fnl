;; -- Module Joueur --
(local player {})
(local abilities (include :abilities))

;; -- Etat initial du joueur --
(fn player.new []
  {:x 120
   :y 68
   :size 8
   :speed 2
   :color 12
   :hp 10
   :max-hp 10
   ;; Si id = -1 vide
   :id-sword-upgrades [0]
   :id-spell-upgrades {:id nil :applied-upgrades []}
   :id-utility -1
   })

;; -- Logique de déplacement avec collisions --
(fn player.update [p world]
  ;; On teste le mouvement sur chaque axe indépendamment pour glisser contre les murs
  
  ;; Axe Y (Haut/Bas)
  (let [dy (if (btn 0) (- p.speed) (if (btn 1) p.speed 0))]
    (when (not= dy 0)
      (if (world.can-move? p.x (+ p.y dy) p.size)
          (set p.y (+ p.y dy)))))
          
  ;; Axe X (Gauche/Droite)
  (let [dx (if (btn 2) (- p.speed) (if (btn 3) p.speed 0))]
    (when (not= dx 0)
      (if (world.can-move? (+ p.x dx) p.y p.size)
          (set p.x (+ p.x dx)))))

  ;; Limites de l'écran (Optionnel si la map est entourée de murs)
  (when (< p.x 0) (set p.x 0))
  (when (< p.y 20) (set p.y 20))
  (when (> p.x (- 240 p.size)) (set p.x (- 240 p.size)))
  (when (> p.y (- 136 p.size)) (set p.y (- 136 p.size)))

  ;; Mémoriser la direction de déplacement pour l'attaque
  (let [dx (if (btn 2) -1 (if (btn 3) 1 0))
        dy (if (btn 0) -1 (if (btn 1) 1 0))]
    (when (or (not= dx 0) (not= dy 0))
      (set p.facing-angle (math.atan2 dy dx)))))


;; -- Dessin du sprite joueur (ID 20) --
(fn player.draw [p]
  (spr 20 p.x p.y 0))

(fn player.take-damage [p dmg]
  (set p.hp (- p.hp dmg))
  
  ;; éviter hp négatif
  (when (< p.hp 0)
    (set p.hp 0)))

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

;; -- Debug : affiche le cône d'attaque --
(fn player.draw-attack-cone [p]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)
        facing (or p.facing-angle 0)
        half-arc (* (/ (math.max stats.arc 15) 2) (/ math.pi 180))
        cx (+ p.x (/ p.size 2))
        cy (+ p.y (/ p.size 2))
        r stats.range
        a1 (- facing half-arc)
        a2 (+ facing half-arc)]
    ;; Bords du cône
    (line cx cy (+ cx (* r (math.cos a1))) (+ cy (* r (math.sin a1))) 8)
    (line cx cy (+ cx (* r (math.cos a2))) (+ cy (* r (math.sin a2))) 8)
    ;; Arc entre les deux bords (approximé avec plusieurs segments)
    (for [i 0 7]
      (let [t1 (+ a1 (* (/ i 7) (* 2 half-arc)))
            t2 (+ a1 (* (/ (+ i 1) 7) (* 2 half-arc)))]
        (line (+ cx (* r (math.cos t1))) (+ cy (* r (math.sin t1)))
              (+ cx (* r (math.cos t2))) (+ cy (* r (math.sin t2)))
              8)))))

;;Attaque en utilisant les dégats de l'arme + les upgrades
(fn player.attack [p enemies enemie]
  (let [stats (abilities.compute-sword-stats p.id-sword-upgrades)
        facing (or p.facing-angle 0)
        ;; arc = 0 (ligne droite) -> tolérance de 15°, sinon arc/2
        half-arc (* (/ (math.max stats.arc 15) 2) (/ math.pi 180))]
    (each [_ e (ipairs enemies)]
      (let [dx (- e.x p.x)
            dy (- e.y p.y)
            dist (math.sqrt (+ (* dx dx) (* dy dy)))]
        (when (< dist stats.range)
          (let [angle-to-enemy (math.atan2 dy dx)
                diff (math.abs (- angle-to-enemy facing))
                ;; Normaliser entre 0 et pi
                norm-diff (if (> diff math.pi) (- (* 2 math.pi) diff) diff)]
            (when (<= norm-diff half-arc)
              (for [i 1 stats.hits]
                (enemie.take-damage e stats.damage)))))))))
player

