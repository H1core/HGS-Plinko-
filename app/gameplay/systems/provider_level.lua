---@alias Level {weights: integer[], values: integer[]}
local storage = require("app.scripts.storage")
local helper = require("app.gameplay.helper")
local M = {}
local _data

function M.init(default_level)
    local _session_data = storage.get("session")
    if(not _session_data) then
        _data = default_level
        return
    end

    if(not _session_data.level) then
        _data = default_level
        return
    end

    _data = _session_data.level
end

---@return Level
function M.get()
    return _data
end

function M.set(lvl)
    _data = lvl
end

function M.hash()
    return helper.level_hash(_data)
end

return M