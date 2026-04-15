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

;; --- 2. COLLISION / MAPS ---
(local map1-c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 1 1 0 0 0 1 1 1 1 0 1]
  [1 0 0 1 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 1 1 0 0 0 1 1 1 1 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 0 1]
  [1 0 0 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 1 1 0 0 0 0 1 1 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 0 0 1 1 1 1 0 0 0 1 1 1 1 1 0 0 0 1 1 1 1 1 0 0 1 1 1 1 1]
  [1 0 0 1 1 1 1 0 0 0 1 1 1 1 1 0 0 0 1 1 1 1 1 0 0 1 1 1 1 1]
  [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]])

(local map1-v [
  [5 4 0 1 9 9 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1]
  [3 2 99 8 8 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 2 6 6 6 6 6 3 99 99 99 99 2 6 6 6 6 6 3 99 99 99 2 6 6 6 3 3]
  [1 0 99 2 6 6 6 6 6 3 99 99 99 99 2 6 6 6 6 6 3 99 99 99 2 6 6 6 3 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 2 6 6 3 99 99 99 2 6 6 6 3 99 99 99 2 6 6 6 3 99 99 99 2 6 3 3]
  [1 0 99 2 6 6 3 99 99 99 2 6 6 6 3 99 99 99 2 6 6 6 3 99 99 99 2 6 3 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [1 0 99 2 6 6 6 3 99 99 2 6 6 6 6 3 99 99 2 6 6 6 6 3 99 99 2 6 6 6 3]
  [1 0 99 2 6 6 6 3 99 99 2 6 6 6 6 3 99 99 2 6 6 6 6 3 99 99 2 6 6 6 3]
  [1 0 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 99 3]
  [3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3]])

(var map-v [])
(local matrice-active map1-c)

(fn M.construire-map []
  (set map-v [])
  (each [num-ligne ligne (ipairs map1-v)]
    (let [new-ligne []]
      (each [num-col id (ipairs ligne)]
        (table.insert new-ligne
          (if (= id 99)
              (if (> (math.random 100) 70) 5 4)
              id)))
      (table.insert map-v new-ligne))))

;; --- 3. INITIALISATION DES ASSETS ---
(fn M.init-assets []
  ;; -- Palette --
  (poke 0x3FC0  68) (poke 0x3FC1  36) (poke 0x3FC2  52) ;; ID 0
  (poke 0x3FC3  20) (poke 0x3FC4  12) (poke 0x3FC5  28) ;; ID 1
  (poke 0x3FC6 133) (poke 0x3FC7  76) (poke 0x3FC8  48) ;; ID 2
  (poke 0x3FC9 210) (poke 0x3FCA 125) (poke 0x3FCB  44) ;; ID 3
  (poke 0x3FCC 133) (poke 0x3FCD  76) (poke 0x3FCE  48) ;; ID 4
  (poke 0x3FCF  52) (poke 0x3FD0 101) (poke 0x3FD1  36) ;; ID 5
  (poke 0x3FD2 208) (poke 0x3FD3  70) (poke 0x3FD4  72) ;; ID 6
  (poke 0x3FD5 117) (poke 0x3FD6 113) (poke 0x3FD7  97) ;; ID 7
  (poke 0x3FD8  89) (poke 0x3FD9 125) (poke 0x3FDA 206) ;; ID 8
  (poke 0x3FDB 210) (poke 0x3FDC 125) (poke 0x3FDD  44) ;; ID 9
  (poke 0x3FDE 133) (poke 0x3FDF 149) (poke 0x3FE0 161) ;; ID A
  (poke 0x3FE1 109) (poke 0x3FE2 170) (poke 0x3FE3  44) ;; ID B
  (poke 0x3FE4 210) (poke 0x3FE5 170) (poke 0x3FE6 153) ;; ID C
  (poke 0x3FE7 109) (poke 0x3FE8 194) (poke 0x3FE9 202) ;; ID D
  (poke 0x3FEA 218) (poke 0x3FEB 212) (poke 0x3FEC  94) ;; ID E
  (poke 0x3FED 222) (poke 0x3FEE 238) (poke 0x3FEF 214) ;; ID F

  ;; -- Sprites --

  ;; #442434
  ;; #140c1c
  ;; #854c30
  ;; #d27d2c

  ;; MUR
    ;; GAUCHE
      ;; bas
      (M.design-spr 0  "0010010100100110001001011110011000100101001111100010010100100110")
      ;; haut
      (M.design-spr 1  "0312201203122012031220120321111103122012031220120312201203122012")
  
    ;; DROITE
      ;; bas
      (M.design-spr 8  "0110010010100100011111001010010001100111101001000110010010100100")
      ;; haut
      (M.design-spr 9  "0000000033333333111121112222122222221222000010001111111122221222")

    ;; HAUT
      ;; bas
      (M.design-spr 10 "2102213021022130210221302102213011111230210221302102213021022130")
      ;; haut
      (M.design-spr 11 "3330000032233333322111110312322203133122031213000312203103122013")
  
    ;; BAS
      ;; bas
      (M.design-spr 16 "0101010110101010111111110010000000100000111111110000100000001000")
      ;; haut
      (M.design-spr 17 "2221222211111111000100002221222222212222111211113333333300000000")

  ;; ANGLES
    ;; HAUT-GAUCHE
      ;; bas droit
      (M.design-spr 2  "2100000012100000012111110010100000110100001010110010010100100110")
      ;; bas gauche
      (M.design-spr 3  "0321111103122012031220120312201203122012031220120312201203122012")
      ;; haut droite
      (M.design-spr 4  "0000000033333333211111111222222212222222100000001111111112222222")
      ;; haut gauche
      (M.design-spr 5  "3330000032233333322111110312322203133122031213000312203103122013")
  
  


  (M.design-spr 6  "8888888888888888888888888888888888888888888888888888888888888888")
  (M.design-spr 12 "000CC00000CCCC000C222C000CBBBC0000BBBB0000333300000110000000000000")

  (math.randomseed (tstamp))
  (M.construire-map))

;; --- 4. LOGIQUE DES COLLISIONS ---

;; Vérifie si un pixel (x,y) est un obstacle
(fn M.wall? [x y]
  (if (or (< y 20) (< x 0) (> x 239) (> y 135)) true ;; Zone réservée à l'UI ou hors écran
    (let [col (+ (// x 8) 1) 
          lig (+ (// (- y 20) 8) 1)]
      (let [ligne (. matrice-active lig)
            valeur (if ligne (. ligne col) 1)]
        (= valeur 1)))))

;; Gestion centralisée de la collision pour un rectangle contre un mur
(fn M.can-move? [x y size]
  (not (or (M.wall? x y)
           (M.wall? (+ x (- size 1)) y)
           (M.wall? x (+ y (- size 1)))
           (M.wall? (+ x (- size 1)) (+ y (- size 1))))))

;; Vérifie si deux entités se rentrent dedans (AABB)
(fn M.collide? [x1 y1 s1 x2 y2 s2]
  (and (< x1 (+ x2 s2))
       (> (+ x1 s1) x2)
       (< y1 (+ y2 s2))
       (> (+ y1 s1) y2)))

;; Dessine toute la carte avec un décalage de 20px pour l'UI
(fn M.draw []
  (each [num-ligne ligne (ipairs map-v)]
    (each [num-col id (ipairs ligne)]
      (spr id (* (- num-col 1) 8) (+ 20 (* (- num-ligne 1) 8)) 0))))

M

