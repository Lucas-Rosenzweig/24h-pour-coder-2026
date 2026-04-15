;; title:  Rogue-like 2D
;; author: Equipe
;; desc:   Rogue-like en vue du dessus
;; script: fennel

;; -- Module Principal --
(local player (include :player))
(local world (include :world))

;; Initialisation
(var initialized false)
(local joueur (player.new))

;; Boucle principale
(fn _G.TIC []
  ;; 1. Initialisation unique au premier tour
  (when (not initialized)
    (world.init-assets)
    (set initialized true))

  ;; 2. Mise à jour (inputs + collisions gérées par world)
  (player.update joueur world)

  ;; 3. Rendu
  (cls 2) ;; Efface avec la couleur herbe (index 2 défini dans world)
  (world.draw)
  (player.draw joueur))

