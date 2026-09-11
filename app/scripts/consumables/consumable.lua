local storage = require("app.scripts.storage")
local event = require("event.event")
local time_provider = require("app.scripts.provider_time_local")
---@class Consumable
---@field event_changed event
---@field cfg table
---@field key string
local M = {}
M.__index = M

function M.new(key, cfg)
    return setmetatable({
        key = key,
        cfg = cfg,
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
        self.state.c = math.max(0, (self.state.c or self.state.initial))
        self.state.c = math.min(self.state.c, self.cfg.max)
        self.state.last_update = self.state.last_update or now
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

function M:add_unsafe(count)
    self.state.c = self.state.c + count
    self.event_changed:trigger(self.state.c)
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
