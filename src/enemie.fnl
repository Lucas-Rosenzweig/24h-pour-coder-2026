(local enemie {})

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
   
   })

;; =========================
;; Distance
;; =========================
(fn enemie.distance [e joueur]
  (math.sqrt
    (+ (* (- joueur.x e.x) (- joueur.x e.x))
       (* (- joueur.y e.y) (- joueur.y e.y)))))

;; =========================
;; IA : suit le joueur
;; =========================
(fn enemie.update [e joueur]
  (var dx (- joueur.x e.x))
  (var dy (- joueur.y e.y))

  (local dist (math.sqrt (+ (* dx dx) (* dy dy))))

  ;; normalisation
  (when (> dist 0)
    (set dx (/ dx dist))
    (set dy (/ dy dist)))

  ;; déplacement
  (set e.x (+ e.x (* dx e.speed)))
  (set e.y (+ e.y (* dy e.speed)))

  ;; cooldown attaque
  (when (> e.attack-timer 0)
    (set e.attack-timer (- e.attack-timer 1))))

;; =========================
;; Collision
;; =========================
(fn enemie.collide? [e joueur]
  (and (< (math.abs (- e.x joueur.x)) e.size)
       (< (math.abs (- e.y joueur.y)) e.size)))

;; =========================
;; Attaque
;; =========================
(fn enemie.attack [e joueur take-damage]
  (when (and (enemie.collide? e joueur)
             (= e.attack-timer 0))
    
    (take-damage joueur 1)
    (set e.attack-timer 30))) ;; cooldown (~0.5s)

;; =========================
;; Dégâts reçus
;; =========================
(fn enemie.take-damage [e dmg]
  (set e.hp (- e.hp dmg)))

(fn enemie.is-dead? [e]
  (<= e.hp 0))

;; =========================
;; Dessin
;; =========================
(fn enemie.draw [e]
  (let [x (math.floor e.x)
        y (math.floor e.y)]
    (rect x y e.size e.size e.color)
    (rectb x y e.size e.size 0)

    ;; petite barre de vie
    (rect x (- y 3) e.size 2 1)
    (rect x (- y 3)
          (* e.size (/ e.hp 3)) 2 11)))

;; =========================
;; Export
;; =========================
enemie