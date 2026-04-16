(local item {})
(local player (include :player))

(fn reward-key [reward]
  (if (= reward.kind :spell-upgrade)
    (.. (tostring reward.kind) ":" reward.spell-id ":" reward.id)
    (.. (tostring reward.kind) ":" reward.id)))

(fn reward-kind-label [reward]
  (if (= reward.kind :sword-upgrade)
    "Upgrade epee"
    (if (= reward.kind :spell)
      "Sort"
      (if (= reward.kind :spell-upgrade)
        "Upgrade sort"
        "Utility"))))

(fn reward-desc [reward]
  (or reward.data.desc ""))

(fn reward-icon-spr [reward]
  (match reward.kind
    :sword-upgrade 203
    :spell (if (= reward.id 1) 200 204)
    :spell-upgrade (if (= reward.spell-id 1) 200 204)
    :utility (if (= reward.id 1) 205 209)
    _ nil))

(fn build-choices [p]
  (let [choices []
        seen {}]
    (var attempts 0)
    (while (and (< (# choices) 3) (< attempts 30))
      (let [reward (player.get-random-reward p)]
        (set attempts (+ attempts 1))
        (when reward
          (let [key (reward-key reward)]
            (when (not (. seen key))
              (tset seen key true)
              (table.insert choices reward))))))
    choices))

(fn item.new []
  {:open? false
   :selected 1
   :choices []})

(fn item.open [state p]
  (set state.open? true)
  (set state.selected 1)
  (set state.choices (build-choices p)))

(fn item.close [state]
  (set state.open? false)
  (set state.selected 1)
  (set state.choices []))

(fn item.is-open? [state]
  state.open?)

(fn item.update [state p]
  (when state.open?
    (when (and (> (# state.choices) 0) (btnp 2))
      (set state.selected (math.max 1 (- state.selected 1))))
    (when (and (> (# state.choices) 0) (btnp 3))
      (set state.selected (math.min (# state.choices) (+ state.selected 1))))
    (when (and (> (# state.choices) 0) (btnp 4))
      (let [choice (. state.choices state.selected)]
        (player.apply-reward p choice)
        (item.close state)))))

(fn item.draw-card [reward x y w h selected?]
  (let [bg (if selected? 6 1)
        border (if selected? 12 13)
        title-color (if selected? 12 6)
        icon (reward-icon-spr reward)]
    (rect x y w h bg)
    (rectb x y w h border)
    (print (reward-kind-label reward) (+ x 5) (+ y 6) title-color false 1 true)
    (when icon
      (spr icon (+ x (- w 14)) (+ y 6) 15))
    (print reward.data.name (+ x 5) (+ y 18) 12 false 1 true)
    (print (reward-desc reward) (+ x 5) (+ y 32) 13 false 1 true)))

(fn item.draw [state]
  (when state.open?
    (rect 12 16 216 104 0)
    (rectb 12 16 216 104 12)
    (print "Choisis une carte" 70 22 12 false 1 true)
    (print "< > changer  X valider" 51 108 13 false 1 true)
    (each [i reward (ipairs state.choices)]
      (item.draw-card reward
                      (+ 20 (* (- i 1) 68))
                      38
                      64
                      58
                      (= i state.selected)))))

item
