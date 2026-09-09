local circle_collision = require("app.gameplay.systems.physics.collision_circle")

---@class GoBall
---@field collision Collision   
---@field velocity vector3
---@field gravity_scale number
---@field bounce_scale number
---@field weak_bounce_scale number
---@field stay_bounce_scale number
---@field correction_scale number
---@field random_function function|nil
local M = {}
M.__index = M

local function random_between(random_function, minimum, maximum)
    local value = random_function and random_function() or math.random()
    return minimum + (maximum - minimum) * value
end

function M.new(url, path, random_function)
    local initial_velocity_x = random_between(random_function, -8, 8)
    local initial_velocity_y = -random_between(random_function, 80, 135)

    return setmetatable({
        velocity = vmath.vector3(
            initial_velocity_x,
            initial_velocity_y,
            0
        ),
        gravity_scale = random_between(random_function, 0.88, 1.12),
        bounce_scale = random_between(random_function, 0.88, 1.14),
        weak_bounce_scale = random_between(random_function, 0.9, 1.12),
        stay_bounce_scale = random_between(random_function, 0.9, 1.12),
        correction_scale = random_between(random_function, 0.8, 1.2),
        random_function = random_function,
        path_it = 1,
        path = path,
        go_url = url,
        collision = circle_collision.new(vmath.vector3(0), 10)
    }, M)
end

function M:get_pos()
    return go.get_position(self.go_url)
end

function M:set_pos(pos)
    go.set_position(pos,self.go_url)
    self.collision:set_position(pos)
end

return M

    
