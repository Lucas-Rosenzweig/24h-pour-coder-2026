local player
package.preload["player"] = package.preload["player"] or function(...)
  local player = {}
  player.new = function()
    return {x = 120, y = 68, size = 8, speed = 2, color = 12}
  end
  player.update = function(p)
    if btn(0) then
      p.y = (p.y - p.speed)
    else
    end
    if btn(1) then
      p.y = (p.y + p.speed)
    else
    end
    if btn(2) then
      p.x = (p.x - p.speed)
    else
    end
    if btn(3) then
      p.x = (p.x + p.speed)
    else
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
      return nil
    else
      return nil
    end
  end
  player.draw = function(p)
    return rect(p.x, p.y, p.size, p.size, p.color)
  end
  return player
end
player = require("player")
local joueur = player.new()
_G.TIC = function()
  player.update(joueur)
  cls(0)
  return player.draw(joueur)
end
return _G.TIC
