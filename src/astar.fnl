;; -- Module A-Star (Pathfinding) --
(local M {})

;; Heuristique : Distance de Manhattan entre deux cases (tiles)
(fn heuristic [x1 y1 x2 y2]
  (+ (math.abs (- x1 x2)) (math.abs (- y1 y2))))

;; Clé string pour les dictionnaires (ex: "5,12")
(fn make-key [x y]
  (.. x "," y))

;; Calcule et retourne une liste de points (pixels) menant à la cible
(fn M.find-path [sx sy tx ty wall?]
  (let [start-x (+ (// sx 8) 1)
        start-y (+ (// (- sy 20) 8) 1)
        target-x (+ (// tx 8) 1)
        target-y (+ (// (- ty 20) 8) 1)]

    (var path [])

    ;; Si la cible est déjà un mur, on s'arrête
    (if (wall? tx ty)
        path
        (do
          (var open-set [[start-x start-y]])
          (local came-from {})
          (local g-score {(make-key start-x start-y) 0})
          (local f-score {(make-key start-x start-y) (heuristic start-x start-y target-x target-y)})

          (fn get-score [score-map k]
            (or (. score-map k) 999999))

          (var found false)
          
          ;; Limite d'itérations pour ne pas freeze le jeu si bloqué
          (var iter 0)

          (while (and (> (length open-set) 0) (not found) (< iter 200))
            (set iter (+ iter 1))
            
            ;; Trouver le nœud avec le plus petit f-score
            (var current-idx 1)
            (var current-f (get-score f-score (make-key (. (. open-set 1) 1) (. (. open-set 1) 2))))
            
            (for [i 2 (length open-set)]
              (let [pt (. open-set i)
                    f (get-score f-score (make-key (. pt 1) (. pt 2)))]
                (when (< f current-f)
                  (set current-f f)
                  (set current-idx i))))

            (let [current (. open-set current-idx)
                  cx (. current 1)
                  cy (. current 2)
                  k (make-key cx cy)]
              
              (if (and (= cx target-x) (= cy target-y))
                  (set found true)
                  (do
                    (table.remove open-set current-idx)
                    
                    ;; Tester les 4 directions de la grille (Haut, Bas, Gauche, Droite)
                    (each [_ dir (ipairs [[0 -1] [0 1] [-1 0] [1 0]])]
                      (let [nx (+ cx (. dir 1))
                            ny (+ cy (. dir 2))
                            nk (make-key nx ny)
                            ;; Convertir la case visée en pixels (centre de la case) pour tester les collisions
                            px (+ (* (- nx 1) 8) 4)
                            py (+ (* (- ny 1) 8) 24)]
                            
                        (when (not (wall? px py))
                          (let [tentative-g (+ (get-score g-score k) 1)]
                            (when (< tentative-g (get-score g-score nk))
                              (tset came-from nk current)
                              (tset g-score nk tentative-g)
                              (tset f-score nk (+ tentative-g (heuristic nx ny target-x target-y)))
                              
                              ;; Ajouter à l'open set s'il n'y est pas
                              (var in-open false)
                              (each [_ p (ipairs open-set)]
                                (when (and (= (. p 1) nx) (= (. p 2) ny))
                                  (set in-open true)))
                              (when (not in-open)
                                (table.insert open-set [nx ny])))))))))))

          ;; Reconstruction du chemin
          (when found
            (var curr [target-x target-y])
            (while (and curr (not (and (= (. curr 1) start-x) (= (. curr 2) start-y))))
              ;; On ajoute au début de la liste
              (let [px (- (+ (* (- (. curr 1) 1) 8) 4) 4) ;; Position coin supérieur gauche (-4) pour compatibilité Spr
                    py (- (+ (* (- (. curr 2) 1) 8) 24) 4)]
                (table.insert path 1 [px py]))
              (set curr (. came-from (make-key (. curr 1) (. curr 2))))))
              
          path))))

M
