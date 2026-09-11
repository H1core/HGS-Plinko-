local color = require("libs.color")

---@alias GradientProperty {v: number, c: string}
---@alias GradientConfig GradientProperty[]

---@class GradientMapPoint
---@field value number
---@field color vector4

---@class Gradient
---@field map GradientMapPoint[]
local Gradient = {}
Gradient.__index = Gradient

local M = {}

---@param cfg GradientConfig
---@return Gradient
function M.new_instance(cfg)
    assert(type(cfg) == "table" and #cfg > 0, "Gradient config must contain at least one point")

    local map = {}

    for index, point in ipairs(cfg) do
        local point_color = point.c
        if type(point_color) == "string" then
            point_color = color.hex2vector4(point_color)
        end

        map[index] = {
            value = point.v,
            color = point_color,
        }
    end

    table.sort(map, function(left, right)
        return left.value < right.value
    end)

    return setmetatable({ map = map }, Gradient)
end

---@param normalized_value number 
---@return vector4
function Gradient:get(normalized_value)
    normalized_value = math.clamp01(normalized_value)

    local left_point = self.map[1]
    local right_point = self.map[#self.map]

    if normalized_value <= left_point.value then
        return left_point.color
    end

    if normalized_value >= right_point.value then
        return right_point.color
    end

    for index = 2, #self.map do
        right_point = self.map[index]

        if normalized_value <= right_point.value then
            local divider = right_point.value - left_point.value
            local t = divider == 0
                and 1
                or (normalized_value - left_point.value) / divider

            return vmath.lerp(t, left_point.color, right_point.color)
        end

        left_point = right_point
    end

    return right_point.color
end

return M
