local gamecontext = require('app.gameplay.gamecontext')

local V_GRAVITY = vmath.vector3(0, -GAMECONSTANT.GRAVITY, 0)

---@class SystemGravity
local System = class("SystemGravity")

function System:update(dt)
    for _ , ball in ipairs(gamecontext.balls) do
        local gravity_scale = ball.gravity_scale or 1
        ball.velocity = ball.velocity + V_GRAVITY * gravity_scale * dt
        ball:set_pos(ball:get_pos() + ball.velocity * dt)
    end
end

return System
