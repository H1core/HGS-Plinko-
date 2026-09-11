local M = {}
local Consumable = require("app.scripts.consumables.consumable")
local default_config = require("app.scripts.consumables.config_consumables")
local time_provider = require("app.scripts.provider_time_local")
local consumables = {}

local function get_definitions(cfg)
    if type(cfg) ~= "table" then
        return {}
    end
    if type(cfg.consumables) == "table" then
        return cfg.consumables
    end
    if type(cfg.items) == "table" then
        return cfg.items
    end
    return cfg
end

function M.init()
    consumables = {}
    local now = time_provider.now()
    for key, consumable_cfg in pairs(get_definitions(default_config)) do
        consumables[key] = Consumable.new(key, consumable_cfg)
        consumables[key]:init(now)
    end

    return consumables
end

---@return Consumable
function M.get(key)
    return consumables[key]
end

function M.update()
    now = time_provider.now()
    local recovered = {}
    for key, consumable in pairs(consumables) do
        recovered[key] = consumable:cooldown(now)
    end
    return recovered
end

function M.consume(key, count, now)
    local consumable = consumables[key]
    if not consumable then return false end
    return consumable:consume(count, now)
end

function M.add(key, count, now)
    local consumable = consumables[key]
    if not consumable then return 0 end
    return consumable:add(count, now)
end

return M
