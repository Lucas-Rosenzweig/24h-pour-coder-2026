;; title:  Fennel-Doom: Fixed & Visible
;; author: Gemini
;; script: fennel

(var p {:x 3.5 :y 3.5 :a 0 :bob 0 :recoil 0})
;; Ennemis placés au milieu des cases vides (0.5) pour éviter les bugs de murs
(var enemies [{:x 4.5 :y 4.5 :hp 3 :alive true :hit 0}
              {:x 2.5 :y 5.5 :hp 3 :alive true :hit 0}])
(var projectiles [])
(var z-buffer [])

(local map [1 1 1 1 1 1 1 1
            1 0 0 0 0 0 0 1
            1 0 1 0 1 0 0 1
            1 0 0 0 0 0 0 1
            1 0 1 0 1 0 0 1
            1 1 1 1 1 1 1 1])
(local map-w 8)

(fn _G.TIC []
  ;; 1. LOGIQUE JOUEUR
  (let [rs 0.06 ms 0.05]
    (if (btn 2) (set p.a (- p.a rs)))
    (if (btn 3) (set p.a (+ p.a rs)))
    (let [dx (* (math.cos p.a) ms) dy (* (math.sin p.a) ms)]
      (each [_ b (ipairs [{:id 0 :dir 1} {:id 1 :dir -1}])]
        (when (btn b.id)
          (let [nx (+ p.x (* dx b.dir)) ny (+ p.y (* dy b.dir))]
            (if (= (or (. map (+ (* (math.floor p.y) map-w) (math.floor nx) 1)) 1) 0) (set p.x nx))
            (if (= (or (. map (+ (* (math.floor ny) map-w) (math.floor p.x) 1)) 1) 0) (set p.y ny))
            (set p.bob (+ p.bob 0.2)))))))

  ;; TIR (X)
  (if (btnp 4) 
    (do 
      (set p.recoil 10) 
      (table.insert projectiles {:x p.x :y p.y :a p.a :v 0.2 :l 100})))
  (if (> p.recoil 0) (set p.recoil (- p.recoil 1)))

  ;; 2. LOGIQUE PROJECTILES & DEGATS
  (each [i prj (ipairs projectiles)]
    (set prj.x (+ prj.x (* (math.cos prj.a) prj.v)))
    (set prj.y (+ prj.y (* (math.sin prj.a) prj.v)))
    (set prj.l (- prj.l 1))
    (let [tx (math.floor prj.x) ty (math.floor prj.y)]
      (if (> (or (. map (+ (* ty map-w) tx 1)) 0) 0) (set prj.l 0)))
    (each [_ e (ipairs enemies)]
      (when e.alive
        (let [dx (- prj.x e.x) dy (- prj.y e.y) dist (math.sqrt (+ (* dx dx) (* dy dy)))]
          (when (< dist 0.6) 
            (set e.hp (- e.hp 1)) (set e.hit 5) (set prj.l 0) 
            (if (<= e.hp 0) (set e.alive false))))))
    (if (<= prj.l 0) (table.remove projectiles i)))

  (each [_ e (ipairs enemies)] (if (> e.hit 0) (set e.hit (- e.hit 1))))

  ;; 3. RENDU 3D + Z-BUFFER
  (cls 0)
  (rect 0 68 240 68 1)
  
  ;; On vide le z-buffer avec une distance infinie au début
  (for [i 1 240] (tset z-buffer i 999))

  (for [x 0 239]
    (let [cam-x (- (* (/ x 240) 2) 1)
          rdx (+ (math.cos p.a) (* (- (math.sin p.a)) cam-x))
          rdy (+ (math.sin p.a) (* (math.cos p.a) cam-x))]
      (var tx (math.floor p.x)) (var ty (math.floor p.y))
      (let [ddx (math.abs (/ 1 rdx)) ddy (math.abs (/ 1 rdy))]
        (var sdx (if (< rdx 0) (* (- p.x tx) ddx) (* (- (+ tx 1) p.x) ddx)))
        (var sdy (if (< rdy 0) (* (- p.y ty) ddy) (* (- (+ ty 1) p.y) ddy)))
        (var side 0) (var hit 0)
        (while (= hit 0)
          (if (< sdx sdy) (do (set sdx (+ sdx ddx)) (set tx (+ tx (if (< rdx 0) -1 1))) (set side 0))
              (do (set sdy (+ sdy ddy)) (set ty (+ ty (if (< rdy 0) -1 1))) (set side 1)))
          (if (> (or (. map (+ (* ty map-w) tx 1)) 0) 0) (set hit 1)))
        
        (let [perp (if (= side 0) (- sdx ddx) (- sdy ddy))
              h (math.min 136 (// 136 perp))
              y1 (+ (// (- 136 h) 2) (math.sin p.bob))
              col (if (= side 0) 13 12)]
          (line x y1 x (+ y1 h) col)
          ;; Remplissage du Z-Buffer
          (tset z-buffer (+ x 1) perp)))))

  ;; 4. RENDU ENNEMIS & PROJECTILES (BILLBOARDS)
  (let [draw-list []]
    (each [_ e (ipairs enemies)] (if e.alive (table.insert draw-list {:x e.x :y e.y :sz 0.3 :col (if (> e.hit 0) 15 2)})))
    (each [_ prj (ipairs projectiles)] (table.insert draw-list {:x prj.x :y prj.y :sz 0.1 :col 4}))

    (each [_ obj (ipairs draw-list)]
      (let [dx (- obj.x p.x) dy (- obj.y p.y)
            dist (math.sqrt (+ (* dx dx) (* dy dy)))
            ang (math.atan2 dy dx)
            diff (math.atan2 (math.sin (- ang p.a)) (math.cos (- ang p.a)))]
        (when (< (math.abs diff) 1)
          (let [sx (+ 120 (* diff 240))
                sz (// 136 dist)
                sy (+ (// (- 136 sz) 2) (math.sin p.bob))
                ix (math.floor sx)]
            ;; Test de profondeur : On compare avec le z-buffer
            (if (and (> ix 0) (< ix 240))
                (let [z-dist (or (. z-buffer (+ ix 1)) 999)]
                  (if (< dist z-dist)
                      (circ sx (+ sy (/ sz 2)) (* sz obj.sz) obj.col)))))))))

  ;; 5. HUD
  (let [gx (+ 100 (* (math.sin (/ p.bob 2)) 5))
        gy (+ 80 (* (math.abs (math.cos (/ p.bob 2))) 3) (- p.recoil))]
    (rect (+ gx 15) gy 10 40 14) (rect (+ gx 10) (+ gy 20) 20 20 15))
  (line 118 68 122 68 15) (line 120 66 120 70 15))