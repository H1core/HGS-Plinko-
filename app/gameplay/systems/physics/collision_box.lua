local collision_shape = require("app.gameplay.systems.physics.collision")
local M = {}
M.__index = M

function M.new(position, width, height)
    return setmetatable({
        shape_type = collision_shape.TYPE_BOX,
        position = position,
        width = width,
        height = height,
        half_width = width * 0.5,
        half_height = height * 0.5,
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