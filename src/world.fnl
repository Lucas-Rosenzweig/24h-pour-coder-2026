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
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 1 1 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]])

(local map1-v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 36 32 32 32 32 37 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 35 31 31 31 31 34 24 24 24 24 24 24 27 29 24 24 24 24  2  3]
  [ 1  0 24 24 24 27 29 24 24 24 35 31 31 31 31 31 32 37 24 24 24 24 28 30 24 24 24 24  2  3]
  [ 1  0 24 24 24 28 30 24 24 24 35 31 31 31 31 31 31 34 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 35 31 31 31 31 31 33 39 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 38 33 33 33 33 39 24 24 27 29 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 26 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 25 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]
])

(local map2-c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 1 1 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]])

(local map2-v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 36 32 32 32 32 37 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 35 31 31 31 31 34 24 24 24 24 24 24 24 27 29 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 35 31 31 31 31 31 32 37 24 24 24 24 24 28 30 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 27 29 24 35 31 31 31 31 31 31 34 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 28 30 24 35 31 31 31 31 31 31 34 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 38 33 33 33 33 33 33 39 24 24 27 29 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 26 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 25 24 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]
])
(var map-v [])
(var matrice-active map1-c)
(set M.current-map-id 1)

(fn M.load-map [map-id]
  (set M.current-map-id map-id)
  (set M.door-open false)
  (set map-v [])
  (if (= map-id 1)
      (do
        (set matrice-active map1-c)
        (each [_ ligne (ipairs map1-v)]
          (let [new-ligne []]
            (each [_ id (ipairs ligne)]
              (table.insert new-ligne id))
            (table.insert map-v new-ligne))))
      (= map-id 2)
      (do
        (set matrice-active map2-c)
        (each [_ ligne (ipairs map2-v)]
          (let [new-ligne []]
            (each [_ id (ipairs ligne)]
              (table.insert new-ligne id))
            (table.insert map-v new-ligne))))))

(fn M.construire-map []
  (M.load-map 1))

(fn M.open-door []
  (set M.door-open true)
  ;; Mettre à jour les sprites de la porte sur la carte (col 29)
  (each [lig ligne (ipairs matrice-active)]
    (when (= (. ligne 29) 2)
      (tset (. map-v lig) 29 44)))) ;; 44 = open door

(fn walkable-rect? [x y size]
  (and (not (M.wall? x y))
       (not (M.wall? (+ x (- size 1)) y))
       (not (M.wall? x (+ y (- size 1))))
       (not (M.wall? (+ x (- size 1)) (+ y (- size 1))))))

(fn find-safe-fallback-spawn [size]
  (var found nil)
  (for [lig 3 13]
    (for [col 3 27]
      (when (not found)
        (let [x (* (- col 1) 8)
              y (+ 16 (* (- lig 1) 8))]
          (when (walkable-rect? x y size)
            (set found {:x x :y y}))))))
  (or found {:x 120 :y 72}))

