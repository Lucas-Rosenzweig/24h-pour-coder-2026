;; title:  Rogue-like 2D
;; author: Equipe
;; desc:   Rogue-like en vue du dessus
;; script: fennel

;; Importation des modules (inlinee a la compilation par Fennel)
(local player (include :player))

;; Initialisation du joueur
(local joueur (player.new))

;; Boucle principale a 60 FPS
(fn _G.TIC []
  ;; 1. Mise a jour (inputs, deplacement, collisions)
  (player.update joueur)

  ;; 2. Rendu
  (cls 0)
  (player.draw joueur))
