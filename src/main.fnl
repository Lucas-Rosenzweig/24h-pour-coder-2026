;; title:  Rogue-like 2D - Méta-Sprites (L'Arbre Géant)
;; author: Equipe
;; script: fennel

;; -- Module Principal --
(local player (include :player))
(local world (include :world))

;; Initialisation
(var initialized false)
(local enemie (include :enemie))
(local enemies [])

(table.insert enemies (enemie.new 50 50))
(table.insert enemies (enemie.new 180 100))
;; Initialisation du joueur
(local joueur (player.new))

;; Boucle principale
(fn _G.TIC []
  ;; 1. Initialisation unique au premier tour
  (when (not initialized)
    (world.init-assets)
    (set initialized true))

  ;; 2. Mise à jour des entités (inputs + collisions)
  (player.update joueur world enemies)

  (each [i e (ipairs enemies)]
    (enemie.update e joueur world enemies)
    (enemie.attack e joueur player.take-damage world)
    ;; suppression si mort
    (when (enemie.is-dead? e)
      (table.remove enemies i)))
    
  ;; 3. Rendu
  (cls 0)
  (world.draw)
  (each [_ e (ipairs enemies)]
    (enemie.draw e))
  (player.draw-ui joueur)
  (player.draw joueur))

