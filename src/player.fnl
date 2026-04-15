;; -- Module Joueur --
(local player {})

;; -- Etat initial du joueur --
(fn player.new []
  {:x 120
   :y 68
   :size 8
   :speed 2
   :color 12
   ;; Si id = -1 vide
   :id-sword-upgrades [0]
   :id-spell-upgrades -1
   :id-utility -1
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

player