;; Retourne un point de spawn pour une récompense devant la porte de sortie.
;; Le résultat est toujours un point walkable (fallback au centre de la salle).
(fn M.get-door-reward-spawn [size]
  (var sum-col 0)
  (var sum-lig 0)
  (var count 0)
  (each [lig ligne (ipairs matrice-active)]
    (each [col valeur (ipairs ligne)]
      (when (= valeur 2)
        (set sum-col (+ sum-col col))
        (set sum-lig (+ sum-lig lig))
        (set count (+ count 1)))))
  (if (> count 0)
      (let [door-col (// sum-col count)
            door-lig (/ sum-lig count)
            door-center-y (+ 16 (* (- door-lig 1) 8) 4)
            base-y (math.floor (- door-center-y (/ size 2)))
            base-x (* (- door-col 2) 8)
            candidates [{:x base-x :y base-y}
                        {:x (- base-x 8) :y base-y}
                        {:x (- base-x 16) :y base-y}
                        {:x base-x :y (- base-y 8)}
                        {:x base-x :y (+ base-y 8)}]
            fallback (find-safe-fallback-spawn size)]
        (var chosen nil)
        (each [_ candidate (ipairs candidates)]
          (when (and (not chosen)
                     (walkable-rect? candidate.x candidate.y size))
            (set chosen candidate)))
        (or chosen fallback))
      (find-safe-fallback-spawn size)))

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
      (M.design-spr 2  "0110010010100100011111001010010001100111101001000110010010100100")
      ;; haut
      (M.design-spr 3  "2102213021022130210221302102213011111230210221302102213021022130")

    ;; HAUT
      ;; bas
      (M.design-spr 4 "0000100000001000111111110010000000100000111111111010101001010101")
      ;; haut
      (M.design-spr 5 "0000000033333333111121112222122222221222000010001111111122221222")
  
    ;; BAS
      ;; bas
      (M.design-spr 6 "1010101001010101111111110000010000000100111111110001000000010000")
      ;; haut
      (M.design-spr 7 "2221222211111111000100002221222222212222111211113333333300000000")

  ;; ANGLES
    ;; HAUT-GAUCHE
      ;; bas droit
      (M.design-spr 8  "2100000012100000012111110010100000110100001010110010010100100110")
      ;; bas gauche
      (M.design-spr 9  "0321111103122012031220120312201203122012031220120312201203122012")
      ;; haut droite
      (M.design-spr 10  "0000000033333333211111111222222212222222100000001111111112222222")
      ;; haut gauche
      (M.design-spr 11  "3330000032233333322111110312322203133122031213000312203103122013")
  
    ;; HAUT-DROITE
      ;; bas droit
      (M.design-spr 12  "1111123021022130210221302102213021022130210221302102213021022130")
      ;; bas gauche
      (M.design-spr 13  "0000001200000121111112100001010000101100110101001010010001100100")
      ;; haut droit
      (M.design-spr 14 "0000033333333223111112232223213022133130003121301302213031022130")
      ;; haut gauche
      (M.design-spr 15 "0000000033333333111111122222222122222221000000011111111122222221")
    
    ;; BAS-DROITE
      ;; bas droit
      (M.design-spr 16 "3102213013022130003121302213313022232130111112233333322300000333")
      ;; bas gauche
      (M.design-spr 17 "2222222111111111000000012222222122222221111111123333333300000000")
      ;; haut droit
      (M.design-spr 18 "2102213021022130210221302102213021022130210221302102213011111230")
      ;; haut gauche
      (M.design-spr 19 "0110010010100100110101000010110000010100111112100000012100000012")
    
    ;; BAS-GAUCHE
      ;; bas droit
      (M.design-spr 20 "1222222211111111100000001222222212222222211111113333333300000000")
      ;; bas gauche
      (M.design-spr 21 "0312201303122031031213000313312203123222322111113223333333300000")
      ;; haut droit
      (M.design-spr 22 "0010011000100101001010110011010000101000012111111210000021000000")
      ;; haut gauche
      (M.design-spr 23 "0312201203122012031220120312201203122012031220120312201203211111")
  
  ;; SOL
    ;; vide
    (M.design-spr 24 "0000000000000000000000000000000000000000000000000000000000000000")
    ;; petit cailloux
    (M.design-spr 25 "0000000000001110010000000100000001000000010000100000001000000000")
    ;; gros cailloux
    (M.design-spr 26 "0000000000010110000000010100000100000011011111110011111000000000")
  
  ;; OBSTACLE
    ;; ROCHER 
      ;; haut gauche
      (M.design-spr 27 "0000000000000000000000110000113300113333001333330010333200100022")
      ;; bas gauche
      (M.design-spr 28 "0132222213332222113333321112222211022222110022221110022101112211")
      ;; haut droit
      (M.design-spr 29 "0000000000000000111100003333100033332100333221002222210022222100")
      ;; bas droit
      (M.design-spr 30 "2223331022333331222223110000211100022221002222011022001111201111")
    ;; TROU
      ;; RIEN
      (M.design-spr 31 "1111111111111111111111111111111111111111111111111111111111111111")
      ;; HAUT
      (M.design-spr 32 "0022220022000022001111001120001112111102111101111001101111111111")
      ;; BAS
      (M.design-spr 33 "1111111111111111111111111111111111111111111111111122211122000222")
      ;; DROIT
      (M.design-spr 34 "1111112011111120111111121111111211111112111111121111112011111120")
      ;; GAUCHE
      (M.design-spr 35 "0211111102111111211111112111111121111111211111110211111102111111")
      ;; HAUT GAUCHE VIDE
      (M.design-spr 36 "0000222200220000002111110201121202011212210110112111111121111010")
      ;; HAUT DROIT VIDE
      (M.design-spr 37 "2222000000002200111112002121102021211020110110121111111201011112")
      ;; BAS GAUCHE VIDE
      (M.design-spr 38 "2111111121111111211111110211111102111111002111110022111100002222")
      ;; BAS DROIT VIDE
      (M.design-spr 39 "1111111211111112111111121111111211111120111112201112200022200000")
      ;; HAUT GAUCHE PLEIN
      (M.design-spr 40 "0000000200000002000000020000002100000021000022000002211222200121")
      ;; HAUT DROIT PLEIN
      (M.design-spr 41 "2000000020000000200000001200000012000000002200002112200012100222")
      ;; BAS GAUCHE PLEIN
      (M.design-spr 42 "2221111100022111000022110000002100000021000000020000000200000002")
      ;; BAS DROIT PLEIN
      (M.design-spr 43 "1111122211122000112200001200000012000000200000002000000020000000")
      
      ;; PORTE OUVERTE MUR DROIT (ID 44)
      (M.design-spr 44 "1111111100000000000000000000000000000000000000000000000000000000")
      ;; PORTE FERMEE MUR DROIT (ID 45)
      (M.design-spr 45 "2222222210000001100000011111111111111111100000011000000101111110")

  (math.randomseed (tstamp))
  (M.construire-map))


