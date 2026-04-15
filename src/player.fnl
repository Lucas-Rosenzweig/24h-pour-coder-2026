;; -- Module Joueur --
(local player {})

;; -- Etat initial du joueur --
(fn player.new []
  {:x 120
   :y 68
   :size 8
   :speed 2
   :color 12
   :hp 10
   :max-hp 10
   })

;; -- Logique de deplacement --
(fn player.update [p]
  ;; Deplacement avec les fleches (btn 0=haut 1=bas 2=gauche 3=droite)
  (when (btn 0) (set p.y (- p.y p.speed)))
  (when (btn 1) (set p.y (+ p.y p.speed)))
  (when (btn 2) (set p.x (- p.x p.speed)))
  (when (btn 3) (set p.x (+ p.x p.speed)))

  ;; Limites de l'ecran (240x136)
  (when (< p.x 0) (set p.x 0))
  (when (< p.y 20) (set p.y 20))
  (when (> p.x (- 240 p.size)) (set p.x (- 240 p.size)))
  (when (> p.y (- 136 p.size)) (set p.y (- 136 p.size))))

;; -- Dessin --
(fn player.draw [p]
  (rect p.x p.y p.size p.size p.color))

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
player
