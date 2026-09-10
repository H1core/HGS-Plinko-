local __t = {}
---@class GameContext
---@field gui_sc table
---@field go_sc table
---@field dirty bool
---@field clear function
---@field frame userdata
---@field balls GoBall[]
---@field debugging bool
---@field spawn_position vector3
---@field stats {score: integer, buckets_reaches: integer[], total_reaches: integer}
---@field requested_shoots integer
---@field set_context_table fun(t: table)
local M = setmetatable({}, {
    __index = function(t, k)
        local v = rawget(t, k)
        if v ~= nil then
            return v
        end
        return __t[k]
    end,
    __newindex = function(_, k, v)
        __t[k] = v
    end
})

rawset(M, "set_context_table", function(t)
    __t = t
end)

rawset(M, "clear", function()
    __t = {}
end)
---@return GameContext
return M
