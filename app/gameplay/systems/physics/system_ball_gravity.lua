local gamecontext = require('app.gameplay.gamecontext')

local V_GRAVITY = vmath.vector3(0, -GAMECONSTANT.GRAVITY, 0)

---@class SystemGravity
local System = class("SystemGravity")

function System:initialize()
end

function System:awake() 
    self.ball_array = gamecontext.balls
end

function System:update(dt)
    for _ , ball in ipairs(self.ball_array) do
        local gravity_scale = ball.gravity_scale or 1
        ball.velocity = ball.velocity + V_GRAVITY * gravity_scale * dt
        ball:set_pos(ball:get_pos() + ball.velocity * dt)
    end
end

return System
