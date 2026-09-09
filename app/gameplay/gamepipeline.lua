local gamecontext = require("app.gameplay.gamecontext")
local pipeline = require("libs.game_pipeline")
local __executor
local M = {}

---@return GamePipeline
function M.get()
    if(not __executor) then
        __executor = pipeline.new({
            methods  = { "awake", "awake_gui", "update","update_gui", "on_dirty","on_dirty_gui", "on_input", "final" },
            lockable = {"update", "on_dirty"}
        })
        __executor:lock()
    end

    return __executor
end

function M.call(method, ...)
    __executor[method](__executor, ...)
end

function M.call_gui(method, ...)
    local old_ctx = event_context_manager.get()
    event_context_manager.set(gamecontext.gui_sc)
    __executor[method](__executor, ...)
    event_context_manager.set(old_ctx)
end


function M.clear()
    __executor = nil
end

return M