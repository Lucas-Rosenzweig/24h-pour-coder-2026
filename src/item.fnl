(local item {})
(local player (include :player))

(local CARD-STAGGER 6)
(local CARD-ENTRY-DURATION 10)
(local CARD-CONFIRM-DURATION 8)

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
   :choices []
   :open-timer 0
   :confirm-timer 0
   :confirmed-choice nil
   :pending-choice nil})

(fn item.open [state p]
  (set state.open? true)
  (set state.selected 1)
  (set state.choices (build-choices p))
  (set state.open-timer 0)
  (set state.confirm-timer 0)
  (set state.confirmed-choice nil)
  (set state.pending-choice nil))

(fn item.close [state]
  (set state.open? false)
  (set state.selected 1)
  (set state.choices [])
  (set state.open-timer 0)
  (set state.confirm-timer 0)
  (set state.confirmed-choice nil)
  (set state.pending-choice nil))

(fn item.is-open? [state]
  state.open?)

(fn item.update [state p]
  (when state.open?
    (set state.open-timer (+ state.open-timer 1))
    (if (> state.confirm-timer 0)
        (do
          (set state.confirm-timer (- state.confirm-timer 1))
          (when (<= state.confirm-timer 0)
            (when state.pending-choice
              (player.apply-reward p state.pending-choice))
            (item.close state)))
        (do
          (when (and (> (# state.choices) 0) (btnp 2))
            (set state.selected (math.max 1 (- state.selected 1))))
          (when (and (> (# state.choices) 0) (btnp 3))
            (set state.selected (math.min (# state.choices) (+ state.selected 1))))
          (when (and (> (# state.choices) 0) (btnp 4))
            (let [choice (. state.choices state.selected)]
              (set state.pending-choice choice)
              (set state.confirmed-choice state.selected)
              (set state.confirm-timer CARD-CONFIRM-DURATION)))))))

(fn entry-offset-y [timer]
  (if (<= timer 0)
      10
      (let [progress (math.min 1 (/ timer CARD-ENTRY-DURATION))]
        (math.floor (* (- 1 progress) 10)))))

(fn pulse-color [timer a b]
  (if (= (% (// timer 2) 2) 0) a b))

(fn item.draw-card [reward x y w h selected? pulse-timer confirm?]
  (let [bg (if selected? 6 1)
        border (if selected?
                   (pulse-color pulse-timer 12 9)
                   13)
        title-color (if selected? 12 6)
        icon (reward-icon-spr reward)]
    (rect x y w h bg)
    (rectb x y w h border)
    (when confirm?
      (rectb (- x 1) (- y 1) (+ w 2) (+ h 2) (pulse-color pulse-timer 10 9)))
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
    (if (> state.confirm-timer 0)
        (print "Validation..." 84 108 9 false 1 true)
        (print "< > changer  X valider" 51 108 13 false 1 true))
    (each [i reward (ipairs state.choices)]
      (let [delay (* (- i 1) CARD-STAGGER)
            timer (- state.open-timer delay)
            y-offset (entry-offset-y timer)]
        (when (> timer 0)
          (item.draw-card reward
                          (+ 20 (* (- i 1) 68))
                          (+ 38 y-offset)
                          64
                          58
                          (= i state.selected)
                          state.open-timer
                          (and (> state.confirm-timer 0)
                               (= i state.confirmed-choice))))))))

item
