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

;; ============================================
;; POOL DE MAPS (Ajoutez facilement vos maps ici)
;; ============================================
(local map-pool [
  ;; -----------------
  ;; MAP 1 : Classique
  ;; -----------------
  {:kind :combat
   :c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 0 1 1 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 36 32 32 32 32 37 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 35 31 31 31 31 34 24 24 24 24 24 24 27 29 24 24 24 24  2  3]
  [ 1  0 24 24 24 27 29 24 24 24 35 31 31 31 31 31 32 37 24 24 24 24 28 30 24 24 24 24  2  3]
  [ 1  0 24 24 24 28 30 24 24 24 35 31 31 31 31 31 31 34 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 35 31 31 31 31 31 33 39 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 38 33 33 33 33 39 24 24 24 27 29 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 26 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 25 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
		  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]}

  ;; -----------------
  ;; MAP 2 : Alternative
  ;; -----------------
  {:kind :combat
   :c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1]
  [1 1 0 0 1 1 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 1 1 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 36 32 32 32 32 37 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 35 31 31 31 31 34 24 24 24 24 24 24 24 27 29 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 35 31 31 31 31 31 32 37 24 24 24 24 24 28 30 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 27 29 24 35 31 31 31 31 31 31 34 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 28 30 24 35 31 31 31 31 31 31 34 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 38 33 33 33 33 33 33 39 24 24 24 27 29 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 26 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 25 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]}

  ;; -----------------
  ;; MAP 3 : Quatre piliers
  ;; -----------------
  {:kind :combat
   :c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 27 29 24 24 24 24 24 24 24 24 24 24 24 24 24 27 29 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 28 30 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 27 29 24 24 24 24 24 24 24 24 24 24 24 24 24 27 29 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 28 30 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 26 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]}

  ;; -----------------
  ;; MAP 4 : Labyrinthe en Z
  ;; -----------------
  {:kind :combat
   :c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 36 32 32 32 32 32 32 32 32 32 32 37 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 38 33 33 33 33 33 33 33 33 33 33 39 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 36 32 32 32 32 32 32 32 32 32 32 32 37 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 38 33 33 33 33 33 33 33 33 33 33 33 39 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]}

  ;; -----------------
  ;; MAP 5 : Champ de rochers
  ;; -----------------
  {:kind :combat
   :c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1]
  [1 1 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 27 29 24 24 24 24 24 24 24 27 29 24 24 24 24 24 24 24 27 29 24 24 24 24  2  3]
  [ 1  0 24 24 28 30 24 24 24 24 24 24 24 28 30 24 24 24 24 24 24 24 28 30 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 27 29 24 24 24 24 24 24 24 24 27 29 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 28 30 24 24 24 24 24 24 24 24 28 30 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 27 29 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 28 30 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 26 24 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]}])

;; ==========================
;; MAP SHOP (hors map-pool)
;; ==========================
(local shop-map
  {:c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 45  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [ 1  0 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24 24  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]})

(local boss-map
  {:kind :boss
   :c [
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 1]
  [1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]
  [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]]
   :v [
  [11 10  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  5  15 14]
  [ 9  8  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  4  13 12]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 27 29 25 25 25 25 25 25 25 25 25 25 25 25 27 29 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 28 30 25 25 25 25 25 25 25 25 25 25 25 25 28 30 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 45  3]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 45  3]
  [ 1  0 25 25 25 25 25 27 29 25 25 25 25 25 25 25 25 25 25 25 25 27 29 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 28 30 25 25 25 25 25 25 25 25 25 25 25 25 28 30 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25  2  3]
  [ 1  0 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25 25  2  3]
  [23 22  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  6  19 18]
  [21 20  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  7  17 16]]})

(var map-v [])
(var matrice-active (. map-pool 1 :c))
(set M.current-map-id 1)
(set M.door-open false)
(set M.current-map-kind :combat)
(set M.rooms-since-shop 0)

(fn M.load-boss-map []
  (set M.current-map-id -2)
  (set M.current-map-kind :boss)
  (set M.door-open false)
  (set map-v [])
  (set matrice-active boss-map.c)
  (each [_ ligne (ipairs boss-map.v)]
    (let [new-ligne []]
      (each [_ id (ipairs ligne)]
        (table.insert new-ligne id))
      (table.insert map-v new-ligne))))

