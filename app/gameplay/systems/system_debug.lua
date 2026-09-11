local gamecontext = require('app.gameplay.gamecontext')
local provider_level = require("app.gameplay.systems.provider_level")
---@class SystemDebug
local System = class("SystemDebug")

local debug_text = function (text, pos)
    msg.post("@render:", "draw_debug_text", {text = text, position = pos, color = vmath.vector4(0,0,0,1)})  
end


function System:awake()
    gamecontext.stats = {score = 0, buckets_reaches = {}, total_reaches = 0}
    self.level = provider_level.get()
end

function System:debug()
    local w, h = window.get_size()
    debug_text("Score:"..gamecontext.stats.score, vmath.vector3(w/2 - 25, 15,0))

    if(gamecontext.stats.total_reaches > 0) then
        for i = 0, #gamecontext.buckets - 1 do
            local _temp =  camera.world_to_screen(gamecontext.buckets[i + 1].pos)
            _temp.z = 0
            local hits = gamecontext.stats.buckets_reaches[i] or 0
            local percent = (hits / gamecontext.stats.total_reaches) * 100
            debug_text(string.format("%d\n%.1f%%", hits, percent), _temp + vmath.vector3(-10 + i * 3,-10,0))
        end
    end
end

function System:on_bucket_reach(data)
    gamecontext.stats.score = gamecontext.stats.score + self.level.values[data.basket_index + 1]
    gamecontext.stats.buckets_reaches[data.basket_index] = (gamecontext.stats.buckets_reaches[data.basket_index] or 0) + 1
    gamecontext.stats.total_reaches = gamecontext.stats.total_reaches + 1 
end

return System