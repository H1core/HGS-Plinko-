---@class Collision
---@field shape_type string
---@field get_position fun(self) : vector3
---@field set_position fun(self, p: vector3)
---@field is_collided fun(self, other_shape: Collision): bool

local M = {}

M.TYPE_CIRCLE = "circle"
M.TYPE_BOX = "box"

local function is_circle_circle_collided(first, second)
    local dx = first.position.x - second.position.x
    local dy = first.position.y - second.position.y
    local radius = first.radius + second.radius

    return dx * dx + dy * dy <= radius * radius
end

local function is_box_box_collided(first, second)
    local dx = math.abs(first.position.x - second.position.x)
    local dy = math.abs(first.position.y - second.position.y)

    return dx <= first.half_width + second.half_width
        and dy <= first.half_height + second.half_height
end

local function is_circle_box_collided(circle, box)
    local box_left = box.position.x - box.half_width
    local box_right = box.position.x + box.half_width
    local box_bottom = box.position.y - box.half_height
    local box_top = box.position.y + box.half_height

    local closest_x = math.clamp(
        circle.position.x,
        box_left,
        box_right
    )

    local closest_y = math.clamp(
        circle.position.y,
        box_bottom,
        box_top
    )

    local dx = circle.position.x - closest_x
    local dy = circle.position.y - closest_y

    return dx * dx + dy * dy <= circle.radius * circle.radius
end

---@param first Collision
---@param second Collision
function M.is_collided(first, second)
    if first.shape_type == M.TYPE_CIRCLE
        and second.shape_type == M.TYPE_CIRCLE
    then
        return is_circle_circle_collided(first, second)
    end

    if first.shape_type == M.TYPE_BOX
        and second.shape_type == M.TYPE_BOX
    then
        return is_box_box_collided(first, second)
    end

    if first.shape_type == M.TYPE_CIRCLE
        and second.shape_type == M.TYPE_BOX
    then
        return is_circle_box_collided(first, second)
    end

    if first.shape_type == M.TYPE_BOX
        and second.shape_type == M.TYPE_CIRCLE
    then
        return is_circle_box_collided(second, first)
    end
end

return M