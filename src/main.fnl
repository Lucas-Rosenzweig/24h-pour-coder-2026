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
(local projectiles [])
(local lightning-flashes [])

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

  ;; Hit épée déclenché à la fin de chaque sweep
  (when joueur.sword-hit-due
    (set joueur.sword-hit-due false)
    (player.do-sword-hit joueur enemies enemie))

  ;; Sort si touche A appuyée (keyp 1)
  (when (keyp 1)
    (player.spell-attack joueur enemies enemie projectiles lightning-flashes))

  
  (each [i e (ipairs enemies)]
  (enemie.update e joueur)
  (enemie.attack e joueur player.take-damage)
  ;; suppression si mort
  (when (enemie.is-dead? e)
    (table.remove enemies i)))

  ;; Mise à jour des projectiles
  (for [i (# projectiles) 1 -1]
    (let [proj (. projectiles i)]
      (set proj.x (+ proj.x proj.vx))
      (set proj.y (+ proj.y proj.vy))
      (set proj.lifetime (- proj.lifetime 1))
      (when (<= proj.lifetime 0)
        (set proj.alive false))
      (when (world.wall? proj.x proj.y)
        (set proj.alive false))
      (when proj.alive
        (each [_ e (ipairs enemies)]
          (when (and proj.alive (not (enemie.is-dead? e)))
            (let [dx (- e.x proj.x)
                  dy (- e.y proj.y)
                  dist (math.sqrt (+ (* dx dx) (* dy dy)))]
              (when (< dist (+ proj.radius (/ e.size 2)))
                (enemie.take-damage e proj.damage)
                (when (> proj.dot 0)
                  (enemie.apply-dot e proj.dot proj.dot-dur))
                (when (> proj.aoe 0)
                  (each [_ e2 (ipairs enemies)]
                    (when (not= e2 e)
                      (let [ax (- e2.x proj.x)
                            ay (- e2.y proj.y)
                            adist (math.sqrt (+ (* ax ax) (* ay ay)))]
                        (when (< adist proj.aoe)
                          (enemie.take-damage e2 proj.damage)
                          (when (> proj.dot 0)
                            (enemie.apply-dot e2 proj.dot proj.dot-dur)))))))
                (set proj.alive false))))))
      (when (not proj.alive)
        (table.remove projectiles i))))

  ;; Mise à jour des flashs éclair
  (for [i (# lightning-flashes) 1 -1]
    (let [f (. lightning-flashes i)]
      (set f.timer (- f.timer 1))
      (when (<= f.timer 0)
        (table.remove lightning-flashes i))))

  ;; 3. Rendu
  (cls 2) ;; Efface avec la couleur herbe (index 2 défini dans world)
  (world.draw)
  (each [_ e (ipairs enemies)]
    (enemie.draw e))
  (each [_ proj (ipairs projectiles)]
    (circ (math.floor proj.x) (math.floor proj.y) 3 6))
  ;; Cône d'attaque épée
  (when (> joueur.sword-flash 0)
    (player.draw-attack-cone joueur))
  ;; Dessin des flashs éclair (zigzag en blanc)
  (each [_ f (ipairs lightning-flashes)]
    (let [mx (+ (/ (+ f.x1 f.x2) 2) f.jx)
          my (+ (/ (+ f.y1 f.y2) 2) f.jy)]
      (line f.x1 f.y1 mx my 12)
      (line mx my f.x2 f.y2 12)))
  (player.draw-ui joueur)
  (player.draw joueur))
  ;;(player.draw-attack-cone joueur) ;; -- Debug : affiche le cône d'attaque --
