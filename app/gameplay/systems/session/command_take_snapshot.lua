local gamecontext = require("app.gameplay.gamecontext")
local storage = require("app.scripts.storage")
local M = {}

local _lvl 
function M.init(lvl)
    _lvl = table.deepcopy(lvl)
end

function M.execute()
    local balls_state = {}
    for _ , ball in ipairs(gamecontext.balls) do
        table.insert(balls_state, ball:save_state())
    end
    
    local session_state = {
        stats = table.deepcopy(gamecontext.stats),
        balls = balls_state,
        level = table.deepcopy(_lvl)
    }

    storage.set("session", session_state)
    storage.save()
end

return M