local storage = require("app.scripts.storage")
local event = require("event.event")
local time_provider = require("app.scripts.provider_time_local")
---@class Consumable
---@field event_changed event
---@field cfg table
---@field key string
local M = {}
M.__index = M

local function get_number(value, fallback)
    if type(value) == "number" then
        return value
    end
    return fallback
end

local function normalize_config(cfg)
    cfg = cfg or {}

    local initial = get_number(cfg.initial, get_number(cfg.initial_count, get_number(cfg.count, 0)))
    local max = get_number(cfg.max, get_number(cfg.max_count, get_number(cfg.capacity, initial)))
    local cooldown = get_number(cfg.cooldown, get_number(cfg.cooldown_secs, 0))
    local recovery_amount = get_number(
        cfg.recovery_amount,
        get_number(cfg.restore_amount, get_number(cfg.amount_per_cooldown, 0))
    )

    initial = math.max(0, math.floor(initial))
    max = math.max(initial, math.floor(max))
    cooldown = math.max(0, cooldown)
    recovery_amount = math.max(0, math.floor(recovery_amount))

    return {
        initial = math.min(initial, max),
        max = max,
        cooldown = cooldown,
        recovery_amount = recovery_amount
    }
end

function M.new(key, cfg)
    return setmetatable({
        key = key,
        cfg = normalize_config(cfg),
        event_changed = event.create(),
    }, M)
end

function M:init(now)
    now = now or time_provider.now()
    local saved_state = storage.get(self.key)

    if type(saved_state) ~= "table" then
        self.state = {
            c = self.cfg.initial,
            last_update = now
        }
    else
        self.state = saved_state
        self.state.c = math.max(0, math.floor(get_number(self.state.c, get_number(self.state.count, self.cfg.initial))))
        self.state.c = math.min(self.state.c, self.cfg.max)
        self.state.last_update = get_number(
            self.state.last_update,
            get_number(self.state.updated_at, get_number(self.state.t, now))
        )
    end

    if self.state.c >= self.cfg.max and self.state.last_update ~= now then
        self.state.last_update = now
        self:save()
    end

    self:cooldown(now)
    return self
end

---@param now any
function M:count(now)
    self:cooldown(now)
    return self.state.c
end

function M:add(count, now)
    count = count or 1
    if type(count) ~= "number" or count <= 0 then return 0 end

    now = now or time_provider.now()
    self:cooldown(now)

    local old_count = self.state.c
    self.state.c = math.min(self.cfg.max, old_count + math.floor(count))
    if self.state.c == self.cfg.max then
        self.state.last_update = now
    end

    local added = self.state.c - old_count
    if added > 0 then
        self:save()
        self.event_changed:trigger(self.state.c)
    end
    return added
end

function M:consume(count)
    count = count or 1
    count = math.floor(count)
    if count < 1 then return false end
    now = now or time_provider.now()
    self:cooldown(now)

    if self.state.c < count then return false end

    self.state.c = self.state.c - count
    if self.state.c < self.cfg.max and self.state.last_update == nil then
        self.state.last_update = now
    end
    self:save()
    self.event_changed:trigger(self.state.c)
    return true
end

function M:cooldown(now)
    now = now or time_provider.now()

    if self.state == nil then
        return 0
    end

    if self.state.c >= self.cfg.max then
        return 0
    end

    if self.cfg.cooldown <= 0 or self.cfg.recovery_amount <= 0 then
        return 0
    end

    local last_update = self.state.last_update or now
    local elapsed = now - last_update
    if elapsed <= 0 then
        return 0
    end

    local periods = math.floor(elapsed / self.cfg.cooldown)
    if periods < 1 then
        return 0
    end

    local recovery = math.min(
        periods * self.cfg.recovery_amount,
        self.cfg.max - self.state.c
    )

    if recovery <= 0 then
        return 0
    end

    local old_count = self.state.c
    self.state.c = self.state.c + recovery
    if self.state.c >= self.cfg.max then
        self.state.last_update = now
    else
        self.state.last_update = last_update + periods * self.cfg.cooldown
    end

    self:save()
    self.event_changed:trigger(self.state.c)
    return self.state.c - old_count
end

function M:time_to_recovery(now)
    if self.state == nil or self.state.c >= self.cfg.max then
        return 0
    end
    if self.cfg.cooldown <= 0 or self.cfg.recovery_amount <= 0 then
        return nil
    end

    now = now or time_provider.now()
    local remaining = self.cfg.cooldown - (now - (self.state.last_update or now))
    return math.max(0, remaining)
end

function M:is_limit()
    return self.state.c >= self.cfg.max
end

function M:save()
    storage.set(self.key, self.state)
    storage.save()
end

return M
