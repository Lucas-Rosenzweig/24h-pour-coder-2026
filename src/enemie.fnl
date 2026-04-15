(local enemie {})
(local astar (include :astar))
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
;; IA : Pathfinding A-Star "Pixe-Perfect"
;; =========================
(fn enemie.update [e joueur world enemies]
  
  ;; Variables d'état pour le pathfinding cache
  (when (not e.path) (set e.path []))
  (when (not e.path-timer) (set e.path-timer 0))

  (set e.path-timer (- e.path-timer 1))

  ;; Recalculer le chemin complet toutes les 60 frames (~ 1 sec)
  (when (<= e.path-timer 0)
    (set e.path (astar.find-path e.x e.y joueur.x joueur.y world.wall?))
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
        
        ;; Tolérance d'arrivée. Quand l'ennemi le touche, on se "snap" sur la grille.
        ;; Cela évite d'être décalé d'un demi-pixel et d'accrocher les murs dans les virages.
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
    
    (var moved false)
    
    ;; Mouvement X
    (when (and (not= dx 0)
               (world.can-move? nx e.y e.size)
               (not (world.collide? nx e.y e.size joueur.x joueur.y joueur.size))
               (not (hit-other-enemie? nx e.y)))
      (set e.x nx)
      (set moved true))
      
    ;; Mouvement Y
    (when (and (not= dy 0)
               (world.can-move? e.x ny e.size)
               (not (world.collide? e.x ny e.size joueur.x joueur.y joueur.size))
               (not (hit-other-enemie? e.x ny)))
      (set e.y ny)
      (set moved true))
      
    ;; Si l'ennemi voulait bouger mais s'est retrouvé bloqué (autre ennemi par ex),
    ;; on force un recalcul immédiat du chemin pour l'aider à s'en sortir.
    (when (and (not moved) (or (not= dx 0) (not= dy 0)))
      (set e.path-timer 0)))

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