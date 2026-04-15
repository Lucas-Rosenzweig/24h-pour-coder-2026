local item
package.preload["item"] = package.preload["item"] or function(...)
  local item = {}
  local player = require("player")
  local function reward_key(reward)
    if (reward.kind == "spell-upgrade") then
      return (tostring(reward.kind) .. ":" .. reward["spell-id"] .. ":" .. reward.id)
    else
      return (tostring(reward.kind) .. ":" .. reward.id)
    end
  end
  local function reward_kind_label(reward)
    if (reward.kind == "sword-upgrade") then
      return "Upgrade epee"
    else
      if (reward.kind == "spell") then
        return "Sort"
      else
        if (reward.kind == "spell-upgrade") then
          return "Upgrade sort"
        else
          return "Utility"
        end
      end
    end
  end
  local function reward_desc(reward)
    return (reward.data.desc or "")
  end
  local function build_choices(p)
    local choices = {}
    local seen = {}
    local attempts = 0
    while ((#choices < 3) and (attempts < 30)) do
      local reward = player["get-random-reward"](p)
      attempts = (attempts + 1)
      if reward then
        local key = reward_key(reward)
        if not seen[key] then
          seen[key] = true
          table.insert(choices, reward)
        else
        end
      else
      end
    end
    return choices
  end
  item.new = function()
    return {selected = 1, choices = {}, ["open?"] = false}
  end
  item.open = function(state, p)
    state["open?"] = true
    state.selected = 1
    state.choices = build_choices(p)
    return nil
  end
  item.close = function(state)
    state["open?"] = false
    state.selected = 1
    state.choices = {}
    return nil
  end
  item["is-open?"] = function(state)
    return state["open?"]
  end
  item.update = function(state, p)
    if state["open?"] then
      if ((#state.choices > 0) and btnp(2)) then
        state.selected = math.max(1, (state.selected - 1))
      else
      end
      if ((#state.choices > 0) and btnp(3)) then
        state.selected = math.min(#state.choices, (state.selected + 1))
      else
      end
      if ((#state.choices > 0) and btnp(4)) then
        local choice = state.choices[state.selected]
        player["apply-reward"](p, choice)
        return item.close(state)
      else
        return nil
      end
    else
      return nil
    end
  end
  item["draw-card"] = function(reward, x, y, w, h, selected_3f)
    local bg
    if selected_3f then
      bg = 6
    else
      bg = 1
    end
    local border
    if selected_3f then
      border = 12
    else
      border = 13
    end
    local title_color
    if selected_3f then
      title_color = 12
    else
      title_color = 6
    end
    rect(x, y, w, h, bg)
    rectb(x, y, w, h, border)
    print(reward_kind_label(reward), (x + 5), (y + 6), title_color, false, 1, true)
    print(reward.data.name, (x + 5), (y + 18), 12, false, 1, true)
    return print(reward_desc(reward), (x + 5), (y + 32), 13, false, 1, true)
  end
  item.draw = function(state)
    if state["open?"] then
      rect(12, 16, 216, 104, 0)
      rectb(12, 16, 216, 104, 12)
      print("Choisis une carte", 70, 22, 12, false, 1, true)
      print("< > changer  X valider", 51, 108, 13, false, 1, true)
      for i, reward in ipairs(state.choices) do
        item["draw-card"](reward, (20 + ((i - 1) * 68)), 38, 64, 58, (i == state.selected))
      end
      return nil
    else
      return nil
    end
  end
  return item
end
package.preload["player"] = package.preload["player"] or function(...)
  local player = {}
  local abilities = require("abilities")
  local function random_choice(xs)
    if (#xs > 0) then
      return xs[math.random(1, #xs)]
    else
      return nil
    end
  end
  player.new = function()
    return {x = 120, y = 68, size = 8, speed = 2, color = 12, hp = 10, ["max-hp"] = 10, ["id-sword-upgrades"] = {0}, ["id-spell-upgrades"] = {id = nil, ["applied-upgrades"] = {}}, ["id-utility"] = -1, ["utility-cooldown"] = 0, ["i-frames"] = 0, ["spell-cooldown"] = 0, ["sword-flash"] = 0, ["sword-hits-left"] = 0, ["sword-hit-due"] = false}
  end
  player.update = function(p, world, enemies)
    local function hit_enemy_3f(nx, ny)
      local hit = false
      do
        local soft_size = (p.size - 2)
        for _, e in ipairs(enemies) do
          if world["collide?"]((nx + 1), (ny + 1), soft_size, e.x, e.y, e.size) then
            hit = true
          else
          end
        end
      end
      return hit
    end
    do
      local dy
      if btn(0) then
        dy = ( - p.speed)
      else
        if btn(1) then
          dy = p.speed
        else
          dy = 0
        end
      end
      if (dy ~= 0) then
        if (world["can-move?"](p.x, (p.y + dy), p.size) and not hit_enemy_3f(p.x, (p.y + dy))) then
          p.y = (p.y + dy)
        else
        end
      else
      end
    end
    do
      local dx
      if btn(2) then
        dx = ( - p.speed)
      else
        if btn(3) then
          dx = p.speed
        else
          dx = 0
        end
      end
      if (dx ~= 0) then
        if (world["can-move?"]((p.x + dx), p.y, p.size) and not hit_enemy_3f((p.x + dx), p.y)) then
          p.x = (p.x + dx)
        else
        end
      else
      end
    end
    if (p.x < 0) then
      p.x = 0
    else
    end
    if (p.y < 20) then
      p.y = 20
    else
    end
    if (p.x > (240 - p.size)) then
      p.x = (240 - p.size)
    else
    end
    if (p.y > (136 - p.size)) then
      p.y = (136 - p.size)
    else
    end
    do
      local dx
      if btn(2) then
        dx = -1
      else
        if btn(3) then
          dx = 1
        else
          dx = 0
        end
      end
      local dy
      if btn(0) then
        dy = -1
      else
        if btn(1) then
          dy = 1
        else
          dy = 0
        end
      end
      if ((dx ~= 0) or (dy ~= 0)) then
        p["facing-angle"] = math.atan2(dy, dx)
      else
      end
    end
    if (p["sword-flash"] > 0) then
      p["sword-flash"] = (p["sword-flash"] - 1)
      if (p["sword-flash"] == 0) then
        p["sword-hit-due"] = true
        if (p["sword-hits-left"] > 1) then
          p["sword-hits-left"] = (p["sword-hits-left"] - 1)
          p["sword-flash"] = 8
        else
        end
      else
      end
    else
    end
    if (p["spell-cooldown"] > 0) then
      p["spell-cooldown"] = (p["spell-cooldown"] - 1)
    else
    end
    if (p["utility-cooldown"] > 0) then
      p["utility-cooldown"] = (p["utility-cooldown"] - 1)
    else
    end
    if (p["i-frames"] > 0) then
      p["i-frames"] = (p["i-frames"] - 1)
      return nil
    else
      return nil
    end
  end
  player.draw = function(p)
    return spr(12, p.x, p.y, 0)
  end
  player["take-damage"] = function(p, dmg)
    if (p["i-frames"] <= 0) then
      p.hp = (p.hp - dmg)
      if (p.hp < 0) then
        p.hp = 0
        return nil
      else
        return nil
      end
    else
      return nil
    end
  end
  player["draw-ui"] = function(p)
    rect(5, 5, 50, 6, 1)
    rect(5, 5, (50 * (p.hp / p["max-hp"])), 6, 11)
    return rectb(5, 5, 50, 6, 12)
  end
  player.heal = function(p, amount)
    p.hp = (p.hp + amount)
    if (p.hp > p["max-hp"]) then
      p.hp = p["max-hp"]
      return nil
    else
      return nil
    end
  end
  player["get-random-reward"] = function(p)
    local choices = {}
    local sword_id = random_choice(abilities["get-all-sword-upgrade-ids"]())
    local spell_id = p["id-spell-upgrades"].id
    local spell_upgrade_ids = abilities["get-available-spell-upgrade-ids"](p["id-spell-upgrades"])
    local utility_ids = {}
    if sword_id then
      table.insert(choices, {kind = "sword-upgrade", id = sword_id, data = abilities["get-sword-upgrade"](sword_id)})
    else
    end
    if (spell_id == nil) then
      local new_spell_id = random_choice(abilities["get-all-spell-ids"]())
      if new_spell_id then
        table.insert(choices, {kind = "spell", id = new_spell_id, data = abilities["get-spell"](new_spell_id)})
      else
      end
    else
      local spell_upgrade_id = random_choice(spell_upgrade_ids)
      if spell_upgrade_id then
        table.insert(choices, {kind = "spell-upgrade", ["spell-id"] = spell_id, id = spell_upgrade_id, data = abilities["get-spell-upgrade"](spell_id, spell_upgrade_id)})
      else
      end
    end
    for _, id in ipairs(abilities["get-all-utility-ids"]()) do
      if (id ~= p["id-utility"]) then
        table.insert(utility_ids, id)
      else
      end
    end
    do
      local utility_id = random_choice(utility_ids)
      if utility_id then
        table.insert(choices, {kind = "utility", id = utility_id, data = abilities["get-utility"](utility_id)})
      else
      end
    end
    return random_choice(choices)
  end
  player["apply-reward"] = function(p, reward)
    if reward then
      if (reward.kind == "sword-upgrade") then
        return table.insert(p["id-sword-upgrades"], reward.id)
      else
        if (reward.kind == "spell") then
          p["id-spell-upgrades"]["id"] = reward.id
          p["id-spell-upgrades"]["applied-upgrades"] = {}
          return nil
        else
          if (reward.kind == "spell-upgrade") then
            return table.insert(p["id-spell-upgrades"]["applied-upgrades"], reward.id)
          else
            if (reward.kind == "utility") then
              p["id-utility"] = reward.id
              return nil
            else
              return nil
            end
          end
        end
      end
    else
      return nil
    end
  end
  player["use-utility"] = function(p, world)
    if ((p["id-utility"] ~= -1) and (p["utility-cooldown"] <= 0)) then
      local util = abilities["get-utility"](p["id-utility"])
      if (util.type == "active") then
        if (p["id-utility"] == 1) then
          local facing = (p["facing-angle"] or 0)
          local dist = util.stats.distance
          local nx = (p.x + (dist * math.cos(facing)))
          local ny = (p.y + (dist * math.sin(facing)))
          p.x = math.max(0, math.min(nx, (240 - p.size)))
          p.y = math.max(20, math.min(ny, (136 - p.size)))
          p["i-frames"] = util.stats["i-frames"]
          p["utility-cooldown"] = util.stats.cooldown
          return nil
        else
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  end
  player["draw-attack-cone"] = function(p)
    local stats = abilities["compute-sword-stats"](p["id-sword-upgrades"])
    local facing = (p["facing-angle"] or 0)
    local half_arc = ((math.max(stats.arc, 15) / 2) * (math.pi / 180))
    local cx = (p.x + (p.size / 2))
    local cy = (p.y + (p.size / 2))
    local r = stats.range
    local a1 = (facing - half_arc)
    local progress = ((8 - p["sword-flash"]) / 8)
    local swept = (progress * 2 * half_arc)
    local cur_angle = (a1 + swept)
    line(cx, cy, (cx + (r * math.cos(cur_angle))), (cy + (r * math.sin(cur_angle))), 12)
    for i = 0, 5 do
      local t1 = (a1 + ((i / 6) * swept))
      local t2 = (a1 + (((i + 1) / 6) * swept))
      line((cx + (r * math.cos(t1))), (cy + (r * math.sin(t1))), (cx + (r * math.cos(t2))), (cy + (r * math.sin(t2))), 12)
    end
    return nil
  end
  player["do-sword-hit"] = function(p, enemies, enemie)
    local stats = abilities["compute-sword-stats"](p["id-sword-upgrades"])
    local facing = (p["facing-angle"] or 0)
    local half_arc = ((math.max(stats.arc, 15) / 2) * (math.pi / 180))
    local cx = (p.x + (p.size / 2))
    local cy = (p.y + (p.size / 2))
    for _, e in ipairs(enemies) do
      local dx = ((e.x + (e.size / 2)) - cx)
      local dy = ((e.y + (e.size / 2)) - cy)
      local dist = math.sqrt(((dx * dx) + (dy * dy)))
      if (dist < stats.range) then
        local angle_to_enemy = math.atan2(dy, dx)
        local diff = math.abs((angle_to_enemy - facing))
        local norm_diff
        if (diff > math.pi) then
          norm_diff = ((2 * math.pi) - diff)
        else
          norm_diff = diff
        end
        if (norm_diff <= half_arc) then
          enemie["take-damage"](e, stats.damage)
        else
        end
      else
      end
    end
    return nil
  end
  player.attack = function(p, enemies, enemie)
    local stats = abilities["compute-sword-stats"](p["id-sword-upgrades"])
    p["sword-flash"] = 8
    p["sword-hits-left"] = stats.hits
    return nil
  end
  player["spell-attack"] = function(p, enemies, enemie, projectiles, lightning_flashes)
    if ((p["id-spell-upgrades"].id ~= nil) and (p["spell-cooldown"] <= 0)) then
      local stats = abilities["compute-spell-stats"](p["id-spell-upgrades"])
      local facing = (p["facing-angle"] or 0)
      local cx = (p.x + (p.size / 2))
      local cy = (p.y + (p.size / 2))
      p["spell-cooldown"] = stats.cooldown
      if (p["id-spell-upgrades"].id == 1) then
        local total = stats.projectiles
        local spread_rad = ((stats.spread or 0) * (math.pi / 180))
        local start_angle
        if (total > 1) then
          start_angle = (facing - (spread_rad * 0.5))
        else
          start_angle = facing
        end
        local step
        if (total > 1) then
          step = (spread_rad / (total - 1))
        else
          step = 0
        end
        for i = 0, (total - 1) do
          local angle = (start_angle + (i * step))
          table.insert(projectiles, {x = cx, y = cy, vx = (stats.speed * math.cos(angle)), vy = (stats.speed * math.sin(angle)), damage = stats.damage, radius = stats.radius, aoe = (stats.aoe or 0), dot = (stats.dot or 0), ["dot-dur"] = (stats["dot-dur"] or 0), alive = true, lifetime = 120})
        end
        return nil
      else
        local range = 80
        local best_e = nil
        local best_dist = 9999
        for _, e in ipairs(enemies) do
          local dx = (e.x - cx)
          local dy = (e.y - cy)
          local dist = math.sqrt(((dx * dx) + (dy * dy)))
          if ((dist < range) and (dist < best_dist)) then
            best_e = e
            best_dist = dist
          else
          end
        end
        if best_e then
          enemie["take-damage"](best_e, stats.damage)
          if (stats.stun > 0) then
            enemie["apply-stun"](best_e, stats.stun)
          else
          end
          do
            local ex = (best_e.x + (best_e.size / 2))
            local ey = (best_e.y + (best_e.size / 2))
            local ddx = (ex - cx)
            local ddy = (ey - cy)
            table.insert(lightning_flashes, {x1 = cx, y1 = cy, x2 = ex, y2 = ey, jx = (( - ddy) / 4), jy = (ddx / 4), timer = 8})
          end
          if (stats.chain > 0) then
            local hit_set = {}
            hit_set[best_e] = true
            local last_target = best_e
            local chains_left = stats.chain
            while (chains_left > 0) do
              local next_e = nil
              local next_dist = 9999
              for _, e in ipairs(enemies) do
                if not hit_set[e] then
                  local dx = (e.x - last_target.x)
                  local dy = (e.y - last_target.y)
                  local dist = math.sqrt(((dx * dx) + (dy * dy)))
                  if ((dist < 40) and (dist < next_dist)) then
                    next_e = e
                    next_dist = dist
                  else
                  end
                else
                end
              end
              if next_e then
                enemie["take-damage"](next_e, stats.damage)
                if (stats.stun > 0) then
                  enemie["apply-stun"](next_e, stats.stun)
                else
                end
                do
                  local lx = (last_target.x + (last_target.size / 2))
                  local ly = (last_target.y + (last_target.size / 2))
                  local nx = (next_e.x + (next_e.size / 2))
                  local ny = (next_e.y + (next_e.size / 2))
                  local ddx = (nx - lx)
                  local ddy = (ny - ly)
                  table.insert(lightning_flashes, {x1 = lx, y1 = ly, x2 = nx, y2 = ny, jx = (( - ddy) / 4), jy = (ddx / 4), timer = 8})
                end
                hit_set[next_e] = true
                last_target = next_e
                chains_left = (chains_left - 1)
              else
                chains_left = 0
              end
            end
            return nil
          else
            return nil
          end
        else
          return nil
        end
      end
    else
      return nil
    end
  end
  return player
end
package.preload["abilities"] = package.preload["abilities"] or function(...)
  local abilities = {}
  local SWORD_BASE = {damage = 1, cooldown = 2, range = 12, arc = 120, hits = 1}
  local sword_upgrades = {{name = "Degats+", type = "stat", ["stack?"] = true, effects = {damage = 3}}, {name = "Vitesse+", type = "stat", ["stack?"] = true, effects = {cooldown = -3}}, {name = "Portee+", type = "stat", ["stack?"] = true, effects = {range = 4}}, {name = "Arc tranchant", type = "behavior", ["stack?"] = true, effects = {arc = 60}}, {name = "Double frappe", type = "behavior", ["stack?"] = true, effects = {hits = 1}}}
  abilities["compute-sword-stats"] = function(upgrade_ids)
    local stats = {damage = SWORD_BASE.damage, cooldown = SWORD_BASE.cooldown, range = SWORD_BASE.range, arc = SWORD_BASE.arc, hits = SWORD_BASE.hits}
    for _, id in ipairs(upgrade_ids) do
      if (id ~= 0) then
        local upg = sword_upgrades[id]
        for k, v in pairs(upg.effects) do
          if (type(v) == "boolean") then
            stats[k] = v
          else
            stats[k] = (stats[k] + v)
          end
        end
      else
      end
    end
    if (stats.cooldown < 6) then
      stats.cooldown = 6
    else
    end
    return stats
  end
  local spells = {{name = "Boule de feu", desc = "Projectile droit, degats de zone", base = {damage = 2, cooldown = 40, speed = 3, radius = 8, aoe = 0, dot = 0, ["dot-dur"] = 0, projectiles = 1, spread = 0}, upgrades = {{name = "Explosion", desc = "Zone de degats a l'impact (+16px)", effects = {aoe = 16}}, {name = "Brulure", desc = "3 degats/sec pendant 3 sec", effects = {dot = 3, ["dot-dur"] = 180}}, {name = "Triple boule", desc = "3 boules en eventail (15 deg)", effects = {projectiles = 2, spread = 15}}}}, {name = "Foudre", desc = "Frappe instantanee, peut chainer entre ennemis", base = {damage = 2, cooldown = 50, chain = 0, stun = 0}, upgrades = {{name = "Chaine", desc = "Rebondit sur 2 ennemis proches", effects = {chain = 2}}, {name = "Paralysie", desc = "Etourdit l'ennemi pendant 1 sec", effects = {stun = 60}}}}}
  abilities["compute-spell-stats"] = function(spell_state)
    if (spell_state.id ~= nil) then
      local def = spells[spell_state.id]
      local stats = {}
      for k, v in pairs(def.base) do
        stats[k] = v
      end
      for _, sub_id in ipairs(spell_state["applied-upgrades"]) do
        local upg = def.upgrades[sub_id]
        for k, v in pairs(upg.effects) do
          stats[k] = ((stats[k] or 0) + v)
        end
      end
      return stats
    else
      return nil
    end
  end
  local utilities = {{name = "Dash", type = "active", desc = "Teleportation 32px dans la direction du mouvement", stats = {distance = 32, cooldown = 90, ["i-frames"] = 10}}, {name = "Bouclier d'epines", type = "passive", desc = "Renvoie 5 degats aux ennemis quand ils frappent le joueur", stats = {["reflect-damage"] = 5}}}
  abilities["get-sword-upgrade"] = function(id)
    return sword_upgrades[id]
  end
  abilities["get-all-sword-upgrade-ids"] = function()
    local ids = {}
    for id, _ in pairs(sword_upgrades) do
      table.insert(ids, id)
    end
    return ids
  end
  abilities["get-spell"] = function(id)
    return spells[id]
  end
  abilities["get-all-spell-ids"] = function()
    local ids = {}
    for id, _ in pairs(spells) do
      table.insert(ids, id)
    end
    return ids
  end
  abilities["get-utility"] = function(id)
    return utilities[id]
  end
  abilities["get-all-utility-ids"] = function()
    local ids = {}
    for id, _ in pairs(utilities) do
      table.insert(ids, id)
    end
    return ids
  end
  abilities["get-spell-upgrade"] = function(spell_id, sub_id)
    local spell = spells[spell_id]
    if spell then
      return spell.upgrades[sub_id]
    else
      return nil
    end
  end
  abilities["get-available-spell-upgrade-ids"] = function(spell_state)
    if (spell_state.id == nil) then
      return {}
    else
      local ids = {}
      local def = spells[spell_state.id]
      local applied_set = {}
      for _, sub_id in ipairs(spell_state["applied-upgrades"]) do
        applied_set[sub_id] = true
      end
      for sub_id, _ in pairs(def.upgrades) do
        if not applied_set[sub_id] then
          table.insert(ids, sub_id)
        else
        end
      end
      return ids
    end
  end
  abilities["remaining-spell-upgrades"] = function(spell_state)
    if (spell_state.id == nil) then
      return 0
    else
      local def = spells[spell_state.id]
      local total
      do
        local n = 0
        for _, _0 in pairs(def.upgrades) do
          n = (n + 1)
        end
        total = n
      end
      local applied = #spell_state["applied-upgrades"]
      return (total - applied)
    end
  end
  return abilities
end
item = require("item")
local player = require("player")
local world
package.preload["world"] = package.preload["world"] or function(...)
  local M = {}
  M["design-spr"] = function(id, hex)
    local addr = (16384 + (id * 32))
    for i = 1, 64, 2 do
      local s1 = hex:sub(i, i)
      local s2 = hex:sub((i + 1), (i + 1))
      local p1
      local _80_
      if (s1 == "") then
        _80_ = "0"
      else
        _80_ = s1
      end
      p1 = tonumber(_80_, 16)
      local p2
      local _82_
      if (s2 == "") then
        _82_ = "0"
      else
        _82_ = s2
      end
      p2 = tonumber(_82_, 16)
      poke((addr + ((i - 1) // 2)), ((p2 * 16) + p1))
    end
    return nil
  end
  local map1_c = {{1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1}, {1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1}, {1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1}, {1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1}, {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1}, {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}}
  local map1_v = {{5, 4, 0, 1, 9, 9, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1}, {3, 2, 99, 8, 8, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 2, 6, 6, 6, 6, 6, 3, 99, 99, 99, 99, 2, 6, 6, 6, 6, 6, 3, 99, 99, 99, 2, 6, 6, 6, 3, 3}, {1, 0, 99, 2, 6, 6, 6, 6, 6, 3, 99, 99, 99, 99, 2, 6, 6, 6, 6, 6, 3, 99, 99, 99, 2, 6, 6, 6, 3, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 2, 6, 6, 3, 99, 99, 99, 2, 6, 6, 6, 3, 99, 99, 99, 2, 6, 6, 6, 3, 99, 99, 99, 2, 6, 3, 3}, {1, 0, 99, 2, 6, 6, 3, 99, 99, 99, 2, 6, 6, 6, 3, 99, 99, 99, 2, 6, 6, 6, 3, 99, 99, 99, 2, 6, 3, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {1, 0, 99, 2, 6, 6, 6, 3, 99, 99, 2, 6, 6, 6, 6, 3, 99, 99, 2, 6, 6, 6, 6, 3, 99, 99, 2, 6, 6, 6, 3}, {1, 0, 99, 2, 6, 6, 6, 3, 99, 99, 2, 6, 6, 6, 6, 3, 99, 99, 2, 6, 6, 6, 6, 3, 99, 99, 2, 6, 6, 6, 3}, {1, 0, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 3}, {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}
  local map_v = {}
  local matrice_active = map1_c
  M["construire-map"] = function()
    map_v = {}
    for num_ligne, ligne in ipairs(map1_v) do
      local new_ligne = {}
      for num_col, id in ipairs(ligne) do
        local function _85_()
          if (id == 99) then
            if (math.random(100) > 70) then
              return 5
            else
              return 4
            end
          else
            return id
          end
        end
        table.insert(new_ligne, _85_())
      end
      table.insert(map_v, new_ligne)
    end
    return nil
  end
  M["init-assets"] = function()
    poke(16320, 68)
    poke(16321, 36)
    poke(16322, 52)
    poke(16323, 20)
    poke(16324, 12)
    poke(16325, 28)
    poke(16326, 133)
    poke(16327, 76)
    poke(16328, 48)
    poke(16329, 210)
    poke(16330, 125)
    poke(16331, 44)
    poke(16332, 133)
    poke(16333, 76)
    poke(16334, 48)
    poke(16335, 52)
    poke(16336, 101)
    poke(16337, 36)
    poke(16338, 208)
    poke(16339, 70)
    poke(16340, 72)
    poke(16341, 117)
    poke(16342, 113)
    poke(16343, 97)
    poke(16344, 89)
    poke(16345, 125)
    poke(16346, 206)
    poke(16347, 210)
    poke(16348, 125)
    poke(16349, 44)
    poke(16350, 133)
    poke(16351, 149)
    poke(16352, 161)
    poke(16353, 109)
    poke(16354, 170)
    poke(16355, 44)
    poke(16356, 210)
    poke(16357, 170)
    poke(16358, 153)
    poke(16359, 109)
    poke(16360, 194)
    poke(16361, 202)
    poke(16362, 218)
    poke(16363, 212)
    poke(16364, 94)
    poke(16365, 222)
    poke(16366, 238)
    poke(16367, 214)
    M["design-spr"](0, "0010010100100110001001011110011000100101001111100010010100100110")
    M["design-spr"](1, "0312201203122012031220120321111103122012031220120312201203122012")
    M["design-spr"](8, "0110010010100100011111001010010001100111101001000110010010100100")
    M["design-spr"](9, "0000000033333333111121112222122222221222000010001111111122221222")
    M["design-spr"](10, "2102213021022130210221302102213011111230210221302102213021022130")
    M["design-spr"](11, "3330000032233333322111110312322203133122031213000312203103122013")
    M["design-spr"](16, "0101010110101010111111110010000000100000111111110000100000001000")
    M["design-spr"](17, "2221222211111111000100002221222222212222111211113333333300000000")
    M["design-spr"](2, "2100000012100000012111110010100000110100001010110010010100100110")
    M["design-spr"](3, "0321111103122012031220120312201203122012031220120312201203122012")
    M["design-spr"](4, "0000000033333333211111111222222212222222100000001111111112222222")
    M["design-spr"](5, "3330000032233333322111110312322203133122031213000312203103122013")
    M["design-spr"](6, "8888888888888888888888888888888888888888888888888888888888888888")
    M["design-spr"](12, "000CC00000CCCC000C222C000CBBBC0000BBBB0000333300000110000000000000")
    math.randomseed(tstamp())
    return M["construire-map"]()
  end
  M["wall?"] = function(x, y)
    if ((y < 20) or (x < 0) or (x > 239) or (y > 135)) then
      return true
    else
      local col = ((x // 8) + 1)
      local lig = (((y - 20) // 8) + 1)
      local ligne = matrice_active[lig]
      local valeur
      if ligne then
        valeur = (ligne[col] or 1)
      else
        valeur = 1
      end
      return (valeur == 1)
    end
  end
  M["can-move?"] = function(x, y, size)
    return not (M["wall?"](x, y) or M["wall?"]((x + (size - 1)), y) or M["wall?"](x, (y + (size - 1))) or M["wall?"]((x + (size - 1)), (y + (size - 1))))
  end
  M["collide?"] = function(x1, y1, s1, x2, y2, s2)
    return ((x1 < (x2 + s2)) and ((x1 + s1) > x2) and (y1 < (y2 + s2)) and ((y1 + s1) > y2))
  end
  M.draw = function()
    for num_ligne, ligne in ipairs(map_v) do
      for num_col, id in ipairs(ligne) do
        spr(id, ((num_col - 1) * 8), (20 + ((num_ligne - 1) * 8)), 0)
      end
    end
    return nil
  end
  return M
end
world = require("world")
local initialized = false
local enemie
package.preload["enemie"] = package.preload["enemie"] or function(...)
  local enemie = {}
  local astar = require("astar")
  local abilities = require("abilities")
  enemie.new = function(x, y)
    return {x = x, y = y, size = 8, speed = 0.5, color = 8, hp = 3, ["attack-timer"] = 0, ["stun-timer"] = 0, ["dot-timer"] = 0, ["dot-dmg"] = 0, ["dot-tick"] = 0}
  end
  enemie.distance = function(e, joueur)
    return math.sqrt((((joueur.x - e.x) * (joueur.x - e.x)) + ((joueur.y - e.y) * (joueur.y - e.y))))
  end
  enemie.update = function(e, joueur, world, enemies)
    if (e["dot-timer"] > 0) then
      e["dot-timer"] = (e["dot-timer"] - 1)
      e["dot-tick"] = (e["dot-tick"] + 1)
      if (e["dot-tick"] >= 60) then
        e["dot-tick"] = 0
        e.hp = (e.hp - e["dot-dmg"])
      else
      end
      if (e["dot-timer"] <= 0) then
        e["dot-dmg"] = 0
        e["dot-tick"] = 0
      else
      end
    else
    end
    if (e["stun-timer"] > 0) then
      e["stun-timer"] = (e["stun-timer"] - 1)
    else
    end
    if (e["stun-timer"] <= 0) then
      if not e.path then
        e.path = {}
      else
      end
      if not e["path-timer"] then
        e["path-timer"] = 0
      else
      end
      e["path-timer"] = (e["path-timer"] - 1)
      if (e["path-timer"] <= 0) then
        local custom_wall_fn
        local function _103_(px, py)
          local is_wall = world["wall?"](px, py)
          if not is_wall then
            for _, other in ipairs(enemies) do
              if ((other ~= e) and (px >= other.x) and (px <= (other.x + other.size)) and (py >= other.y) and (py <= (other.y + other.size))) then
                is_wall = true
              else
              end
            end
          else
          end
          return is_wall
        end
        custom_wall_fn = _103_
        e.path = astar["find-path"]((e.x + 4), (e.y + 4), (joueur.x + 4), (joueur.y + 4), custom_wall_fn)
        e["path-timer"] = (60 + math.random(0, 10))
      else
      end
      local dx = 0
      local dy = 0
      if (#e.path > 0) then
        local target = e.path[1]
        local tx = target[1]
        local ty = target[2]
        local diff_x = (tx - e.x)
        local diff_y = (ty - e.y)
        local dist = math.sqrt(((diff_x * diff_x) + (diff_y * diff_y)))
        if (dist <= e.speed) then
          e.x = tx
          e.y = ty
          table.remove(e.path, 1)
        else
          dx = (diff_x / dist)
          dy = (diff_y / dist)
        end
      else
      end
      local function hit_other_enemie_3f(nx, ny)
        local hit = false
        do
          local soft_size = (e.size - 2)
          for _, other in ipairs(enemies) do
            if ((other ~= e) and world["collide?"]((nx + 1), (ny + 1), soft_size, other.x, other.y, other.size)) then
              hit = true
            else
            end
          end
        end
        return hit
      end
      local nx = (e.x + (dx * e.speed))
      local ny = (e.y + (dy * e.speed))
      if ((dx ~= 0) and world["can-move?"](nx, e.y, e.size) and not world["collide?"](nx, e.y, e.size, joueur.x, joueur.y, joueur.size) and not hit_other_enemie_3f(nx, e.y)) then
        e.x = nx
      else
      end
      if ((dy ~= 0) and world["can-move?"](e.x, ny, e.size) and not world["collide?"](e.x, ny, e.size, joueur.x, joueur.y, joueur.size) and not hit_other_enemie_3f(e.x, ny)) then
        e.y = ny
      else
      end
    else
    end
    if (e["attack-timer"] > 0) then
      e["attack-timer"] = (e["attack-timer"] - 1)
      return nil
    else
      return nil
    end
  end
  enemie.attack = function(e, joueur, take_damage, world)
    if (world["collide?"]((e.x - 1), (e.y - 1), (e.size + 2), joueur.x, joueur.y, joueur.size) and (e["attack-timer"] == 0)) then
      take_damage(joueur, 1)
      e["attack-timer"] = 30
      if (joueur["id-utility"] == 2) then
        local util = abilities["get-utility"](2)
        return enemie["take-damage"](e, util.stats["reflect-damage"])
      else
        return nil
      end
    else
      return nil
    end
  end
  enemie["take-damage"] = function(e, dmg)
    e.hp = (e.hp - dmg)
    return nil
  end
  enemie["apply-dot"] = function(e, dmg, dur)
    e["dot-dmg"] = dmg
    e["dot-timer"] = dur
    e["dot-tick"] = 0
    return nil
  end
  enemie["apply-stun"] = function(e, frames)
    if (frames > e["stun-timer"]) then
      e["stun-timer"] = frames
      return nil
    else
      return nil
    end
  end
  enemie["is-dead?"] = function(e)
    return (e.hp <= 0)
  end
  enemie.draw = function(e)
    local x = math.floor(e.x)
    local y = math.floor(e.y)
    rect(x, y, e.size, e.size, e.color)
    rectb(x, y, e.size, e.size, 0)
    rect(x, (y - 3), e.size, 2, 1)
    return rect(x, (y - 3), (e.size * (e.hp / 3)), 2, 11)
  end
  return enemie
end
package.preload["astar"] = package.preload["astar"] or function(...)
  local M = {}
  local function heuristic(x1, y1, x2, y2)
    return (math.abs((x1 - x2)) + math.abs((y1 - y2)))
  end
  local function make_key(x, y)
    return (x .. "," .. y)
  end
  M["find-path"] = function(sx, sy, tx, ty, wall_3f)
    local start_x = ((sx // 8) + 1)
    local start_y = (((sy - 20) // 8) + 1)
    local target_x = ((tx // 8) + 1)
    local target_y = (((ty - 20) // 8) + 1)
    local path = {}
    if wall_3f(tx, ty) then
      return path
    else
      local open_set = {{start_x, start_y}}
      local came_from = {}
      local g_score = {[make_key(start_x, start_y)] = 0}
      local f_score = {[make_key(start_x, start_y)] = heuristic(start_x, start_y, target_x, target_y)}
      local function get_score(score_map, k)
        return (score_map[k] or 999999)
      end
      local found = false
      local iter = 0
      while ((#open_set > 0) and not found and (iter < 1000)) do
        iter = (iter + 1)
        local current_idx = 1
        local current_f = get_score(f_score, make_key(open_set[1][1], open_set[1][2]))
        for i = 2, #open_set do
          local pt = open_set[i]
          local f = get_score(f_score, make_key(pt[1], pt[2]))
          if (f < current_f) then
            current_f = f
            current_idx = i
          else
          end
        end
        local current = open_set[current_idx]
        local cx = current[1]
        local cy = current[2]
        local k = make_key(cx, cy)
        if ((cx == target_x) and (cy == target_y)) then
          found = true
        else
          table.remove(open_set, current_idx)
          for _, dir in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
            local nx = (cx + dir[1])
            local ny = (cy + dir[2])
            local nk = make_key(nx, ny)
            local px = (((nx - 1) * 8) + 4)
            local py = (((ny - 1) * 8) + 24)
            if not wall_3f(px, py) then
              local tentative_g = (get_score(g_score, k) + 1)
              if (tentative_g < get_score(g_score, nk)) then
                came_from[nk] = current
                g_score[nk] = tentative_g
                f_score[nk] = (tentative_g + heuristic(nx, ny, target_x, target_y))
                local in_open = false
                for _0, p in ipairs(open_set) do
                  if ((p[1] == nx) and (p[2] == ny)) then
                    in_open = true
                  else
                  end
                end
                if not in_open then
                  table.insert(open_set, {nx, ny})
                else
                end
              else
              end
            else
            end
          end
        end
      end
      if found then
        local curr = {target_x, target_y}
        while curr do
          do
            local px = ((((curr[1] - 1) * 8) + 4) - 4)
            local py = ((((curr[2] - 1) * 8) + 24) - 4)
            table.insert(path, 1, {px, py})
          end
          if ((curr[1] == start_x) and (curr[2] == start_y)) then
            curr = nil
          else
            curr = came_from[make_key(curr[1], curr[2])]
          end
        end
      else
      end
      return path
    end
  end
  return M
end
enemie = require("enemie")
local enemies = {}
local projectiles = {}
local lightning_flashes = {}
local reward_screen = item.new()
local pickups = {}
local pickup_spawn_timer = 180
local pickup_spawn_delay = 300
local max_pickups = 3
table.insert(enemies, enemie.new(50, 50))
table.insert(enemies, enemie.new(180, 100))
table.insert(enemies, enemie.new(180, 90))
table.insert(enemies, enemie.new(180, 120))
local joueur = player.new()
local function player_overlap_item_3f(p, pickup)
  return (pickup.active and (math.abs((p.x - pickup.x)) < pickup.size) and (math.abs((p.y - pickup.y)) < pickup.size))
end
local function spawn_pickup()
  if (#pickups < max_pickups) then
    local attempts = 0
    local spawned = false
    while ((attempts < 20) and not spawned) do
      local x = (math.random(1, 28) * 8)
      local y = (20 + (math.random(1, 13) * 8))
      attempts = (attempts + 1)
      if (not world["wall?"](x, y) and not world["wall?"]((x + 7), (y + 7))) then
        table.insert(pickups, {x = x, y = y, size = 8, active = true})
        spawned = true
      else
      end
    end
    return nil
  else
    return nil
  end
end
local function update_game()
  player.update(joueur, world, enemies)
  pickup_spawn_timer = (pickup_spawn_timer - 1)
  if (pickup_spawn_timer <= 0) then
    spawn_pickup()
    pickup_spawn_timer = pickup_spawn_delay
  else
  end
  for i = #pickups, 1, -1 do
    local pickup = pickups[i]
    if player_overlap_item_3f(joueur, pickup) then
      table.remove(pickups, i)
      item.open(reward_screen, joueur)
    else
    end
  end
  if keyp(5) then
    player.attack(joueur, enemies, enemie)
  else
  end
  if joueur["sword-hit-due"] then
    joueur["sword-hit-due"] = false
    player["do-sword-hit"](joueur, enemies, enemie)
  else
  end
  if keyp(1) then
    player["spell-attack"](joueur, enemies, enemie, projectiles, lightning_flashes)
  else
  end
  if keyp(26) then
    player["use-utility"](joueur, world)
  else
  end
  for i, e in ipairs(enemies) do
    enemie.update(e, joueur, world, enemies)
    enemie.attack(e, joueur, player["take-damage"], world)
    if enemie["is-dead?"](e) then
      table.remove(enemies, i)
    else
    end
  end
  for i = #projectiles, 1, -1 do
    local proj = projectiles[i]
    proj.x = (proj.x + proj.vx)
    proj.y = (proj.y + proj.vy)
    proj.lifetime = (proj.lifetime - 1)
    if (proj.lifetime <= 0) then
      proj.alive = false
    else
    end
    if world["wall?"](proj.x, proj.y) then
      proj.alive = false
    else
    end
    if proj.alive then
      for _, e in ipairs(enemies) do
        if (proj.alive and not enemie["is-dead?"](e)) then
          local dx = (e.x - proj.x)
          local dy = (e.y - proj.y)
          local dist = math.sqrt(((dx * dx) + (dy * dy)))
          if (dist < (proj.radius + (e.size / 2))) then
            enemie["take-damage"](e, proj.damage)
            if (proj.dot > 0) then
              enemie["apply-dot"](e, proj.dot, proj["dot-dur"])
            else
            end
            if (proj.aoe > 0) then
              for _0, e2 in ipairs(enemies) do
                if (e2 ~= e) then
                  local ax = (e2.x - proj.x)
                  local ay = (e2.y - proj.y)
                  local adist = math.sqrt(((ax * ax) + (ay * ay)))
                  if (adist < proj.aoe) then
                    enemie["take-damage"](e2, proj.damage)
                    if (proj.dot > 0) then
                      enemie["apply-dot"](e2, proj.dot, proj["dot-dur"])
                    else
                    end
                  else
                  end
                else
                end
              end
            else
            end
            proj.alive = false
          else
          end
        else
        end
      end
    else
    end
    if not proj.alive then
      table.remove(projectiles, i)
    else
    end
  end
  for i = #lightning_flashes, 1, -1 do
    local f = lightning_flashes[i]
    f.timer = (f.timer - 1)
    if (f.timer <= 0) then
      table.remove(lightning_flashes, i)
    else
    end
  end
  return nil
end
local function draw_game()
  cls(2)
  world.draw()
  for _, e in ipairs(enemies) do
    enemie.draw(e)
  end
  for _, proj in ipairs(projectiles) do
    circ(math.floor(proj.x), math.floor(proj.y), 3, 6)
  end
  for _, pickup in ipairs(pickups) do
    circ((pickup.x + 4), (pickup.y + 4), 4, 10)
    circ((pickup.x + 4), (pickup.y + 4), 2, 12)
  end
  if (joueur["sword-flash"] > 0) then
    player["draw-attack-cone"](joueur)
  else
  end
  for _, f in ipairs(lightning_flashes) do
    local mx = (((f.x1 + f.x2) / 2) + f.jx)
    local my = (((f.y1 + f.y2) / 2) + f.jy)
    line(f.x1, f.y1, mx, my, 12)
    line(mx, my, f.x2, f.y2, 12)
  end
  player["draw-ui"](joueur)
  return player.draw(joueur)
end
_G.TIC = function()
  if not initialized then
    world["init-assets"]()
    initialized = true
  else
  end
  if item["is-open?"](reward_screen) then
    item.update(reward_screen, joueur)
  else
    update_game()
  end
  draw_game()
  if item["is-open?"](reward_screen) then
    return item.draw(reward_screen)
  else
    return nil
  end
end
return _G.TIC
