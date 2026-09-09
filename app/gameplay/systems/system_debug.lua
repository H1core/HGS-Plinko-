local gamecontext = require('app.gameplay.gamecontext')
local command_shoot_ball = require("app.gameplay.systems.command_shoot_ball")
---@class SystemDebug
local System = class("SystemDebug")

function System:initialize(context)
end

function System:awake() 
end

function System:update(dt)
end

local ACT_SPACE = hash("space")
function System:on_input(action_id, action)
    if(action_id == ACT_SPACE and action.released) then
        command_shoot_ball.execute()
    end
end
return System