local gamecontext = require("app.gameplay.gamecontext")
local command_instantiate_ball = require("app.gameplay.systems.balls.command_instantiate_ball")
local storage = require("app.scripts.storage")
local helper = require("app.gameplay.helper")
local provider_level = require("app.gameplay.systems.provider_level")

local M = {}

function M.execute()
    local save = storage.get("session")
    if(not save) then
        return
    end
    
    if(helper.level_hash(save.level) ~= provider_level.hash()) then
        return
    end
    for _ , ball in ipairs(gamecontext.balls) do
        go.delete(ball.go_url)
    end
    table.clear(gamecontext.balls)

    local balls = save.balls
    for _ , ball_state in ipairs(balls) do
        local go_ball = command_instantiate_ball.execute(ball_state.seed)
        go_ball:recovery_state(ball_state)
    end

    gamecontext.stats = table.deepcopy(save.stats)
end

return M