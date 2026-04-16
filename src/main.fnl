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

;; Gestion d'états
(var game-state :intro) ;; Peut valoir :intro, :menu, ou :game
(var intro-timer 120)
(var menu-blink 0)

;; --- Shop (objets au sol) ---
(local spr-potion 207)
(local spr-item-upgrade 203)
(var shop-items [])
(var shop-msg "")
(var shop-msg-timer 0)

(local DOOR-PULSE-DURATION 24)
(local PLAYER-HIT-OVERLAY-DURATION 8)
(local PICKUP-BOB-AMPLITUDE 2)
(local PICKUP-BOB-SPEED 8)

(local fx
  {:frame 0
   :door-pulse 0
   :door-pulse-x 120
   :door-pulse-y 72
   :player-hit-overlay 0})

;; Initialisation du joueur
(var joueur (player.new))
(local SWORD-KNOCKBACK-PX 12)
(local SWORD-KNOCKBACK-STEP 1.5)

(fn tick-fx []
  (set fx.frame (+ fx.frame 1))
  (when (> fx.door-pulse 0)
    (set fx.door-pulse (- fx.door-pulse 1)))
  (when (> fx.player-hit-overlay 0)
    (set fx.player-hit-overlay (- fx.player-hit-overlay 1))))

(fn trigger-door-pulse []
  (let [spawn (world.get-door-reward-spawn reward-pickup-size)]
    (set fx.door-pulse DOOR-PULSE-DURATION)
    (set fx.door-pulse-x (+ spawn.x 4))
    (set fx.door-pulse-y (+ spawn.y 4))))

(fn player-take-damage-with-fx [p dmg hit-x hit-y]
  (when (player.take-damage p dmg hit-x hit-y world)
    (set fx.player-hit-overlay PLAYER-HIT-OVERLAY-DURATION)
    true))

(fn is-boss? [e]
  (= e.type :boss))

(fn entity-update [e]
  (if (is-boss? e)
      (boss.update e joueur world enemies player-take-damage-with-fx)
      (enemie.update e joueur world enemies player-take-damage-with-fx)))

(fn entity-attack [e]
  (if (is-boss? e)
      (boss.attack e joueur player-take-damage-with-fx world)
      (enemie.attack e joueur player-take-damage-with-fx world)))

(fn entity-draw [e]
  (if (is-boss? e)
      (boss.draw e)
      (enemie.draw e)))

(fn entity-is-dead? [e]
  (if (is-boss? e)
      (boss.is-dead? e)
      (enemie.is-dead? e)))

(fn entity-center-x [e]
  (+ e.x (/ e.size 2)))

(fn entity-center-y [e]
  (+ e.y (/ e.size 2)))

(fn can-occupy-entity? [e nx ny]
  (and (world.can-move? nx ny e.size)
       (not (world.collide? nx ny e.size joueur.x joueur.y joueur.size))
       (do
         (var blocked false)
         (each [_ other (ipairs enemies)]
           (when (and (not= other e)
                      (not (entity-is-dead? other))
                      (world.collide? nx ny e.size other.x other.y other.size))
             (set blocked true)))
         (not blocked))))

(fn queue-sword-knockback [e from-x from-y dist]
  (when (> dist 0)
    (let [dx (- (entity-center-x e) from-x)
          dy (- (entity-center-y e) from-y)
          len (math.sqrt (+ (* dx dx) (* dy dy)))]
      (if (> len 0.001)
          (do
            (set e.kb-dx (/ dx len))
            (set e.kb-dy (/ dy len)))
          (do
            (set e.kb-dx 1)
            (set e.kb-dy 0)))
      (set e.kb-left dist))))

(fn apply-entity-knockback [e]
  (when (> (or e.kb-left 0) 0)
    (let [step (math.min SWORD-KNOCKBACK-STEP e.kb-left)
          vx (* (or e.kb-dx 0) step)
          vy (* (or e.kb-dy 0) step)]
      (var moved false)
      (let [nx (+ e.x vx)]
        (when (can-occupy-entity? e nx e.y)
          (set e.x nx)
          (set moved true)))
      (let [ny (+ e.y vy)]
        (when (can-occupy-entity? e e.x ny)
          (set e.y ny)
          (set moved true)))
      (if moved
          (set e.kb-left (- e.kb-left step))
          (set e.kb-left 0))
      (when (< e.kb-left 0.001)
        (set e.kb-left 0)))))

(fn entity-take-damage [e dmg hit-context]
  (local hp-before e.hp)
  (if (is-boss? e)
      (boss.take-damage e dmg)
      (enemie.take-damage e dmg))
  (when (and hit-context
             (= hit-context.source :sword)
             (> dmg 0)
             (< e.hp hp-before)
             (not (entity-is-dead? e)))
    (queue-sword-knockback e hit-context.from-x hit-context.from-y SWORD-KNOCKBACK-PX)))

