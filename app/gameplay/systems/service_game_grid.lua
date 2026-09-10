local helper = require("app.gameplay.helper")

local M = {}

local _config = nil
local _row_count = 0
local _left_x = 0
local _top_obstacle_y = 0

local BUCKET_WIDTH = 52.5
local BUCKET_HEIGHT = 120
local ROW_HEIGHT = 70

function M.build(count)
    _config = {
        COUNT = count,
        BUCKET_WIDTH = BUCKET_WIDTH,
        ROW_HEIGHT = ROW_HEIGHT,
        BUCKET_HEIGHT = BUCKET_HEIGHT,
        CENTER_X = 0,
        BOTTOM_Y = 0,
        Z = 0,
    }

    _row_count = _config.COUNT - 1

    local grid_width = _config.BUCKET_WIDTH * _config.COUNT

    _left_x = _config.CENTER_X - grid_width * 0.5

    local bottom_obstacle_y =
        _config.BOTTOM_Y + _config.BUCKET_HEIGHT

    _top_obstacle_y =
        bottom_obstacle_y
        + (_row_count - 1) * _config.ROW_HEIGHT
end

function M.get_bucket_pos(index)
    assert(_config, "Call ServiceGameGrid.build() first")

    local x =
        _left_x
        + (index + 0.5) * _config.BUCKET_WIDTH

    return vmath.vector3(
        x,
        _config.BOTTOM_Y,
        _config.Z
    )
end

function M.get_obstacle_pos(level, index)
    assert(_config, "Call ServiceGameGrid.build() first")

    local x_offset =
        (index) - level * 0.5

    local x =
        _config.CENTER_X
        + x_offset * _config.BUCKET_WIDTH

    local y =
        _top_obstacle_y
        - level * _config.ROW_HEIGHT

    return vmath.vector3(x, y, _config.Z)
end

-- Logical field extents; visual allowances are owned by the framing system.
function M.get_frame_geometry()
    assert(_config, "Call ServiceGameGrid.build() first")
    return {
        left = M.get_bucket_pos(0).x,
        right = M.get_bucket_pos(_config.COUNT - 1).x,
        bottom = _config.BOTTOM_Y,
        top = _top_obstacle_y,
    }
end

function M.get_closest_obstacle_flat_index(position)
    assert(_config, "Call ServiceGameGrid.build() first")

    local max_level = _row_count - 1
    local level = math.floor(
        (_top_obstacle_y - position.y) / _config.ROW_HEIGHT + 0.5
    )
    level = math.clamp(level, 0, max_level)

    local index = math.floor(
        (position.x - _config.CENTER_X) / _config.BUCKET_WIDTH
            + level * 0.5
            + 0.5
    )
    index = math.clamp(index, 0, level)

    return level * (level + 1) / 2 + index + 1
end

return M
