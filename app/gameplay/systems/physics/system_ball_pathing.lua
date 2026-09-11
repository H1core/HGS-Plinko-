local gamecontext = require("app.gameplay.gamecontext")
local gamepipeline = require("app.gameplay.gamepipeline")
local GRAVITY = GAMECONSTANT.GRAVITY

local MIN_BOUNCE_HEIGHT = 9

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

function System:awake()
    self.balls = gamecontext.balls
end

function System:update(dt)
    for index = #self.balls, 1, -1 do
        local ball = self.balls[index]
        self:handle_collision(ball)

        if ball.pathing_state.route_finished then
            return
        end

        self:update_weak_correction(ball, ball.pathing_state, dt)
        self:update_basket_capture(ball, ball.pathing_state)
    end
end

function System:handle_collision(ball)
    local state = ball.pathing_state
    local collision = ball.hitbox
    state.active_collision_seen = false
    state.processed_this_frame = false

    if collision and collision:is_collided(ball.collision) then
        if self:positions_match(state.active_collision, collision:get_position()) then
            state.active_collision_seen = true
        elseif not state.route_finished then
            self:respond_to_collision(ball, state, collision)
            state.active_collision = vmath.vector3(collision:get_position())
            state.active_collision_seen = true
            state.processed_this_frame = true
        end
    end

    if state.active_collision and not state.active_collision_seen then
        state.active_collision = nil
    end
end

function System:positions_match(first, second)
    if not first or not second then
        return false
    end

    local dx = first.x - second.x
    local dy = first.y - second.y
    return dx * dx + dy * dy <= POSITION_MATCH_EPSILON
end

function System:resolve_overlap(ball, collision)
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

function System:register_hit(collision)
    table.insert(gamecontext.hit_positions, collision:get_position())
end

function System:next_route_target(ball)
    local index = ball.path_it + 1
    local target = ball.route_targets[index]
    if target then ball.path_it = index end
    return target
end

function System:target_contact_position(ball, target, obstacle_radius)
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

function System:ballistic_flight_time(dy, velocity_y, gravity)
    local discriminant = velocity_y * velocity_y - 2 * gravity * dy

    if discriminant < 0 then
        discriminant = 0
    end

    return (velocity_y + math.sqrt(discriminant)) / gravity
end

function System:launch_to_target(ball, target, obstacle_radius)
    local position = ball:get_pos()
    local contact = self:target_contact_position(ball, target, obstacle_radius)
    local dx = contact.x - position.x
    local dy = contact.y - position.y
    local gravity = GRAVITY * (ball.gravity_scale or 1)
    local minimum_velocity = target.minimum_velocity
    local rebound_velocity = math.max(0, -ball.velocity.y)
        * (ball.restitution or 0.68)
        * target.impact_variation

    local velocity_y = math.clamp(
        math.max(minimum_velocity, rebound_velocity),
        math.sqrt(2 * gravity * MIN_BOUNCE_HEIGHT),
        math.sqrt(2 * gravity * (ball.max_bounce_height or 20))
    )
    local flight_time = self:ballistic_flight_time(
        dy,
        velocity_y,
        gravity
    )

    flight_time = math.max(flight_time, 0.05)

    local velocity_x = math.clamp(
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

function System:begin_local_bounce(ball, state, collision, target, kind)
    state.pending_target = target
    state.target = nil
    state.maneuver_position = collision:get_position()

    local velocity_y

    if kind == "stay" then
        velocity_y = target.stay_velocity
    else
        velocity_y = target.weak_velocity
    end

    ball.velocity = vmath.vector3(0, velocity_y, 0)
end

function System:continue_route(ball, state, collision)
    local target = self:next_route_target(ball)

    if not target then
        state.route_finished = true
        return
    end

    if not target.is_basket
        and (target.bounce_type == "bounce"
            or target.bounce_type == "stay")
    then
        self:begin_local_bounce(
            ball,
            state,
            collision,
            target,
            target.bounce_type
        )
    else
        state.target = target
        self:launch_to_target(ball, target, collision.radius)
    end
end

function System:finish_local_bounce(ball, state, collision)
    local target = state.pending_target

    state.pending_target = nil
    state.maneuver_position = nil
    state.target = target

    if target then
        self:launch_to_target(ball, target, collision.radius)
    end
end

function System:bounce_from_unexpected_obstacle(
    ball,
    state,
    collision,
    normal_x,
    normal_y
)
    local target = state.target

    if target then
        self:launch_to_target(ball, target, collision.radius)
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

function System:respond_to_collision(ball, state, collision)
    local obstacle_position = collision:get_position()
    local normal_x, normal_y = self:resolve_overlap(ball, collision)

    self:register_hit(collision)

    if not state.route_started then
        state.route_started = true
        self:continue_route(ball, state, collision)
        return
    end

    if state.maneuver_position
        and self:positions_match(obstacle_position, state.maneuver_position)
    then
        self:finish_local_bounce(ball, state, collision)
        return
    end

    if state.target
        and not state.target.is_basket
        and self:positions_match(obstacle_position, state.target.position)
    then
        state.target = nil
        self:continue_route(ball, state, collision)
        return
    end

    self:bounce_from_unexpected_obstacle(
        ball,
        state,
        collision,
        normal_x,
        normal_y
    )
end

function System:update_weak_correction(ball, state, dt)
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
    local velocity_x = ball.velocity.x + math.clamp(
        desired_velocity_x - ball.velocity.x,
        -maximum_change,
        maximum_change
    )

    if velocity_x * target.travel_direction < 0 then
        velocity_x = 0
    end

    ball.velocity = vmath.vector3(
        math.clamp(
            velocity_x,
            -MAX_HORIZONTAL_SPEED,
            MAX_HORIZONTAL_SPEED
        ),
        ball.velocity.y,
        0
    )
end

function System:update_basket_capture(ball, state)
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
        gamepipeline.call("on_bucket_reach", {
            ball = ball,
            basket_index = target.basket_index,
        })
    end
end

return System
