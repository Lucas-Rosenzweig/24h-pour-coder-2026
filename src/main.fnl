;; title:  Rogue-like 2D
;; author: Equipe
;; desc:   Rogue-like en vue du dessus
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

  ;; 2. Mise à jour (inputs + collisions gérées par world)
  (player.update joueur world)

  ;; Attaque si touche E appuyée
  (when (keyp 5)
    (player.attack joueur enemies enemie))

  
  (each [i e (ipairs enemies)]
  (enemie.update e joueur)
  (enemie.attack e joueur player.take-damage)
  ;; suppression si mort
  (when (enemie.is-dead? e)
    (table.remove enemies i)))
    
  ;; 3. Rendu
  (cls 2) ;; Efface avec la couleur herbe (index 2 défini dans world)
  (world.draw)
  (each [_ e (ipairs enemies)]
    (enemie.draw e))
  (player.draw-ui joueur)
  (player.draw joueur)
  ;;(player.draw-attack-cone joueur)) ;; -- Debug : affiche le cône d'attaque --

