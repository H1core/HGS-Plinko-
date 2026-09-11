local gradient = require("libs.gradient")

local M = {}

local _bakedColors = {}
local _gradientInstance

---@param gradient_cfg GradientConfig
function M.build(bucket_count, gradient_cfg)
    _gradientInstance = gradient.new_instance(gradient_cfg)
    local half = (bucket_count - 1) / 2
    for i = 0, bucket_count - 1 do
        local normalized_value = math.abs(half - i) / half
        _bakedColors[i] = _gradientInstance:get(normalized_value)
    end
end

function M.get(bucket_index)
    return _bakedColors[bucket_index]
end

return M