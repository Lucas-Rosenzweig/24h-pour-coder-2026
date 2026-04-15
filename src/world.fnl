;; -- Module Monde (World) --
(local M {})

;; --- 1. GÉNÉRATEUR DE SPRITES ---
(fn M.design-spr [id hex]
  (let [addr (+ 0x4000 (* id 32))]
    (for [i 1 64 2]
      (let [s1 (hex:sub i i) 
            s2 (hex:sub (+ i 1) (+ i 1))
            p1 (tonumber (if (= s1 "") "0" s1) 16)
            p2 (tonumber (if (= s2 "") "0" s2) 16)]
        (poke (+ addr (// (- i 1) 2)) (+ (* p2 16) p1))))))

;; --- 2. INITIALISATION DES ASSETS ---
(fn M.init-assets []
  ;; -- Palette --
  (poke 0x3FC0 20 40 20)   ;; 0: Vert Ombre
  (poke 0x3FC3 40 100 40)  ;; 1: Vert Sombre
  (poke 0x3FC6 80 160 60)  ;; 2: Vert Herbe
  (poke 0x3FC9 140 210 80) ;; 3: Vert Clair
  (poke 0x3FCC 60 30 20)   ;; 4: Brun Sombre
  (poke 0x3FCF 110 70 40)  ;; 5: Brun Moyen
  (poke 0x3FD2 160 110 70) ;; 6: Brun Clair
  (poke 0x3FE4 220 230 200) ;; C: Blanc

  ;; -- Sprites --
  (M.design-spr 2 "2222222222232222223322222222222222222222222223222222332222222222")
  (M.design-spr 10 "2222000022001111201133332013333301133333011333330111333301111111")
  (M.design-spr 11 "0000222211110022333311023333110233331102333311023333110211111102")
  (M.design-spr 12 "0111111120001111222205662222056622220566222204552222200022222222")
  (M.design-spr 13 "1111111011110002554022225540222255402222440022220022222222222222")
  (M.design-spr 20 "000CC00000CCCC000C000C000C333C0000333300005555000000000000000000"))

;; --- 3. MATRICE ---
(local map-v [
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 10 11 2 2 2 2 2 2 2 2 2 2 10 11 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 12 13 2 2 2 2 2 2 2 2 2 2 12 13 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 10 11 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 12 13 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 10 11 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 10 11 2 2 2 2 2 2 2]
  [2 2 2 12 13 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 12 13 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]
  [2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2]])

;; --- 4. LOGIQUE DES COLLISIONS ---

;; Vérifie si un pixel (x,y) est un obstacle
(fn M.wall? [x y]
  (if (< y 20) true ;; Zone réservée à l'UI
    (let [col (+ (// x 8) 1) 
          lig (+ (// (- y 20) 8) 1)]
      (let [ligne (. map-v lig)
            valeur (if ligne (. ligne col) 2)]
        (or (= valeur 12) (= valeur 13))))))

;; Gestion centralisée de la collision pour un rectangle (joueur)
(fn M.can-move? [x y size]
  (not (or (M.wall? x y)
           (M.wall? (+ x (- size 1)) y)
           (M.wall? x (+ y (- size 1)))
           (M.wall? (+ x (- size 1)) (+ y (- size 1))))))

;; Dessine toute la carte avec un décalage de 20px pour l'UI
(fn M.draw []
  (each [num-ligne ligne (ipairs map-v)]
    (each [num-col id (ipairs ligne)]
      (spr id (* (- num-col 1) 8) (+ 20 (* (- num-ligne 1) 8)) 0))))

M