(fn entity-apply-dot [e dmg dur]
  (if (is-boss? e)
      (boss.apply-dot e dmg dur)
      (enemie.apply-dot e dmg dur)))

(fn entity-apply-stun [e frames]
  (if (is-boss? e)
      (boss.apply-stun e frames)
      (enemie.apply-stun e frames)))

(fn entity-apply-knockback [e from-x from-y strength]
  (if (is-boss? e)
      (boss.apply-knockback e from-x from-y strength)
      (enemie.apply-knockback e from-x from-y strength)))

(local combat-api
  {:take-damage entity-take-damage
   :apply-dot entity-apply-dot
   :apply-stun entity-apply-stun
   :apply-knockback entity-apply-knockback
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
    (let [pos (world.get-random-spawn 8 joueur.x joueur.y 60)]
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

(fn player-near-item? [p pickup]
  (let [dx (- (+ p.x (/ p.size 2)) (+ pickup.x (/ pickup.size 2)))
        dy (- (+ p.y (/ p.size 2)) (+ pickup.y (/ pickup.size 2)))]
    (< (+ (* dx dx) (* dy dy)) 450)))

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
        (player.spend-gold joueur it.cost)
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
            sid (if (= it.kind :heal) spr-potion spr-item-upgrade)
            bob (math.floor (* (math.sin (/ (+ fx.frame (* it.x 0.5)) PICKUP-BOB-SPEED)) PICKUP-BOB-AMPLITUDE))
            draw-y (+ it.y bob)
            near? (player-near-item? joueur it)
            pulse-r (+ 7 (math.floor (* (math.sin (/ (+ fx.frame (* it.y 0.4)) 5)) 1.5)))]
        (when near?
          (circb (+ it.x 4) (+ draw-y 4) pulse-r (if (= (% (// fx.frame 4) 2) 0) 9 10)))
        ;; "item par terre" (sprite)
        (spr sid it.x draw-y 15)
        ;; indication au dessus
        (print "W acheter" (- it.x 6) (- draw-y 10) (if near? 12 13) false 1 true)
        ;; prix juste en dessous
        (print label (- it.x 2) (+ draw-y 10) 12 false 1 true)))))
  (when (not= shop-msg "")
    (let [t shop-msg-timer
          y (- 124 (math.floor (/ (- 60 t) 10)))
          color (if (< t 15)
                    (if (= (% (// t 2) 2) 0) 12 6)
                    12)]
      (print shop-msg 10 y color false 1 true)))

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
          (table.insert pickups {:x x :y y :size 8 :active true :phase (math.random 0 60)})
          (set spawned true))))))


(fn update-game []
  ;; Mise a jour (inputs + collisions gerees par world)
  (player.update joueur world enemies)

  ;; Shop : pas de combat, juste l'UI + porte ouverte
  (when (world.is-shop?)
    (when (not world.door-open)
      (world.open-door)
      (trigger-door-pulse))
    (when (= (# shop-items) 0)
      (init-shop-items))
    (update-shop-items))

  ;; Attaque si touche E appuyee
  (when (and (not (world.is-shop?)) (keyp 5))
    (let [status (player.attack joueur enemies combat-api)]
      (player.feedback-action-status joueur :attack status)))

  ;; Hit épée déclenché à la fin de chaque sweep
  (when joueur.sword-hit-due
    (set joueur.sword-hit-due false)
    (player.do-sword-hit joueur enemies combat-api))

  ;; Sort si touche A appuyée (keyp 1)
  (when (and (not (world.is-shop?)) (keyp 1))
    (let [status (player.spell-attack joueur enemies combat-api projectiles lightning-flashes)]
      (player.feedback-action-status joueur :spell status)))

  ;; Utilitaire actif si touche Z appuyée (keyp 26)
  (when (and (not (world.is-shop?)) (keyp 26))
    (let [status (player.use-utility joueur world)]
      (player.feedback-action-status joueur :utility status)))

  ;; Mise a jour IA et suppression des morts (pas pendant le shop)
  (when (not (world.is-shop?))
    (for [i (# enemies) 1 -1]
      (let [e (. enemies i)]
        (entity-update e)
        (apply-entity-knockback e)
        (entity-attack e)
        (when (entity-is-dead? e)
          (player.add-gold joueur (if (is-boss? e) 80 (math.random 5 20)))
          (table.remove enemies i)))))

  ;; Fin de salle: ouverture de porte + spawn de la recompense devant la sortie.
  (when (and (not (world.is-shop?))
             (= (# enemies) 0)
             (not room-reward-spawned))
    (world.open-door)
    (trigger-door-pulse)
    (let [spawn (world.get-door-reward-spawn reward-pickup-size)]
      (table.insert pickups
        {:x spawn.x :y spawn.y :size reward-pickup-size :active true :phase (math.random 0 60)}))
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
  (when (and (not room-reward-required)
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
  (when (> fx.door-pulse 0)
    (let [progress (- DOOR-PULSE-DURATION fx.door-pulse)
          radius (+ 8 (math.floor (* progress 1.2)))
          col (if (= (% (// fx.door-pulse 2) 2) 0) 9 12)]
      (circb fx.door-pulse-x fx.door-pulse-y radius col)))
  (each [_ e (ipairs enemies)]
    (entity-draw e))
  (each [_ proj (ipairs projectiles)]
    (let [elapsed (- 120 proj.lifetime)
          frame (% (// elapsed 6) 3)
          angle (math.atan2 proj.vy proj.vx)
          rot (% (+ (math.floor (+ 0.5 (/ (* angle 2) math.pi))) 4) 4)]
      (spr (+ 200 frame) (- (math.floor proj.x) 4) (- (math.floor proj.y) 4) 15 1 0 rot)))
  (each [i pickup (ipairs pickups)]
    (let [phase (+ fx.frame (or pickup.phase (* i 9)))
          bob (math.floor (* (math.sin (/ phase PICKUP-BOB-SPEED)) PICKUP-BOB-AMPLITUDE))
          draw-y (+ pickup.y bob)
          pulse-r (+ 6 (math.floor (* (math.sin (/ phase 6)) 1.5)))]
      (spr spr-item-upgrade pickup.x draw-y 15)
      (circb (+ pickup.x 4) (+ draw-y 4) pulse-r (if (= (% (// phase 4) 2) 0) 9 12))))
  ;; Cône d'attaque épée
  (when (> joueur.sword-flash 0)
    (player.draw-attack-cone joueur))

  ;; Dessin des flashs éclair (zigzag en blanc)
  (each [_ f (ipairs lightning-flashes)]
    (let [mx (+ (/ (+ f.x1 f.x2) 2) f.jx)
          my (+ (/ (+ f.y1 f.y2) 2) f.jy)]
      (line f.x1 f.y1 mx my 9)
      (line mx my f.x2 f.y2 9)))
  (when (> fx.player-hit-overlay 0)
    (let [col (if (= (% (// fx.player-hit-overlay 2) 2) 0) 6 12)]
      (rect 0 16 240 2 col)
      (rect 0 134 240 2 col)
      (rect 0 16 2 120 col)
      (rect 238 16 2 120 col)))
  (when (world.is-shop?)
    (draw-shop-items))
  (player.draw-ui joueur)
  (player.draw-gold-ui joueur)
  (player.draw joueur))

;; --- MOTEUR 3D (MENU & INTRO) ---
(var global-t 0)

;; Etoiles
(local stars [])
(for [i 1 60]
  (table.insert stars
    {:x (- (math.random 200) 100)
     :y (- (math.random 200) 100)
     :z (math.random 10 200)}))

(fn update-stars []
  (each [_ s (ipairs stars)]
    (set s.z (- s.z 1.5))
    (when (< s.z 1)
      (set s.z 200)
      (set s.x (- (math.random 200) 100))
      (set s.y (- (math.random 200) 100)))))

(fn draw-stars []
  (each [_ s (ipairs stars)]
    (let [px (+ 120 (/ (* s.x 100) s.z))
          py (+ 68 (/ (* s.y 100) s.z))]
      (when (and (> px 0) (< px 240) (> py 0) (< py 136))
        (let [col (if (< s.z 50) 15 (< s.z 120) 13 8)] ;; Etoiles: Blanc (15), Cyan (13), Bleu (8)
          (pix (math.floor px) (math.floor py) col))))))

;; Cube Filaire 3D
(local cube-verts 
  [[-1 -1 -1] [ 1 -1 -1] [ 1  1 -1] [-1  1 -1]
   [-1 -1  1] [ 1 -1  1] [ 1  1  1] [-1  1  1]])
   
(local cube-edges
  [[1 2] [2 3] [3 4] [4 1]
   [5 6] [6 7] [7 8] [8 5]
   [1 5] [2 6] [3 7] [4 8]])

(var angle-x 0)
(var angle-y 0)
(var angle-z 0)

(fn rotate-3d [x y z ax ay az]
  (let [sy (math.sin ax) cy (math.cos ax)
        y1 (- (* y cy) (* z sy))
        z1 (+ (* y sy) (* z cy))]
    (let [sp (math.sin ay) cp (math.cos ay)
          x2 (+ (* x cp) (* z1 sp))
          z2 (+ (* x (- 0 sp)) (* z1 cp))]
      (let [sr (math.sin az) cr (math.cos az)
            x3 (- (* x2 cr) (* y1 sr))
            y3 (+ (* x2 sr) (* y1 cr))]
        [x3 y3 z2]))))

(fn draw-wireframe []
  (set angle-x (+ angle-x 0.02))
  (set angle-y (+ angle-y 0.03))
  (set angle-z (+ angle-z 0.01))
  
  (local proj-verts [])
  (each [_ v (ipairs cube-verts)]
    (let [r (rotate-3d (. v 1) (. v 2) (. v 3) angle-x angle-y angle-z)
          z (+ (- (. r 3)) 2.5) ;; focal depth
          scale (/ 45 z)
          px (+ 120 (* (. r 1) scale))
          py (+ 68 (* (. r 2) scale))]
      (table.insert proj-verts [px py z])))
      
  (each [_ e (ipairs cube-edges)]
    (let [v1 (. proj-verts (. e 1))
          v2 (. proj-verts (. e 2))]
      (let [col (if (< (. v1 3) 2.5) 11 5)] ;; Cube: Vert Fluo (11) au premier plan, Vert Foret (5) au fond
        (line (. v1 1) (. v1 2) (. v2 1) (. v2 2) col)))))

;; Texte Animé Sine Wave
(fn draw-wobbling-text [text cx cy base-color time-var]
  (let [len (string.len text)
        width (* len 6)
        start-x (- cx (/ width 2))]
    (for [i 1 len]
      (let [char (string.sub text i i)
            oy (* (math.sin (+ time-var (* i 0.5))) 4)]
        (print char (+ start-x (* (- i 1) 6)) (+ cy oy) base-color)))))

;; --- INTRO & MENU ---
(fn update-intro []
  (set global-t (+ global-t 0.05))
  (update-stars)
  (set intro-timer (- intro-timer 1))
  ;; Après 2 secondes le texte disparait, reset des timer, passage au menu
  (if (< intro-timer -30)
      (set game-state :menu)))

(fn draw-intro []
  (cls 0)
  (draw-stars)
  (draw-wireframe)
  (when (> intro-timer 0)
    (draw-wobbling-text "LES ZIGOTOS V3" 120 64 14 global-t)))

(fn update-menu []
  (set global-t (+ global-t 0.05))
  (update-stars)
  ;; Appuyez sur Z (key 26) ou le bouton A de TIC-80 pour jouer
  (when (or (keyp 26) (btnp 4))
    (set game-state :game)))

(fn draw-menu []
  (cls 0)
  (draw-stars)
  (draw-wireframe)
  (draw-wobbling-text "LES ZIGOTOS V3" 120 40 14 global-t) ;; Jaune (14)
  (set menu-blink (+ menu-blink 1))
  (when (< (% menu-blink 60) 30)
    (print "Appuyez sur Z pour jouer" 52 100 15))) ;; Blanc (15)

;; --- GAME OVER ---
(fn reset-game []
  ;; Réinitialisation complète du joueur et des listes
  (set joueur (player.new))
  (set joueur.x 24)
  (set joueur.y 64)
  (clear-list enemies)
  (clear-list projectiles)
  (clear-list lightning-flashes)
  (clear-list pickups)
  
  ;; Reset de l'état du monde
  (world.construire-map)
  (setup-room-encounter)
  
  ;; Reset des drapeaux de salle
  (set room-reward-spawned false)
  (set room-reward-required false)
  (set shop-items [])
  (set shop-msg "")
  (set shop-msg-timer 0)
  (set fx.door-pulse 0)
  (set fx.player-hit-overlay 0)
  
  ;; Relance la partie directement
  (set game-state :game))

(fn update-gameover []
  ;; Appuyer sur Z (26) ou Btn A (4) pour relancer
  (when (or (keyp 26) (btnp 4))
    (reset-game)))

(fn draw-gameover []
  (cls 0)
  (print "GAME OVER" 70 50 12 false 2)
  (set menu-blink (+ menu-blink 1))
  (when (< (% menu-blink 60) 30)
    (print "Appuyez sur Z pour recommencer" 45 90 15)))

;; Boucle principale
(fn _G.TIC []
  ;; Initialisation unique
  (when (not initialized)
    (world.init-assets)
    (setup-room-encounter)
    (set initialized true))
  (tick-fx)

  (if (= game-state :intro)
      (do
        (update-intro)
        (draw-intro))
        
      (= game-state :menu)
      (do
        (update-menu)
        (draw-menu))
        
      (= game-state :game)
      (do
        ;; Pause du jeu si l'ecran reward est ouvert
        (if (item.is-open? reward-screen)
            (item.update reward-screen joueur)
            (update-game))

        ;; Détection de la mort
        (when (<= joueur.hp 0)
          (set game-state :gameover))

        ;; Rendu
        (draw-game)
        (when (item.is-open? reward-screen)
          (item.draw reward-screen)))

      (= game-state :gameover)
      (do
        (update-gameover)
        (draw-gameover))))
