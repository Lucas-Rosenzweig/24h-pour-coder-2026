;; -- Module Joueur --
(local player {})

;; -- Etat initial du joueur --
(fn player.new []
  {:x 120
   :y 68
   :size 8
   :speed 2
   :color 12})

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
  (when (< p.y 0) (set p.y 0))
  (when (> p.x (- 240 p.size)) (set p.x (- 240 p.size)))
  (when (> p.y (- 136 p.size)) (set p.y (- 136 p.size))))

;; -- Dessin du sprite joueur (ID 20) --
(fn player.draw [p]
  (spr 20 p.x p.y 0))

player

