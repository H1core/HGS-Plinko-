local circle_collision = require("app.gameplay.systems.physics.collision_circle")
local grid = require("app.gameplay.systems.map.service_game_grid")

---@class GoBall
---@field collision Collision   
---@field seed any
---@field velocity vector3
---@field hitbox Collision|nil Closest obstacle hitbox selected in O(1).
---@field gravity_scale number
---@field bounce_scale number
---@field restitution number Fraction of impact speed returned by an ordinary bounce.
---@field max_bounce_height number Maximum rise above the contact point.
---@field weak_bounce_scale number
---@field stay_bounce_scale number
---@field correction_scale number
---@field pathing_state table Runtime route state owned by this ball.
---@field route_targets table Pre-generated targets and bounce parameters.
local M = {}
M.__index = M

local function random_between(random_function, minimum, maximum)
    local value = random_function and random_function() or math.random()
    return minimum + (maximum - minimum) * value
end

function M.new(url, path, seed, random_function)
    local initial_velocity_x = random_between(random_function, -8, 8)
    local initial_velocity_y = -random_between(random_function, 80, 135)

    local ball = setmetatable({
        seed = seed,
        velocity = vmath.vector3(
            initial_velocity_x,
            initial_velocity_y,
            0
        ),
        gravity_scale = random_between(random_function, 0.88, 1.12),
        bounce_scale = random_between(random_function, 0.88, 1.14),
        restitution = random_between(random_function, 0.55, 0.82),
        max_bounce_height = random_between(random_function, 16, 24),
        weak_bounce_scale = random_between(random_function, 0.9, 1.12),
        stay_bounce_scale = random_between(random_function, 0.9, 1.12),
        correction_scale = random_between(random_function, 0.8, 1.2),
        pathing_state = {
            route_started = false,
            route_finished = false,
            active_collision_seen = false,
            processed_this_frame = false,
        },
        route_targets = {},
        hitbox = nil,
        path_it = 1,
        path = path,
        go_url = url,
        collision = circle_collision.new(go.get_position(url), 10)
    }, M)

    for i = 2, #path do
        local node = path[i]
        local is_basket = node.type == "basket"
        ball.route_targets[i] = {
            position = is_basket and grid.get_bucket_pos(node.index - 1)
                or grid.get_obstacle_pos(node.level, node.index - 1),
            basket_index = is_basket and node.index - 1 or nil,
            direction = node.direction,
            bounce_type = is_basket and "direct" or (node.bounce_type or "direct"),
            is_basket = is_basket,
            minimum_velocity = random_between(random_function, 105, 130) * ball.bounce_scale,
            impact_variation = random_between(random_function, 0.88, 1.12),
            stay_velocity = random_between(random_function, 135, 160) * ball.stay_bounce_scale,
            weak_velocity = random_between(random_function, 80, 95) * ball.weak_bounce_scale,
        }
    end
    return ball
end

function M:get_pos()
    return go.get_position(self.go_url)
end

function M:set_pos(pos)
    go.set_position(pos,self.go_url)
    self.collision:set_position(pos)
end

function M:save_state()
    return table.deepcopy({
        seed = self.seed,
        position = self:get_pos(),
        velocity = self.velocity,
        pathing_state = self.pathing_state,
        path_it = self.path_it
    })
end

function M:recovery_state(state)
    local _temp = table.deepcopy(state)
    self.velocity = _temp.velocity
    self.path_it = _temp.path_it
    self.pathing_state = _temp.pathing_state
    self:set_pos(_temp.position)
end

return M

    
