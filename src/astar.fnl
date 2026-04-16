;; -- Module A-Star Pathfinding --
(local M {})

;; Heuristique : distance pour 8 directions (Diagonale de Chebyshev / Octile)
(fn M.heuristic [x1 y1 x2 y2]
  (let [dx (math.abs (- x1 x2))
        dy (math.abs (- y1 y2))]
    (+ (* 10 (math.max dx dy)) (* 4 (math.min dx dy)))))

(fn M.find-path [start-x start-y target-x target-y walkable?]
  ;; Grille basée sur des "tuiles" de taille 8
  ;; On aligne les positions en pixels sur des pas de 8 pour les noeuds.
  (local step 8)
  
  (local sx (* (// (+ start-x (/ step 2)) step) step))
  (local sy (* (// (+ start-y (/ step 2)) step) step))
  (local gx (* (// (+ target-x (/ step 2)) step) step))
  (local gy (* (// (+ target-y (/ step 2)) step) step))
  
  (local open-list [])
  (local closed-set {})
  (local came-from {})
  (local g-score {})
  (local f-score {})
  
  (fn get-key [x y]
    (.. x "," y))
  
  (local start-key (get-key sx sy))
  
  (table.insert open-list {:x sx :y sy})
  (tset g-score start-key 0)
  (tset f-score start-key (M.heuristic sx sy gx gy))
  
  (var path nil)
  (var iter 0)
  (local max-iter 300) ;; Sécurité anti-lag pour les longs chemins
  
  (while (and (> (# open-list) 0) (not path) (< iter max-iter))
    (set iter (+ iter 1))
    
    ;; Récupérer l'élément avec le score F minimum
    (var current-idx 1)
    (var current (. open-list 1))
    (var min-f (or (. f-score (get-key current.x current.y)) 999999))
    
    (for [i 2 (# open-list)]
      (let [node (. open-list i)
            f (or (. f-score (get-key node.x node.y)) 999999)]
        (when (< f min-f)
          (set current-idx i)
          (set current node)
          (set min-f f))))
          
    (local cur-key (get-key current.x current.y))
    
    ;; Arrivée au but
    (if (and (= current.x gx) (= current.y gy))
        (do
          (local best-path [])
          (var curr-key cur-key)
          (while (. came-from curr-key)
            (let [p (. came-from curr-key)]
              (table.insert best-path 1 [p.to-x p.to-y])
              (set curr-key (get-key p.x p.y))))
          ;; On ajoute la coordonnée cible exacte en bout de chemin
          (table.insert best-path [target-x target-y])
          (set path best-path))
        
        ;; Exploration des voisins
        (do
          (table.remove open-list current-idx)
          (tset closed-set cur-key true)
          
          ;; Haut, Bas, Gauche, Droite, et Diagonales
          (local neighbors [[(- step) 0 10] [step 0 10] [0 (- step) 10] [0 step 10]
                            [(- step) (- step) 14] [step (- step) 14] 
                            [(- step) step 14] [step step 14]])
          
          (each [_ offset (ipairs neighbors)]
            (local nx (+ current.x (. offset 1)))
            (local ny (+ current.y (. offset 2)))
            (local cost (. offset 3))
            (local n-key (get-key nx ny))
            
            ;; Vérifier que le voisin est traversable et qu'on ne l'a pas déjà fermé
            (when (and (not (. closed-set n-key)) 
                       (walkable? nx ny))
              (local tentative-g (+ (. g-score cur-key) cost))
              (local old-g (or (. g-score n-key) 999999))
              
              (when (< tentative-g old-g)
                (tset came-from n-key {:x current.x :y current.y :to-x nx :to-y ny})
                (tset g-score n-key tentative-g)
                (tset f-score n-key (+ tentative-g (M.heuristic nx ny gx gy)))
                
                (var in-open false)
                (each [_ node (ipairs open-list)]
                  (when (and (= node.x nx) (= node.y ny))
                    (set in-open true)))
                
                (when (not in-open)
                  (table.insert open-list {:x nx :y ny}))))))))
                  
  (or path []))

M
