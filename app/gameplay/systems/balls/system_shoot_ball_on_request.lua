local gamecontext = require('app.gameplay.gamecontext')
local command_instantiate_ball = require("app.gameplay.systems.balls.command_instantiate_ball")

---@class SystemShootBallOnRequest
local System = class("SystemShootBallOnRequest")
local counter = 0
function System:awake() 
    gamecontext.requested_shoots = gamecontext.requested_shoots or 0
end

function System:update(dt)
    for i = 1, gamecontext.requested_shoots do
        local seed = socket.gettime() + counter
        counter = counter + 1
        command_instantiate_ball.execute(seed)
    end
    gamecontext.requested_shoots = 0
end

return System