;; --- 4. LOGIQUE DES COLLISIONS ---

;; Vérifie si un pixel (x,y) est un obstacle
(fn M.wall? [x y]
  (if (< y 16) true ;; Zone réservée à l'UI
    (let [col (+ (// x 8) 1)
          lig (+ (// (- y 16) 8) 1)]
      (let [ligne (. matrice-active lig)
            valeur (if ligne (or (. ligne col) 1) 1)]
        (if (= valeur 2)
            (not M.door-open)
            (= valeur 1))))))

;; Gestion centralisée de la collision pour un rectangle contre un mur
(fn M.can-move? [x y size]
  (not (or (M.wall? x y)
           (M.wall? (+ x (- size 1)) y)
           (M.wall? x (+ y (- size 1)))
           (M.wall? (+ x (- size 1)) (+ y (- size 1))))))

;; Dessine toute la carte avec un décalage de 16px pour l'UI
;; Vérifie si deux entités se rentrent dedans (AABB)
(fn M.collide? [x1 y1 s1 x2 y2 s2]
  (and (< x1 (+ x2 s2))
       (> (+ x1 s1) x2)
       (< y1 (+ y2 s2))
       (> (+ y1 s1) y2)))

;; Vérifie si on touche la porte de sortie (valeur 2 dans matrice)
(fn M.is-door? [x y size]
  (let [cx (+ x (/ size 2))
        cy (+ y (/ size 2))
        col (+ (// cx 8) 1)
        lig (+ (// (- cy 16) 8) 1)]
    (let [ligne (. matrice-active lig)]
      (if (and ligne (. ligne col))
          (and (= (. ligne col) 2) M.door-open)
          false))))

;; Dessine toute la carte avec un décalage de 20px pour l'UI
(fn M.draw []
  (each [num-ligne ligne (ipairs map-v)]
    (each [num-col id (ipairs ligne)]
      (spr id (* (- num-col 1) 8) (+ 16 (* (- num-ligne 1) 8)) 0))))

M
