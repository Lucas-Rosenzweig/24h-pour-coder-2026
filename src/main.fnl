;; title:  Rogue-like 2D - Méta-Sprites (L'Arbre Géant)
;; author: Equipe
;; script: fennel

(var px 120) (var py 68)
(var size 8) (var speed 2)

;; --- 1. PALETTE "CLEAN" ---
(fn init-palette []
  (poke 0x3FC0 20 40 20)   ;; 0: Vert Ombre (Contours)
  (poke 0x3FC3 40 100 40)  ;; 1: Vert Sombre (Feuilles ombre)
  (poke 0x3FC6 80 160 60)  ;; 2: Vert Herbe (Sol de base)
  (poke 0x3FC9 140 210 80) ;; 3: Vert Clair (Lumière/Feuilles)
  (poke 0x3FCC 60 30 20)   ;; 4: Brun Sombre (Ombre tronc)
  (poke 0x3FCF 110 70 40)  ;; 5: Brun Moyen (Tronc)
  (poke 0x3FD2 160 110 70) ;; 6: Brun Clair (Lumière tronc)
  (poke 0x3FE4 220 230 200));; C: Blanc (Pour le joueur)

;; --- 2. GÉNÉRATEUR ---
(fn design-spr [id hex]
  (let [addr (+ 0x4000 (* id 32))]
    (for [i 1 64 2]
      (let [s1 (hex:sub i i) s2 (hex:sub (+ i 1) (+ i 1))
            p1 (tonumber (if (= s1 "") "0" s1) 16)
            p2 (tonumber (if (= s2 "") "0" s2) 16)]
        (poke (+ addr (// (- i 1) 2)) (+ (* p2 16) p1))))))

;; --- 3. LES SPRITES ---

;; Sol de base (Herbe unie et propre)
(design-spr 2 "2222222222232222223322222222222222222222222223222222332222222222")

;; --- L'ARBRE GÉANT (4 Sprites qui s'assemblent) ---
;; 10: Arbre Haut-Gauche (Feuilles arrondies)
(design-spr 10 "2222000022001111201133332013333301133333011333330111333301111111")
;; 11: Arbre Haut-Droit (Feuilles avec lumière)
(design-spr 11 "0000222211110022333311023333110233331102333311023333110211111102")
;; 12: Arbre Bas-Gauche (Tronc et ombres)
(design-spr 12 "0111111120001111222205662222056622220566222204552222200022222222")
;; 13: Arbre Bas-Droit (Tronc et racine)
(design-spr 13 "1111111011110002554022225540222255402222440022220022222222222222")

;; 20: Joueur
(design-spr 20 "000CC00000CCCC000C000C000C333C0000333300005555000000000000000000")

;; --- 4. MATRICES ---

;; Matrice Visuelle (On place notre arbre en plein milieu !)
(local map1-v [
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

;; Matrice de Collision
;; ASTUCE : On met les ID 12 et 13 comme solides, mais pas 10 et 11 !
(fn mur? [x y]
  (let [col (+ (// x 8) 1) lig (+ (// y 8) 1)]
    (let [ligne (. map1-v lig)
          valeur (if ligne (. ligne col) 2)]
      ;; Si le joueur touche la base de l'arbre (12 ou 13), c'est bloqué.
      (or (= valeur 12) (= valeur 13)))))

;; --- 5. INITIALISATION & BOUCLE ---
(init-palette)

(fn _G.TIC []
  (cls 2)
  
  ;; Dessine la map
  (each [num-ligne ligne (ipairs map1-v)]
    (each [num-col id (ipairs ligne)]
      (spr id (* (- num-col 1) 8) (* (- num-ligne 1) 8) 0)))
  
  ;; Mouvement
  (when (btn 0) (if (and (not (mur? px (- py speed))) (not (mur? (+ px 7) (- py speed)))) (set py (- py speed))))
  (when (btn 1) (if (and (not (mur? px (+ py 8))) (not (mur? (+ px 7) (+ py 8)))) (set py (+ py speed))))
  (when (btn 2) (if (and (not (mur? (- px speed) py)) (not (mur? (- px speed) (+ py 7)))) (set px (- px speed))))
  (when (btn 3) (if (and (not (mur? (+ px 8) py)) (not (mur? (+ px 8) (+ py 7)))) (set px (+ px speed))))
  
  ;; Dessine le joueur (ID 20) par dessus le reste
  (spr 20 px py 0))