(fn M.load-map [map-id]
  (set M.current-map-id map-id)
  (set M.door-open false)
  (set map-v [])
  (let [map-data (. map-pool map-id)]
    (set M.current-map-kind (or map-data.kind :combat))
    (set matrice-active map-data.c)
    (each [num-ligne ligne (ipairs map-data.v)]
      (let [new-ligne []]
        (each [num-col id (ipairs ligne)]
          (table.insert new-ligne id))
        (table.insert map-v new-ligne)))))

(fn M.is-shop? []
  (= M.current-map-kind :shop))

(fn M.is-boss-room []
  (= M.current-map-kind :boss))

(fn M.load-random-map []
  (var next-id M.current-map-id)
  ;; Si on a plus d'1 map, évite de tirer la même map deux fois d'affilée
  (if (> (# map-pool) 1)
      (while (= next-id M.current-map-id)
        (set next-id (math.random 1 (# map-pool))))
      (set next-id 1))
  (M.load-map next-id))

(fn M.construire-map []
  (set M.rooms-since-shop 0)
  (M.load-random-map))

	(fn M.load-shop-map []
	  (set M.current-map-id -1)
	  (set M.current-map-kind :shop)
	  (set M.door-open false)
	  (set map-v [])
	  (set matrice-active shop-map.c)
	  (each [_ ligne (ipairs shop-map.v)]
	    (let [new-ligne []]
	      (each [_ id (ipairs ligne)]
	        (table.insert new-ligne id))
	      (table.insert map-v new-ligne))))

	;; Avance la progression des salles :
	;; - Toutes les 4 salles de combat terminÃ©es, prochaine salle = shop
	;; - En sortant du shop, on repart sur une salle de combat et le compteur repart Ã  0
(fn M.load-next-room []
  (if (M.is-shop?)
      (do
        ;; après le shop -> boss
        (M.load-boss-map))

      (if (M.is-boss-room)
          (do
            ;; après le boss -> on repart sur un nouveau cycle
            (set M.rooms-since-shop 0)
            (M.load-random-map))

          (do
            ;; progression normale des salles de combat
            (set M.rooms-since-shop (+ M.rooms-since-shop 1))
            (if (>= M.rooms-since-shop 4)
                (M.load-shop-map)
                (M.load-random-map))))))

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

;; Retourne un point de spawn aléatoire valide (walkable) pour une certaine taille.
;; Optionnel: évite une zone circulaire (avoid-x, avoid-y) avec un rayon min-dist.
(fn M.get-random-spawn [size avoid-x avoid-y min-dist]
  (var found nil)
  (var attempts 0)
  (let [md-sq (if min-dist (* min-dist min-dist) 1600)] ;; 40 pixels par défaut
    (while (and (not found) (< attempts 50))
      (let [x (math.random 16 224)
            y (math.random 32 120)]
        (var dist-ok true)
        (when (and avoid-x avoid-y)
          (let [dx (- x avoid-x)
                dy (- y avoid-y)
                d-sq (+ (* dx dx) (* dy dy))]
            (if (< d-sq md-sq) (set dist-ok false))))
            
        (when (and dist-ok (walkable-rect? x y size))
          (set found {:x x :y y})))
      (set attempts (+ attempts 1)))
    (or found (find-safe-fallback-spawn size))))

;; --- 3. INITIALISATION DES ASSETS ---
(fn M.init-assets []
  ;; -- Palette --
  (poke 0x3FC0  68) (poke 0x3FC1  36) (poke 0x3FC2  52) ;; ID 0
  (poke 0x3FC3  20) (poke 0x3FC4  12) (poke 0x3FC5  28) ;; ID 1
  (poke 0x3FC6 133) (poke 0x3FC7  76) (poke 0x3FC8  48) ;; ID 2
  (poke 0x3FC9 210) (poke 0x3FCA 125) (poke 0x3FCB  44) ;; ID 3
  (poke 0x3FCC  41) (poke 0x3FCD 170) (poke 0x3FCE 254) ;; ID 4
  (poke 0x3FCF  93) (poke 0x3FD0  81) (poke 0x3FD1  72) ;; ID 5
  (poke 0x3FD2 252) (poke 0x3FD3 241) (poke 0x3FD4 236) ;; ID 6
  (poke 0x3FD5 255) (poke 0x3FD6 202) (poke 0x3FD7 171) ;; ID 7
  (poke 0x3FD8 222) (poke 0x3FD9 125) (poke 0x3FDA  59) ;; ID 8
  (poke 0x3FDB 247) (poke 0x3FDC 229) (poke 0x3FDD 120) ;; ID 9
  (poke 0x3FDE 235) (poke 0x3FDF 176) (poke 0x3FE0  80) ;; ID A
  (poke 0x3FE1 177) (poke 0x3FE2  62) (poke 0x3FE3  83) ;; ID B
  (poke 0x3FE4 112) (poke 0x3FE5  19) (poke 0x3FE6  39) ;; ID C
  (poke 0x3FE7 252) (poke 0x3FE8 13) (poke 0x3FE9 65) ;; ID D
  (poke 0x3FEA 61) (poke 0x3FEB 6) (poke 0x3FEC 18) ;; ID E
  (poke 0x3FED 222) (poke 0x3FEE 238) (poke 0x3FEF 214) ;; ID F

  ;; -- Sprites --

  ;; #442434
  ;; #140c1c
  ;; #854c30
  ;; #d27d2c

  ;; #FC0D41
  ;; #3D0612

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

  ;; JOUEUR
    ;; IDLE
      ;; 1
      (M.design-spr 100 "F000000F055555500557777005747740F0777770F066560F07655570F066560F")
      ;; 2
      (M.design-spr 101 "FFFFFFFFF000000F055555500557777005747740F077777007655570F066560F")
    ;; MARCHE-DROITE
      ;; 1
      (M.design-spr 102 "F000000F055555500557777005747740F07777700766560FF0655570F066500F")
      ;; 2
      (M.design-spr 103 "FFFFFFFFF000000F055555500557777005747740F0777770F065550FF066560F")
      ;; 3
      (M.design-spr 104 "F000000F055555500557777005747740F0777770F06656700765550FF006560F")
    ;; MARCHE-GAUCHE
      ;; 1
      (M.design-spr 105 "F000000F0555555007777550047747500777770FF06566700755560FF005660F")
      ;; 2
      (M.design-spr 106 "FFFFFFFFF000000F0555555007777550047747500777770FF055560FF065660F")
      ;; 3
      (M.design-spr 107 "F000000F0555555007777550047747500777770F0765660FF0555670F065600F")
    ;; MARCHE-DEVANT
      ;; 1
      (M.design-spr 108 "F000000F0555555005555550055555500755570FF06666700766660FF006660F")
      ;; 2
      (M.design-spr 109 "FFFFFFFFF000000F055555500555555005555550F075570FF066660FF066660F")
      ;; 3
      (M.design-spr 110 "F000000F055555500555555005555550F075557F0766660FF0666670F066660F")
  ;; MONSTRE 1
    ;; IDLE
      ;; 1
      (M.design-spr 111 "FF1111FFF1CCCC1F1CC7C7C11BC7C7B11BBBCBB11B1BBBB111F1B1B1FFFF1F1F")
      ;; 2
      (M.design-spr 112 "FFFFFFFFFF1111FFF1CCCC1F1CC7C7C11CB7C7C11BBBBBB11B1BBBB1F1F1B1BF")
    ;; MARCHE-DROITE
      ;; 1
      (M.design-spr 113 "FFFFFFFFFF1111FFF1CCCC1F1CCC7C711CBB7B711BBBBBB1BB1BBBB1111B1B1F")
      ;; 2
      (M.design-spr 114 "FF1111FFF1CCCC1F1CCC7C711CBC7C711CBBBBB11BBBBBB11B1B1BB1F1F1F11F")
      ;; 3
      (M.design-spr 115 "FF1111FFF1CCCC1F1CCCCCC11CBC7C711CBB7B711CBBBBB11B1B1B1FF1F1F1FF")
    ;; MARCHE-GAUCHE
      ;; 1
      (M.design-spr 116 "FFFFFFFFFF1111FFF1CCCC1F17C7CCC117B7BBC11BBBBBB11BBBB1BBF1B1B111")
      ;; 2
      (M.design-spr 117 "FF1111FFF1CCCC1F17C7CCC117C7CBC11BBBBBC11BBBBBB11BB1B1B1F11F1F1F")
      ;; 3
      (M.design-spr 118 "FF1111FFF1CCCC1F1CCCCCC117C7CBC117B7BBC11BBBBBC1F1B1B1B1FF1F1F1F")
    ;; MARCHE-DEVANT
      ;; 1
      (M.design-spr 119 "FF1111FFF1CCCC1F1CCCCCC11BCCCCB11BBBCBB11B1BBBB111F1B1B1FFFF1F1F")
      ;; 2
      (M.design-spr 120 "FFFFFFFFFF1111FFF1CCCC1F1CCCCCC11CBCCCC11BBBCBB11B1BBBB1F1F1B1BF")
  ;; BOSS
    ;; IDLE
      ;; 1
        ;; haut-gauche
        (M.design-spr 121 "FFFF1111FF11CEBBF1B3BCE1F1B3331C1CCB133C1BBC1CDC1BBB1CCCF1C1B11C")
        ;; haut-droite
        (M.design-spr 122 "1111FFFFBBEC11FF1ECB3B1FC1333B1FC331BCC1CDC1CBB1CCC1BBB1C11B1C1F")
        ;; bas-gauche
        (M.design-spr 123 "1CC11EE11CCC1EEE1CCCB1EEF1BBDD1EFF1DD1E1F11D1E1FF1B1B1FFF1CCC1FF")
        ;; bas-droite
        (M.design-spr 124 "1EE11CC1EEE1CCC1EE1BCCC1E1DDBB1F1E1DD1FFF1E1D11FFF1B1B1FFF1CCC1F")
      ;; 2
        ;; haut-gauche
        (M.design-spr 125 "FFFFFFFFFFFF1111FF11BCEBF1B3BBC1F1C3331C1BBC133C1BBB1CDCF1C11CCC")
        ;; haut-droite
        (M.design-spr 126 "FFFFFFFF1111FFFFBECB11FF1CBB3B1FC1333C1FC331CBB1CDC1BBB1CCC11C1F")
        ;; bas-gauche
        (M.design-spr 127 "1CCC111C1CCCC1E1F1CCBD1EFF1BDD1EFF1BD1E1F1111E1FF1B1B1FFF1CCCC1F")
        ;; bas-droite
        (M.design-spr 128 "C111CCC11E1CCCC1E1DBCC1FE1DDB1FF1E111FFFF1E1D1FFFF1B1B1FF1CCC1FF")
      ;; 3
        ;; haut-gauche
        (M.design-spr 129 "FFFF1111FF11CEBBF1BBBCEBF1B3BBC11CC3331C1BBC133C1BBB1CDCF1C11CCC")
        ;; haut-droite
        (M.design-spr 130 "1111FFFFBBEC11FFBECBBB1F1CBB3B1FC1333CC1C331CBB1CDC1BBB1CCC11C1F")
        ;; bas-gauche
        (M.design-spr 131 "1CCC111C1CCCC1E1F1CCBD1EFF1BDD1EFF1BD1E1F1111E1FF1B1B1FFF1CCCC1F")
        ;; bas-droite
        (M.design-spr 132 "C111CCC11E1CCCC1E1DBCC1FE1DDB1FF1E111FFFF1E1D1FFFF1B1B1FF1CCC1FF")
      
    ;; MARCHE-DROITE
      ;; 1
        (M.design-spr 133 "FFFFFF11FFFFF1BBFFFF1BC3FFFF1CBBFFF1BBBBFFF1CBBBFF1BCBBBFF1CBCC1")
        (M.design-spr 134 "1FFFFFFFBCFFFFFF3B11FFFF333C1FFFB133C1FF1CCDC1FF1CCCC1FFC11111FF")
        (M.design-spr 135 "FF1CCBBBFFF1CCCCFFF1CCCCFFF1CCCCFFFF1CCCFFFF111DFFF1BBB1FF1CCCCC")
        (M.design-spr 136 "1EEE1C1F1EE1CCD1C1E1CD1FCD1F11FFDD11FFFFD1BB1FFF1F1BB1FF1F1CC1CF")
      ;; 2
        (M.design-spr 137 "FFFFFF11FFFFF1B3FFFF1BCBFFFF1CBBFF11BBBBFF11CBBBF11BCBBBF11CBCC1")
        (M.design-spr 138 "1FFFFFFF3C11FFFFB3311FFFBB3311FFB1BDC1FF1CCCC1FF111111FFEEEEE1FF")
        (M.design-spr 139 "1CCCCB1ECCCCC11EDCCC1F1E1DD1FF11F1FFF1BBFFFF1CBBFFFFF1CBFFFFF1C1")
        (M.design-spr 140 "EEEE1FFFEEE1D1FFEEE1D1FFEE1F1FFFCB1FFFFF1B1FFFFF1BB1FFFFCCC1FFFF")
      ;; 3
        (M.design-spr 141 "FFFFFF11FFFFF1BBFFFF1BC3FFFF1CBBFFF1BBBBFFF1CBBBFF1BCBBBFF1CBCC1")
        (M.design-spr 142 "1FFFFFFFBCFFFFFF3B11FFFF333C1FFFB133C1FF1CCDC1FF1CCCC1FFC11111FF")
        (M.design-spr 143 "FF1CCBB1FFF1CCC1FFF1CCC1FFF1CC11FFF1DCD1FFFF1D1DFFFF1BB1FFF1CCCC")
        (M.design-spr 144 "EEEE1C1FEEE1CCD1EEE1CD1FEE1F11FFBBB1FFFF1BBB1FFF11BBB1FF11CCC1FF")
    ;; MARCHE-GAUCHE
      ;; 1
        (M.design-spr 145 "FFFFFFF1FFFFFFCBFFFF11B3FFF1C333FF1C331BFF1CDCC1FF1CCCC1FF11111C")
        (M.design-spr 146 "11FFFFFFBB1FFFFF3CB1FFFFBBC1FFFFBBBB1FFFBBBC1FFFBBBCB1FF1CCBC1FF")
        (M.design-spr 147 "F1C1EEE11DCC1EE1F1DC1E1CFF11F1DCFFFF11DDFFF1BB1DFF1BB1F1FC1CC1F1")
        (M.design-spr 148 "BBBCC1FFCCCC1FFFCCCC1FFFCCCC1FFFCCC1FFFFD111FFFF1BBB1FFFCCCCC1FF")
      ;; 2
        (M.design-spr 149 "FFFFFFF1FFFF11C3FFF1133BFF1133BBFF1CDB1BFF1CCCC1FF111111FF1EEEEE")
        (M.design-spr 150 "11FFFFFF3B1FFFFFBCB1FFFFBBC1FFFFBBBB11FFBBBC11FFBBBCB11F1CCBC11F")
        (M.design-spr 151 "FFF1EEEEFF1D1EEEFF1D1EEEFFF1F1EEFFFFF1BCFFFFF1B1FFFF1BB1FFFF1CCC")
        (M.design-spr 152 "E1BCCCC1E11CCCCCE1F1CCCD11FF1DD1BB1FFF1FBBC1FFFFBC1FFFFF1C1FFFFF")
      ;; 3
        (M.design-spr 153 "FFFFFFF1FFFFFFCBFFFF11B3FFF1C333FF1C331BFF1CDCC1FF1CCCC1FF11111C")
        (M.design-spr 154 "11FFFFFFBB1FFFFF3CB1FFFFBBC1FFFFBBBB1FFFBBBC1FFFBBBCB1FF1CCBC1FF")
        (M.design-spr 155 "F1C1EEEE1DCC1EEEF1DC1EEEFF11F1EEFFFF1BBBFFF1BBB1FF1BBB11FF1CCC11")
        (M.design-spr 156 "1BBCC1FF1CCC1FFF1CCC1FFF11CC1FFF1DCD1FFFD1D1FFFF1BB1FFFFCCCC1FFF")
    ;; MARCHE-DEVANT
      ;; 1
        (M.design-spr 157 "FFFF1111FF11CEBBF1B3BCE1F1B3331C1CCB133C1BBC1CDC1BBB1CCCF1C1B11C")
        ;; haut-droite
        (M.design-spr 158 "1111FFFFBBEC11FF1ECB3B1FC1333B1FC331BCC1CDC1CBB1CCC1BBB1C11B1C1F")
        ;; bas-gauche
        (M.design-spr 159 "1CC11EE11CCC1EEE1CCCB1EEF1BBDD1EFF1DD1E1F11D1E1FF1B1B1FFF1CCC1FF")
        ;; bas-droite
        (M.design-spr 160 "1EE11CC1EEE1CCC1EE1BCCC1E1DDBB1F1E1DD1FFF1E1D11FFF1B1B1FFF1CCC1F")
      ;; 2
        (M.design-spr 161 "FFFFFF11FFF111BBFF1BBCE1F1B3331CF1CB133C1BBC1CDC1BBB1CCCF1C1B11C")
        (M.design-spr 162 "11FFFFFFBB111FFF1ECBB1FFC1333B1FC331BC1FCDC1CBB1CCC1BBB1C11B1C1F")
        (M.design-spr 163 "1CC11EE11CCC11EE1CCCBD1EF1CDD1BEF1D11BE1FF1CCC1FFF1111FFFFFFFFFF")
        (M.design-spr 164 "1EE11CC1EEE1CCC1EE1BCCC1E1DDBB1F1E1DD1FFF1E1D11FFF1B1B1FFF1CCC1F")
      ;; 3
        (M.design-spr 165 "FFFF1111FF11CEBBF1B3BCE1F1B3331C1CCB133C1BBC1CDC1BBB1CCCF1C1B11C")
        (M.design-spr 166 "1111FFFFBBEC11FF1ECB3B1FC1333B1FC331BCC1CDC1CBB1CCC1BBB1C11B1C1F")
        (M.design-spr 167 "1CC11EE11CCC1EEE1CCCB1EEF1BBDD1EFF1DD1E1F11D1E1FF1B1B1FFF1CCC1FF")
        (M.design-spr 168 "1EE11CC1EE11CCC1E1DBCCC1EB1DDC1F1EB11D1FF1CCC1FFFF1111FFFFFFFFFF")
    ;; ATTAQUE
      ;; 1
        (M.design-spr 169 "FFFF1111FF11CEBBF1B3BCE1F1B3331C1CCB133C1BBC1CDC1BBB1CCCF1C1B11C")
        (M.design-spr 170 "1111FFFFBBEC11FF1ECB3B1FC1333B1FC331BCC1CDC1CBB1CCC1BBB1C11B1C1F")
        (M.design-spr 171 "1CC11EE11DCDD1EE1DDD1EEEF111CCCEFF1CCCC1F11CCC1FF1BBB1FFF1CCC1FF")
        (M.design-spr 172 "1EE11CC1EE1DDCD1EEE1DDD1ECCC111F1CCCC1FFF1CCC11FFF1BBB1FFF1CCC1F")
      ;; 2
        (M.design-spr 173 "FFFF1111FF11CEBBF1B3BCE1FDBDD31C1DDD133C1CCC1CDC1BCC1CCCF1C1B11C")
        (M.design-spr 174 "1111FFFFBBEC11FF1ECB3B1FC13DDBDFC331DDD1CDC1CCC1CCC1CCB1C11B1C1F")
        (M.design-spr 175 "F1CC1EE1FF11F1EEFFFF1EEEFF11CCCEFF1CCCC1F11CCC1FF1BBB1FFF1CCC1FF")
        (M.design-spr 176 "1EE1CC1FEE1F11FFEEE1FFFFECCC11FF1CCCC1FFF1CCC11FFF1BBB1FFF1CCC1F")
      ;; 3
        (M.design-spr 177 "FFFFFFFFF9FF9FFFF999F111FF991BBBFF19ABB1F1BC9A1C1BBB1AAC11C11CDC")
        (M.design-spr 178 "FFFFFFFFFFF9FF9F111F999FBB1199FF1BBA91FFC1A9CB1FCAA1BBB1CDC11C11")
        (M.design-spr 179 "1CC11CCC1CCC111C1CCCB1E1FDBBBB1EDD1BBBE1FDDBBD1FF11DBD1FF1DDDDD1")
        (M.design-spr 180 "CCC11CC1C111CCC11E1BCC11E1BBBB1D1EDBB1DDF1DBBDDFF11BDD1F1DDDDD1F")
  ;; MONSTRE 2
    ;; IDLE
      ;; 1
      (M.design-spr 181 "FFF1FFFFF11211FF1222221F1242431F1336331F1366631FF13331FFFF111FFF")
      ;; 2
      (M.design-spr 182 "F11211FF1222221F1242421F1336331F1366631F1333331FF13131FFFF1F1FFF")
    ;; MARCHE-DROITE
      ;; 1
      (M.design-spr 183 "FF1121FFFF12231FF122241F1224331F1233361F1333661FF13131FFFF1F1FFF")
      ;; 2
      (M.design-spr 184 "FFFFFFFFFF1211FFF122221F1222341F1234331F1333361F1333661FF13131FF")
    ;; MARCHE-GAUCHE
      ;; 1
      (M.design-spr 186 "FF1211FFF13221FFF142221FF1334221F1633321F1663331FF13131FFFF1F1FF")
      ;; 2
      (M.design-spr 187 "FFFFFFFFFF1121FFF122221FF1432221F1334321F1633331F1663331FF13131F")
    ;; MARCHE-DEVANT
      ;; 1
      (M.design-spr 189 "FF1211FFF13221FFF142221FF1334221F1633321F1663331FF13131FFFF1F1FF")
      ;; 2
      (M.design-spr 190 "FFFFFFFFFF1121FFF122221FF1432221F1334321F1633331F1663331FF13131F")

  ;; MONSTRE 3
    ;; IDLE
      ;; 1
      (M.design-spr 191 "FFF11FFFF112211F122222211C9229C11C2882C11CC22CC1F11CC11FFFF11FFF")
    ;; MARCHE-DROITE
      ;; 1
      (M.design-spr 192 "FFF11FFF1112211FF1222221FF122991FF1C2281F1CCC8C1111CC11FFFF11FFF")
      ;; 2
      (M.design-spr 193 "FFF11FFFFF12211FF122222112222991122C2281F1CCC8C1FF1CC11FFFF11FFF")

    ;; MARCHE-GAUCHE
      ;; 1
      (M.design-spr 195 "FFF11FFFF11221111222221F199221FF1822C1FF1C8CCC1FF11CC111FFF11FFF")
      ;; 2
      (M.design-spr 196 "FFF11FFFF11221FF1222221F199222211822C2211C8CCC1FF11CC1FFFFF11FFF")

    ;; MARCHE-DEVANT
      ;; 1
      (M.design-spr 198 "FFF11FFFF11221111222221F199221FF1822C1FF1C8CCC1FF11CC111FFF11FFF")
      ;; 2
      (M.design-spr 199 "FFF11FFFF11221FF1222221F199222211822C2211C8CCC1FF11CC1FFFFF11FFF")

  ;; ITEM
    ;; BOULE DE FEU
      ;; 1
      (M.design-spr 200 "FFFFFFFFF88888FF8AAAAA8FFF8A99A88A9999A8888AAA8FFFF888FFFFFFFFFF")
      ;; 2
      (M.design-spr 201 "FFFFFFFFFFF888FF888AAA8F8A9999A8FF8A99A88AAAAA8FF88888FFFFFFFFFF")
      ;; 3
      (M.design-spr 202 "FFFFFFFFFFF888FF8F8AAA8FF89999A88AAA99A8F8AAAA8FFF8888FFFFFFFFFF")
    ;; EPEE
      (M.design-spr 203 "FFFFFF66FFFFF667FFFF667F9AF667FFF9667FFFF227FFFF1229AFFF91FF9FFF")
    ;; FROUDRE
      (M.design-spr 204 "FFFF99FFFFF996FFFF996FFFF999FFFFF99999FFFFF996FFFF996FFFF99FFFFF")
	    ;; DASH
	      (M.design-spr 205 "FFFFFFFFFFF444FFFF44446FFFFFF46F4446F44FF446F4FFFF44FFFFFFF4FFFF")
	    ;; GOLD
	      (M.design-spr 206 "FF1111FFF199991F19996991199966911999669119996991F199991FFF1111FF")
	    ;; POTION VIE
	      (M.design-spr 207 "FFF22FFFFF6226FFFFF66FFFFF6666FFF6FFFF6F6BBBBBB66BBBBBB6F666666F")
    ;; PLAYER DOWN
      (M.design-spr 208 "FFFF111FF111BB511667BB5117674B51156777B1155777B1156747511711111F")
    ;; SHIELD
      (M.design-spr 209 "FFFFFFFF1111111112255221152552511255552111222211F112211FFF1111FF")
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
      (spr id (* (- num-col 1) 8) (+ 16 (* (- num-ligne 1) 8)) 15))))

M
