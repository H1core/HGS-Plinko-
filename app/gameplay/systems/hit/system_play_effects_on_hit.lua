local gamecontext = require('app.gameplay.gamecontext')
---@class SystemPlayEffectsOnHit
local System = class("SystemPlayEffectsOnHit")

function System:awake()
    ---@class GameContext
    ---@field hit_positions vector3[] 

    gamecontext.hit_positions = {}
    self.hit_positions = gamecontext.hit_positions

    self.rnd_sfx_hit = function ()
        return "sfx_hit"..math.random(5)
    end
end

local sfx_props = {gate = 0.025}
function System:update(dt)

    local n = #self.hit_positions
    for i = n,1,-1 do
        local pos = self.hit_positions[i]
        
        self.hit_positions[i] = nil
        play_sound(self.rnd_sfx_hit(), sfx_props)
        factory.create("/factories#factory_fx_hit", pos)
    end
end

return System