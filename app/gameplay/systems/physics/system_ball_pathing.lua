local gamecontext = require("app.gameplay.gamecontext")
local service_game_grid = require("app.gameplay.systems.service_game_grid")

local GRAVITY = GAMECONSTANT.GRAVITY

local BOUNCE_VELOCITY_MIN = 105
local BOUNCE_VELOCITY_MAX = 130
local IMPACT_VARIATION_MIN = 0.88
local IMPACT_VARIATION_MAX = 1.12
local MIN_BOUNCE_HEIGHT = 9
local WEAK_BOUNCE_VELOCITY_MIN = 80
local WEAK_BOUNCE_VELOCITY_MAX = 95
local STAY_BOUNCE_VELOCITY_MIN = 135
local STAY_BOUNCE_VELOCITY_MAX = 160

local MAX_CORRECTION_ACCELERATION = 90
local CORRECTION_FLIGHT_PART = 0.5
local CORRECTION_STOP_DISTANCE = 32
local MAX_HORIZONTAL_SPEED = 220

local COLLISION_EPSILON = 0.25
local POSITION_MATCH_EPSILON = 0.01
local UNEXPECTED_RESTITUTION = 0.55
local BASKET_CAPTURE_Y = 12
local BASKET_CAPTURE_X = 24

---@class SystemBallPathing
local System = class("SystemBallPathing")

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function positions_match(first, second)
    if not first or not second then
        return false
    end

    local dx = first.x - second.x
    local dy = first.y - second.y
    return dx * dx + dy * dy <= POSITION_MATCH_EPSILON
end

local function random_between(ball, minimum, maximum)
    local random_function = ball.random_function
    local value = random_function and random_function() or math.random()
    return minimum + (maximum - minimum) * value
end

local function new_state()
    return {
        route_started = false,
        route_finished = false,
        target = nil,
        pending_target = nil,
        maneuver_position = nil,
        active_collision = nil,
        active_collision_seen = false,
        processed_this_frame = false,
    }
end

local function get_state(self, ball)
    if not self.ball_states then
        self.ball_states = setmetatable({}, { __mode = "k" })
    end

    local state = self.ball_states[ball]

    if not state then
        state = new_state()
        self.ball_states[ball] = state
    end

    return state
end

local function resolve_overlap(ball, collision)
    local ball_position = ball:get_pos()
    local obstacle_position = collision:get_position()
    local dx = ball_position.x - obstacle_position.x
    local dy = ball_position.y - obstacle_position.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local normal_x
    local normal_y

    if distance > 0 then
        normal_x = dx / distance
        normal_y = dy / distance
    else
        normal_x = 0
        normal_y = 1
        distance = 0
    end

    local minimum_distance = ball.collision.radius
        + collision.radius
        + COLLISION_EPSILON
    local penetration = minimum_distance - distance

    if penetration > 0 then
        ball:set_pos(vmath.vector3(
            ball_position.x + normal_x * penetration,
            ball_position.y + normal_y * penetration,
            ball_position.z
        ))
    end

    return normal_x, normal_y
end

local function register_hit(collision)
    table.insert(gamecontext.hit_positions, collision:get_position())
end

