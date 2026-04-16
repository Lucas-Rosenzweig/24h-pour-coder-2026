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

;; --- Shop (objets au sol) ---
(local spr-potion 207)
(local spr-item-upgrade 203)
(var shop-items [])
(var shop-msg "")
(var shop-msg-timer 0)

;; Initialisation du joueur
(local joueur (player.new))

(fn is-boss? [e]
  (= e.type :boss))

(fn entity-update [e]
  (if (is-boss? e)
      (boss.update e joueur world enemies player.take-damage)
      (enemie.update e joueur world enemies player.take-damage)))

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

(fn random-enemy-type []
  (let [roll (math.random 1 100)]
    (if (<= roll 40)
        :grunt
        (<= roll 70)
        :laser
        :kamikaze)))

(fn spawn-room-enemies [count]
  (for [_ 1 count]
    (let [pos (world.get-random-spawn 8)]
      (table.insert enemies (enemie.new pos.x pos.y (random-enemy-type))))))

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

(fn shop-set-msg [txt]
  (set shop-msg txt)
  (set shop-msg-timer 60))

(fn init-shop-items []
  ;; 2 objets au sol : heal (50g) et itemUpgrade (100g)
  (set shop-items
    [{:kind :heal :cost 50 :amount 5 :x 80 :y 72 :size 8 :active true}
     {:kind :itemUpgrade :cost 100 :x 152 :y 72 :size 8 :active true}]))

(fn try-buy-shop-item [it]
  (if (< joueur.gold it.cost)
      (shop-set-msg (.. it.cost "g requis"))
      (do
        (set joueur.gold (- joueur.gold it.cost))
        (if (= it.kind :heal)
            (do
              (player.heal joueur it.amount)
              (shop-set-msg (.. "+" it.amount " PV")))
            ;; itemUpgrade
            (do
              (shop-set-msg "Upgrade")
              (item.open reward-screen joueur))))))

(fn update-shop-items []
  ;; message temporaire
  (when (> shop-msg-timer 0)
    (set shop-msg-timer (- shop-msg-timer 1))
    (when (<= shop-msg-timer 0)
      (set shop-msg "")))
  ;; achat en boucle : garder l'item au sol, achat sur touche X au contact
  (each [_ it (ipairs shop-items)]
    (when (and it.active
               (player-overlap-item? joueur it)
               (or (btnp 4) (keyp 23)))
      (try-buy-shop-item it))))

(fn draw-shop-items []
  (each [_ it (ipairs shop-items)]
    (when it.active
      (let [label (.. it.cost "g")
            sid (if (= it.kind :heal) spr-potion spr-item-upgrade)]
        ;; "item par terre" (sprite)
        (spr sid it.x it.y 15)
        ;; indication au dessus
        (print "W acheter" (- it.x 6) (- it.y 10) 13 false 1 true)
        ;; prix juste en dessous
        (print label (- it.x 2) (+ it.y 10) 12 false 1 true)))))
  (when (not= shop-msg "")
    (print shop-msg 10 124 12 false 1 true))

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

  ;; Shop : pas de combat, juste l'UI + porte ouverte
  (when (world.is-shop?)
    (when (not world.door-open)
      (world.open-door))
    (when (= (# shop-items) 0)
      (init-shop-items))
    (update-shop-items))

  ;; Attaque si touche E appuyee
  (when (and (not (world.is-shop?)) (keyp 5))
    (player.attack joueur enemies combat-api))

  ;; Hit épée déclenché à la fin de chaque sweep
  (when joueur.sword-hit-due
    (set joueur.sword-hit-due false)
    (player.do-sword-hit joueur enemies combat-api))

  ;; Sort si touche A appuyée (keyp 1)
  (when (and (not (world.is-shop?)) (keyp 1))
    (player.spell-attack joueur enemies combat-api projectiles lightning-flashes))

  ;; Utilitaire actif si touche Z appuyée (keyp 26)
  (when (and (not (world.is-shop?)) (keyp 26))
    (player.use-utility joueur world))

  ;; Mise a jour IA et suppression des morts (pas pendant le shop)
  (when (not (world.is-shop?))
    (for [i (# enemies) 1 -1]
      (let [e (. enemies i)]
        (entity-update e)
        (entity-attack e)
        (when (entity-is-dead? e)
          (player.add-gold joueur (if (is-boss? e) 80 (math.random 5 20)))
          (table.remove enemies i)))))

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
    (set room-reward-required false)
    (set shop-items [])
    (set shop-msg "")
    (set shop-msg-timer 0)
    (when (world.is-shop?)
      (init-shop-items)))

  ;; Mise a jour des projectiles joueur
  (when (not (world.is-shop?))
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
          (table.remove projectiles i)))))

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
    (let [elapsed (- 120 proj.lifetime)
          frame (% (// elapsed 6) 3)
          angle (math.atan2 proj.vy proj.vx)
          rot (% (+ (math.floor (+ 0.5 (/ (* angle 2) math.pi))) 4) 4)]
      (spr (+ 200 frame) (- (math.floor proj.x) 4) (- (math.floor proj.y) 4) 15 1 0 rot)))
  (each [_ pickup (ipairs pickups)]
    (spr spr-item-upgrade pickup.x pickup.y 15))
  ;; Cône d'attaque épée
  (when (> joueur.sword-flash 0)
    (player.draw-attack-cone joueur))

  ;; Dessin des flashs éclair (zigzag en blanc)
  (each [_ f (ipairs lightning-flashes)]
    (let [mx (+ (/ (+ f.x1 f.x2) 2) f.jx)
          my (+ (/ (+ f.y1 f.y2) 2) f.jy)]
      (line f.x1 f.y1 mx my 12)
      (line mx my f.x2 f.y2 12)))
  (when (world.is-shop?)
    (draw-shop-items))
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
