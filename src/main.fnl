;; title:  Rogue-like 2D - Méta-Sprites (L'Arbre Géant)
;; author: Equipe
;; script: fennel

;; -- Module Principal --
(local item (include :item))
(local player (include :player))
(local world (include :world))

;; Initialisation
(var initialized false)
(local enemie (include :enemie))
(local enemies [])
(local projectiles [])
(local lightning-flashes [])
(local reward-screen (item.new))
(local pickups [])
(var pickup-spawn-timer 180)
(local pickup-spawn-delay 300)
(local max-pickups 3)
(local reward-screen (item.new))
(table.insert enemies (enemie.new 50 50))
(table.insert enemies (enemie.new 180 100))
(table.insert enemies (enemie.new 180 90))
(table.insert enemies (enemie.new 180 120))

;; Initialisation du joueur
(local joueur (player.new))

(fn player-overlap-item? [p pickup]
  (and pickup.active
       (< (math.abs (- p.x pickup.x)) pickup.size)
       (< (math.abs (- p.y pickup.y)) pickup.size)))

(fn spawn-pickup []
  (when (< (# pickups) max-pickups)
    (var attempts 0)
    (var spawned false)
    (while (and (< attempts 20) (not spawned))
      (let [x (* (math.random 1 28) 8)
            y (+ 20 (* (math.random 1 13) 8))]
        (set attempts (+ attempts 1))
        (when (and (not (world.wall? x y))
                   (not (world.wall? (+ x 7) (+ y 7))))
          (table.insert pickups {:x x :y y :size 8 :active true})
          (set spawned true))))))


(fn update-game []
  ;; Mise a jour (inputs + collisions gerees par world)
  (player.update joueur world enemies)

  ;; Spawn aleatoire de pickups avec limite a l'ecran
  (set pickup-spawn-timer (- pickup-spawn-timer 1))
  (when (<= pickup-spawn-timer 0)
    (spawn-pickup)
    (set pickup-spawn-timer pickup-spawn-delay))

  ;; Ramassage des pickups
  (for [i (# pickups) 1 -1]
    (let [pickup (. pickups i)]
      (when (player-overlap-item? joueur pickup)
        (table.remove pickups i)
        (item.open reward-screen joueur))))

  ;; Attaque si touche E appuyee
  (when (keyp 5)
    (player.attack joueur enemies enemie))

  ;; Sort si touche A appuyee
  ;; Hit épée déclenché à la fin de chaque sweep
  (when joueur.sword-hit-due
    (set joueur.sword-hit-due false)
    (player.do-sword-hit joueur enemies enemie))

  ;; Sort si touche A appuyée (keyp 1)
  (when (keyp 1)
    (player.spell-attack joueur enemies enemie projectiles lightning-flashes))

  ;; Utilitaire actif si touche Z appuyée (keyp 26)
  (when (keyp 26)
    (player.use-utility joueur world))

  ;; Gestion d'ouverture de la porte
  (when (and (= (# enemies) 0) (not world.door-open))
    (world.open-door))

  ;; Portes / Transition de carte (uniquement si porte ouverte)
  (when (world.is-door? joueur.x joueur.y joueur.size)
    (world.load-random-map)
    
    ;; Téléportation à gauche
    (set joueur.x 24)
    (set joueur.y 64)

    ;; Génération de nouveaux ennemis pour la nouvelle salle
    (for [i 1 4]
      (table.insert enemies (enemie.new (* (math.random 10 20) 8) (* (math.random 5 12) 8))))

    ;; Effacer les projectiles et éclairs
    (while (> (# projectiles) 0) (table.remove projectiles 1))
    (while (> (# lightning-flashes) 0) (table.remove lightning-flashes 1)))

  (each [i e (ipairs enemies)]
    (enemie.update e joueur world enemies)
    (enemie.attack e joueur player.take-damage world)
    ;; suppression si mort
    (when (enemie.is-dead? e)
      (player.add-gold joueur (math.random 5 20))
      (table.remove enemies i)))

  ;; Mise a jour des projectiles
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

  ;; Mise a jour des flashs eclair
  (for [i (# lightning-flashes) 1 -1]
    (let [f (. lightning-flashes i)]
      (set f.timer (- f.timer 1))
      (when (<= f.timer 0)
        (table.remove lightning-flashes i)))))

(fn draw-game []
  (cls 0)
  (world.draw)
  (each [_ e (ipairs enemies)]
    (enemie.draw e))
  (each [_ proj (ipairs projectiles)]
    (circ (math.floor proj.x) (math.floor proj.y) 3 6))
  (each [_ pickup (ipairs pickups)]
    (circ (+ pickup.x 4) (+ pickup.y 4) 4 10)
    (circ (+ pickup.x 4) (+ pickup.y 4) 2 12))
  ;; Dessin des flashs eclair
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
  (player.draw-gold-ui joueur)
  (player.draw joueur))

;; Boucle principale
(fn _G.TIC []
  ;; Initialisation unique
  (when (not initialized)
    (world.init-assets)
    (set initialized true))

  ;; Pause du jeu si l'ecran reward est ouvert
  (if (item.is-open? reward-screen)
    (item.update reward-screen joueur)
    (update-game))

  ;; Rendu
  (draw-game)
  (when (item.is-open? reward-screen)
    (item.draw reward-screen)))
