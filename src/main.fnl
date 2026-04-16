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
(local reward-pickup-size 8)
(var room-reward-spawned false)
(var room-reward-required false)

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

(fn update-game []
  ;; Mise a jour (inputs + collisions gerees par world)
  (player.update joueur world enemies)

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

  (for [i (# enemies) 1 -1]
    (let [e (. enemies i)]
      (enemie.update e joueur world enemies)
      (enemie.attack e joueur player.take-damage world)
      ;; suppression si mort
      (when (enemie.is-dead? e)
        (table.remove enemies i))))

  ;; Fin de salle: ouverture de porte + spawn de la recompense devant la sortie.
  (when (and (= (# enemies) 0) (not room-reward-spawned))
    (world.open-door)
    (let [spawn (world.get-door-reward-spawn reward-pickup-size)]
      (table.insert pickups {:x spawn.x :y spawn.y :size reward-pickup-size :active true}))
    (set room-reward-spawned true)
    (set room-reward-required true))

  ;; Ramassage de la recompense de salle (obligatoire avant transition)
  (for [i (# pickups) 1 -1]
    (let [pickup (. pickups i)]
      (when (player-overlap-item? joueur pickup)
        (table.remove pickups i)
        (item.open reward-screen joueur)
        (set room-reward-required false))))

  ;; Portes / Transition de carte (bloquee tant que la recompense n'est pas prise)
  (when (and (not room-reward-required)
             (not (item.is-open? reward-screen))
             (world.is-door? joueur.x joueur.y joueur.size))
    (if (= world.current-map-id 1)
        (world.load-map 2)
        (world.load-map 1))
    
    ;; Téléportation à gauche
    (set joueur.x 24)
    (set joueur.y 64)

    ;; Génération de nouveaux ennemis pour la nouvelle salle
    (for [i 1 4]
      (table.insert enemies (enemie.new (* (math.random 10 20) 8) (* (math.random 5 12) 8))))

    ;; Effacer les projectiles, éclairs et pickups residuels
    (while (> (# projectiles) 0) (table.remove projectiles 1))
    (while (> (# lightning-flashes) 0) (table.remove lightning-flashes 1))
    (while (> (# pickups) 0) (table.remove pickups 1))

    ;; Reset etat de salle pour la prochaine room
    (set room-reward-spawned false)
    (set room-reward-required false))

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
