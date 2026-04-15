;; title:  Rogue-like 2D
;; author: Equipe
;; desc:   Rogue-like en vue du dessus
;; script: fennel

;; Importation des modules (inlinee a la compilation par Fennel)
(local player (include :player))
(local enemie (include :enemie))
(local enemies [])

(table.insert enemies (enemie.new 50 50))
(table.insert enemies (enemie.new 180 100))
;; Initialisation du joueur
(local joueur (player.new))

;; Boucle principale a 60 FPS
(fn _G.TIC []
  ;; 1. Mise a jour (inputs, deplacement, collisions)
  (player.update joueur)
  (each [i e (ipairs enemies)]
  (enemie.update e joueur)
  (enemie.attack e joueur player.take-damage)
  ;; suppression si mort
  (when (enemie.is-dead? e)
    (table.remove enemies i)))
    
  ;; 2. Rendu
  (cls 0)
  (each [_ e (ipairs enemies)]
    (enemie.draw e))
  (player.draw-ui joueur)
  (player.draw joueur))