local function next_route_target(ball)
    local path = ball.path

    if not path or #path == 0 then
        return nil
    end

    local path_index = ball.path_it or 1
    local next_node = path[path_index + 1]

    if next_node then
        ball.path_it = path_index + 1

        if next_node.type == "basket" then
            local grid_basket_index = next_node.index - 1

            return {
                position = service_game_grid.get_bucket_pos(
                    grid_basket_index
                ),
                basket_index = grid_basket_index,
                direction = next_node.direction,
                bounce_type = "direct",
                is_basket = true,
            }
        end

        return {
            position = service_game_grid.get_obstacle_pos(
                next_node.level,
                next_node.index - 1
            ),
            direction = next_node.direction,
            bounce_type = next_node.bounce_type or "direct",
            is_basket = false,
        }
    end

    local basket_node = path[#path]
    local grid_basket_index = basket_node.index - 1

    return {
        position = service_game_grid.get_bucket_pos(grid_basket_index),
        basket_index = grid_basket_index,
        direction = nil,
        bounce_type = "direct",
        is_basket = true,
    }
end

local function target_contact_position(ball, target, obstacle_radius)
    if target.is_basket then
        return vmath.vector3(
            target.position.x,
            target.position.y + BASKET_CAPTURE_Y,
            target.position.z
        )
    end

    return vmath.vector3(
        target.position.x,
        target.position.y + obstacle_radius + ball.collision.radius,
        target.position.z
    )
end

local function ballistic_flight_time(dy, velocity_y, gravity)
    local discriminant = velocity_y * velocity_y - 2 * gravity * dy

    if discriminant < 0 then
        discriminant = 0
    end

    return (velocity_y + math.sqrt(discriminant)) / gravity
end

local function launch_to_target(ball, target, obstacle_radius)
    local position = ball:get_pos()
    local contact = target_contact_position(ball, target, obstacle_radius)
    local dx = contact.x - position.x
    local dy = contact.y - position.y
    local gravity = GRAVITY * (ball.gravity_scale or 1)
    local minimum_velocity = random_between(
        ball,
        BOUNCE_VELOCITY_MIN,
        BOUNCE_VELOCITY_MAX
    ) * (ball.bounce_scale or 1)
    -- Return impact energy according to this ball's elasticity. The bounded
    -- height prevents a hard first impact from sending it into upper rows.
    local rebound_velocity = math.max(0, -ball.velocity.y)
        * (ball.restitution or 0.68)
        * random_between(ball, IMPACT_VARIATION_MIN, IMPACT_VARIATION_MAX)
    local velocity_y = clamp(
        math.max(minimum_velocity, rebound_velocity),
        math.sqrt(2 * gravity * MIN_BOUNCE_HEIGHT),
        math.sqrt(2 * gravity * (ball.max_bounce_height or 20))
    )
    local flight_time = ballistic_flight_time(
        dy,
        velocity_y,
        gravity
    )

    flight_time = math.max(flight_time, 0.05)

    local velocity_x = clamp(
        dx / flight_time,
        -MAX_HORIZONTAL_SPEED,
        MAX_HORIZONTAL_SPEED
    )

    ball.velocity = vmath.vector3(velocity_x, velocity_y, 0)

    target.contact_position = contact
    target.flight_time = flight_time
    target.elapsed = 0

    if velocity_x > 0 then
        target.travel_direction = 1
    elseif velocity_x < 0 then
        target.travel_direction = -1
    else
        target.travel_direction = 0
    end
end

local function begin_local_bounce(ball, state, collision, target, kind)
    state.pending_target = target
    state.target = nil
    state.maneuver_position = collision:get_position()

    local velocity_y

    if kind == "stay" then
        velocity_y = random_between(
            ball,
            STAY_BOUNCE_VELOCITY_MIN,
            STAY_BOUNCE_VELOCITY_MAX
        ) * (ball.stay_bounce_scale or 1)
    else
        velocity_y = random_between(
            ball,
            WEAK_BOUNCE_VELOCITY_MIN,
            WEAK_BOUNCE_VELOCITY_MAX
        ) * (ball.weak_bounce_scale or 1)
    end

    ball.velocity = vmath.vector3(0, velocity_y, 0)
end

local function continue_route(ball, state, collision)
    local target = next_route_target(ball)

    if not target then
        state.route_finished = true
        return
    end

    if not target.is_basket
        and (target.bounce_type == "bounce"
            or target.bounce_type == "stay")
    then
        begin_local_bounce(
            ball,
            state,
            collision,
            target,
            target.bounce_type
        )
    else
        state.target = target
        launch_to_target(ball, target, collision.radius)
    end
end

local function finish_local_bounce(ball, state, collision)
    local target = state.pending_target

    state.pending_target = nil
    state.maneuver_position = nil
    state.target = target

    if target then
        launch_to_target(ball, target, collision.radius)
    end
end

local function bounce_from_unexpected_obstacle(
    ball,
    state,
    collision,
    normal_x,
    normal_y
)
    local target = state.target

    if target then
        launch_to_target(ball, target, collision.radius)
        return
    end

    local normal_velocity = ball.velocity.x * normal_x
        + ball.velocity.y * normal_y

    if normal_velocity < 0 then
        local reflection = (1 + UNEXPECTED_RESTITUTION)
            * normal_velocity
        ball.velocity = vmath.vector3(
            ball.velocity.x - reflection * normal_x,
            ball.velocity.y - reflection * normal_y,
            0
        )
    end
end

local function handle_collision(ball, state, collision)
    local obstacle_position = collision:get_position()
    local normal_x, normal_y = resolve_overlap(ball, collision)

    register_hit(collision)

    if not state.route_started then
        state.route_started = true
        continue_route(ball, state, collision)
        return
    end

    if state.maneuver_position
        and positions_match(obstacle_position, state.maneuver_position)
    then
        finish_local_bounce(ball, state, collision)
        return
    end

    if state.target
        and not state.target.is_basket
        and positions_match(obstacle_position, state.target.position)
    then
        state.target = nil
        continue_route(ball, state, collision)
        return
    end

    bounce_from_unexpected_obstacle(
        ball,
        state,
        collision,
        normal_x,
        normal_y
    )
end

local function update_weak_correction(ball, state, dt)
    local target = state.target

    if not target or not target.contact_position then
        return
    end

    local position = ball:get_pos()
    local dx = target.contact_position.x - position.x
    local dy = target.contact_position.y - position.y
    local distance = math.sqrt(dx * dx + dy * dy)

    target.elapsed = target.elapsed + dt

    if target.elapsed >= target.flight_time * CORRECTION_FLIGHT_PART
        or distance <= CORRECTION_STOP_DISTANCE
        or target.travel_direction == 0
    then
        return
    end

    local remaining_time = math.max(
        target.flight_time - target.elapsed,
        0.05
    )
    local desired_velocity_x = dx / remaining_time
    local maximum_change = MAX_CORRECTION_ACCELERATION
        * (ball.correction_scale or 1)
        * dt
    local velocity_x = ball.velocity.x + clamp(
        desired_velocity_x - ball.velocity.x,
        -maximum_change,
        maximum_change
    )

    if velocity_x * target.travel_direction < 0 then
        velocity_x = 0
    end

    ball.velocity = vmath.vector3(
        clamp(
            velocity_x,
            -MAX_HORIZONTAL_SPEED,
            MAX_HORIZONTAL_SPEED
        ),
        ball.velocity.y,
        0
    )
end

local function update_basket_capture(ball, state)
    local target = state.target

    if not target or not target.is_basket then
        return
    end

    local position = ball:get_pos()

    if position.y <= target.position.y + BASKET_CAPTURE_Y
        and math.abs(position.x - target.position.x) <= BASKET_CAPTURE_X
    then
        state.route_finished = true
        state.target = nil
        table.insert(gamecontext.ball_reach_busket_events, {
            ball = ball,
            basket_index = target.basket_index,
        })
    end
end

function System:initialize()
    self.ball_states = setmetatable({}, { __mode = "k" })
end

function System:awake()
    self.ball_states = setmetatable({}, { __mode = "k" })
    self.balls = gamecontext.balls
end

function System:update(dt)
    for _, ball in ipairs(self.balls) do
        local state = get_state(self, ball)
        state.active_collision_seen = false
        state.processed_this_frame = false
    end

    for _, ball in ipairs(self.balls) do
        local state = get_state(self, ball)
        local collision = ball.hitbox

        if collision and collision:is_collided(ball.collision) then
            if state.active_collision == collision then
                state.active_collision_seen = true
            elseif not state.processed_this_frame
                and not state.route_finished
            then
                handle_collision(ball, state, collision)
                state.active_collision = collision
                state.active_collision_seen = true
                state.processed_this_frame = true
            end
        end
    end

    for _, ball in ipairs(self.balls) do
        local state = get_state(self, ball)

        if state.active_collision
            and not state.active_collision_seen
        then
            state.active_collision = nil
        end

        if not state.route_finished then
            update_weak_correction(ball, state, dt)
            update_basket_capture(ball, state)
        end
    end
end

return System
