;; title:  Rogue-like 2D
;; author: Equipe
;; desc:   Rogue-like en vue du dessus
;; script: fennel

;; Position du joueur
(var px 120)
(var py 68)

;; Taille du joueur
(var size 8)

;; Vitesse de deplacement
(var speed 2)

;; Boucle principale a 60 FPS
(fn _G.TIC []
  ;; Deplacement avec les fleches (btn 0=haut 1=bas 2=gauche 3=droite)
  (when (btn 0) (set py (- py speed)))
  (when (btn 1) (set py (+ py speed)))
  (when (btn 2) (set px (- px speed)))
  (when (btn 3) (set px (+ px speed)))

  ;; Limites de l'ecran (240x136)
  (when (< px 0) (set px 0))
  (when (< py 20) (set py 20))
  (when (> px (- 240 size)) (set px (- 240 size)))
  (when (> py (- 136 size)) (set py (- 136 size)))

  ;; Nettoie l'ecran (fond noir)
  (cls 0)

  ;; Dessine le joueur (carre blanc)
  (rect px py size size 12))
