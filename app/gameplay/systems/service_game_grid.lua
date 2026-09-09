local helper = require("app.gameplay.helper")

local M = {}

local _config = nil
local _row_count = 0
local _left_x = 0
local _top_obstacle_y = 0

local BUCKET_WIDTH = 70
local BUCKET_HEIGHT = 145
local ROW_HEIGHT = 50

function M.build(count)
    _config = {
        COUNT = count,
        BUCKET_WIDTH = BUCKET_WIDTH,
        ROW_HEIGHT = ROW_HEIGHT,
        BUCKET_HEIGHT = BUCKET_HEIGHT,
        CENTER_X = 0,
        BOTTOM_Y = -250,
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

return M
