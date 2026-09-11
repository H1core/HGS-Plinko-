local collision_shape = require("app.gameplay.systems.physics.collision")

local M = {}
M.__index = M

function M.new(position, radius)
    return setmetatable({
        shape_type = collision_shape.TYPE_CIRCLE,
        position = position,
        radius = radius,
    }, M)
end

function M:set_position(position)
    self.position = position
end

function M:get_position()
    return self.position
end

function M:is_collided(other_shape)
    return collision_shape.is_collided(self, other_shape)
end

return M