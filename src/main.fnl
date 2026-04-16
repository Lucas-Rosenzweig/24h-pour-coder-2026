;; title:  Rogue-like 2D - Méta-Sprites (L'Arbre Géant)
;; author: Equipe
;; script: fennel

;; -- Module Principal --
(local item (include :item))
(local player (include :player))
(local world (include :world))
(local enemie (include :enemie))
(local boss (include :boss))

;; Initialisation
(var initialized false)
(local enemies [])
(local projectiles [])
(local lightning-flashes [])
(local pickups [])
(local reward-screen (item.new))
(local reward-pickup-size 8)
(var room-reward-spawned false)
(var room-reward-required false)

;; Initialisation du joueur
(local joueur (player.new))

(fn is-boss? [e]
  (= e.type :boss))

(fn entity-update [e]
  (if (is-boss? e)
      (boss.update e joueur world enemies player.take-damage)
      (enemie.update e joueur world enemies)))

(fn entity-attack [e]
  (if (is-boss? e)
      (boss.attack e joueur player.take-damage world)
      (enemie.attack e joueur player.take-damage world)))

(fn entity-draw [e]
  (if (is-boss? e)
      (boss.draw e)
      (enemie.draw e)))

(fn entity-is-dead? [e]
  (if (is-boss? e)
      (boss.is-dead? e)
      (enemie.is-dead? e)))

(fn entity-take-damage [e dmg]
  (if (is-boss? e)
      (boss.take-damage e dmg)
      (enemie.take-damage e dmg)))

(fn entity-apply-dot [e dmg dur]
  (if (is-boss? e)
      (boss.apply-dot e dmg dur)
      (enemie.apply-dot e dmg dur)))

(fn entity-apply-stun [e frames]
  (if (is-boss? e)
      (boss.apply-stun e frames)
      (enemie.apply-stun e frames)))

(local combat-api
  {:take-damage entity-take-damage
   :apply-dot entity-apply-dot
   :apply-stun entity-apply-stun
   :is-dead? entity-is-dead?})

(fn spawn-room-enemies [count]
  (for [_ 1 count]
    (table.insert enemies
      (enemie.new (* (math.random 10 20) 8)
                  (* (math.random 5 12) 8)))))

(fn clear-list [xs]
  (while (> (# xs) 0)
    (table.remove xs 1)))

(fn setup-room-encounter []
  (clear-list enemies)
  (if (world.is-boss-room)
      (table.insert enemies (boss.new 112 64))
      (when (not (world.is-shop?))
        (spawn-room-enemies 4))))

(fn player-overlap-item? [p pickup]
  (and pickup.active
       (< (math.abs (- p.x pickup.x)) pickup.size)
       (< (math.abs (- p.y pickup.y)) pickup.size)))

(fn update-game []
  ;; Mise a jour (inputs + collisions gerees par world)
  (player.update joueur world enemies)

  ;; Attaque si touche E appuyee
  (when (keyp 5)
    (player.attack joueur enemies combat-api))

  ;; Hit épée déclenché à la fin de chaque sweep
  (when joueur.sword-hit-due
    (set joueur.sword-hit-due false)
    (player.do-sword-hit joueur enemies combat-api))

  ;; Sort si touche A appuyée (keyp 1)
  (when (keyp 1)
    (player.spell-attack joueur enemies combat-api projectiles lightning-flashes))

  ;; Utilitaire actif si touche Z appuyée (keyp 26)
  (when (keyp 26)
    (player.use-utility joueur world))

  ;; Mise a jour IA et suppression des morts
  (for [i (# enemies) 1 -1]
    (let [e (. enemies i)]
      (entity-update e)
      (entity-attack e)
      (when (entity-is-dead? e)
        (player.add-gold joueur (if (is-boss? e) 80 (math.random 5 20)))
        (table.remove enemies i))))

  ;; Fin de salle: ouverture de porte + spawn de la recompense devant la sortie.
  (when (and (not (world.is-shop?))
             (= (# enemies) 0)
             (not room-reward-spawned))
    (world.open-door)
    (let [spawn (world.get-door-reward-spawn reward-pickup-size)]
      (table.insert pickups {:x spawn.x :y spawn.y :size reward-pickup-size :active true}))
    (set room-reward-spawned true)
    (set room-reward-required true))

  ;; Ramassage de la recompense de salle
  (for [i (# pickups) 1 -1]
    (let [pickup (. pickups i)]
      (when (player-overlap-item? joueur pickup)
        (table.remove pickups i)
        (item.open reward-screen joueur)
        (set room-reward-required false))))

  ;; Portes / Transition de carte
  ;; En boss room MVP, on ne transitionne pas : drop de reward locale uniquement.
  (when (and (not (world.is-boss-room))
             (not room-reward-required)
             (world.is-door? joueur.x joueur.y joueur.size))
    (world.load-next-room)

    ;; Téléportation à gauche
    (set joueur.x 24)
    (set joueur.y 64)

    ;; Effacer les projectiles, éclairs et pickups residuels
    (clear-list projectiles)
    (clear-list lightning-flashes)
    (clear-list pickups)

    ;; Génération des entités de la nouvelle salle
    (setup-room-encounter)

    ;; Reset etat de salle pour la prochaine room
    (set room-reward-spawned false)
    (set room-reward-required false))

  ;; Mise a jour des projectiles joueur
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
          (when (and proj.alive (not (entity-is-dead? e)))
            (let [dx (- e.x proj.x)
                  dy (- e.y proj.y)
                  dist (math.sqrt (+ (* dx dx) (* dy dy)))]
              (when (< dist (+ proj.radius (/ e.size 2)))
                (entity-take-damage e proj.damage)
                (when (> proj.dot 0)
                  (entity-apply-dot e proj.dot proj.dot-dur))
                (when (> proj.aoe 0)
                  (each [_ e2 (ipairs enemies)]
                    (when (not= e2 e)
                      (let [ax (- e2.x proj.x)
                            ay (- e2.y proj.y)
                            adist (math.sqrt (+ (* ax ax) (* ay ay)))]
                        (when (< adist proj.aoe)
                          (entity-take-damage e2 proj.damage)
                          (when (> proj.dot 0)
                            (entity-apply-dot e2 proj.dot proj.dot-dur)))))))
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
    (entity-draw e))
  (each [_ proj (ipairs projectiles)]
    (circ (math.floor proj.x) (math.floor proj.y) 3 6))
  (each [_ pickup (ipairs pickups)]
    (circ (+ pickup.x 4) (+ pickup.y 4) 4 10)
    (circ (+ pickup.x 4) (+ pickup.y 4) 2 12))

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
    (setup-room-encounter)
    (set initialized true))

  ;; Pause du jeu si l'ecran reward est ouvert
  (if (item.is-open? reward-screen)
      (item.update reward-screen joueur)
      (update-game))

  ;; Rendu
  (draw-game)
  (when (item.is-open? reward-screen)
    (item.draw reward-screen)))
