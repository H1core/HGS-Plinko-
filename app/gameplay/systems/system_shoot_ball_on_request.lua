local gamecontext = require('app.gameplay.gamecontext')
local command_shoot_ball = require("app.gameplay.systems.command_shoot_ball")

---@class SystemShootBallOnRequest
local System = class("SystemShootBallOnRequest")

function System:awake() 
    gamecontext.requested_shoots = gamecontext.requested_shoots or 0
end

function System:update(dt)
    for i = 1, gamecontext.requested_shoots do
        command_shoot_ball.execute()
    end
    gamecontext.requested_shoots = 0
end

return System