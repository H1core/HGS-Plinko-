---@class GamePipeline
local GamePipeline = {}
GamePipeline.__index = GamePipeline

local RESERVED = { add = true, clear = true, lock = true, unlock = true, is_locked = true }

function GamePipeline.new(options)
    assert(options and options.methods, "GameExecutor: methods list is required")

    local lockable = {}
    for _, name in ipairs(options.lockable or {}) do
        lockable[name] = true
    end

    local executor = setmetatable({
        _handlers = {},
        _locked   = false,
        _lockable = lockable,
        _methods  = options.methods,
    }, GamePipeline)

    for _, name in ipairs(options.methods) do
        assert(not RESERVED[name], "GameExecutor: '" .. name .. "' is reserved")
        executor._handlers[name] = {}
        local is_lockable = lockable[name]
        executor[name] = function(exec, ...)
            if exec._locked and is_lockable then return end
            for _, handler in ipairs(exec._handlers[name]) do
                handler(...)
            end
        end
    end

    return executor
end

function GamePipeline:add(system)
    for _, name in ipairs(self._methods) do
        local fn = system[name]
        if type(fn) == "function" then
            table.insert(self._handlers[name], function(...)
                fn(system, ...) 
            end)
        end
    end
end

function GamePipeline:lock()   self._locked = true  end
function GamePipeline:unlock() self._locked = false end

function GamePipeline:is_locked()
    return self._locked
end

function GamePipeline:clear()
    for _, name in ipairs(self._methods) do
        self._handlers[name] = {}
    end
    self._locked = false
end

return GamePipeline