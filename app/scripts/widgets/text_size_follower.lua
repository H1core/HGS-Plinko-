local component = require("druid.component")
---@class druid.instance
---@field new_text_size_follower fun(self: druid.instance, text: druid.text): component_text_size_follower

---@class component_text_size_follower: druid.component
---@field followers userdata[]
local M = component.create("text_size_follower")

---@param text druid.text
---@return component_text_size_follower
function M:init(text)
    self.text = text
    self.axis = vmath.vector3(1,0,0)
    self.bias = vmath.vector3(0,0,0)
    self.followers = {}
    self.text.on_set_text:subscribe(self.update_view, self)

    return self
end

---@param bias vector3
---@return component_text_size_follower
function M:set_size_bias(bias)
    self.bias = bias
    return self
end

---@return component_text_size_follower
---@param axis vector3
function M:set_text_size_axis(axis)
    self.axis = axis
    return self

end

---@return component_text_size_follower
function M:use_scaled_size_set()
    self.scaled_size_set = true
    return self
end

---@return component_text_size_follower
---@param node userdata
function M:add_follower(node)
    table.insert(self.followers, node)
    return self

end

function M:scaled_view_update()
    local size = self:follower_size()
    for _ , node in ipairs(self.followers) do
        local scale = gui.get_scale(node)
        local fsize = gui.get_size(node)
        fsize.x = (size.x ~= 0 and size.x / scale.x or fsize.x)
        fsize.y = (size.y ~= 0 and size.y / scale.y or fsize.y)
        gui.set_size(node, fsize)
    end

    return self
end

function M:update_view()
    if(self.scaled_size_set) then
        self:scaled_view_update()
        return
    end
    local size = self:follower_size()

    for _ , node in ipairs(self.followers) do
        local fsize = gui.get_size(node)
        fsize.x = (size.x ~= 0 and size.x or fsize.x)
        fsize.y = (size.y ~= 0 and size.y or fsize.y)
        gui.set_size(node, fsize)
    end

    return self
end

function M:follower_size()
    local width, height = self.text:get_text_size()
    local size = vmath.mul_per_elem(vmath.vector3(width, height, 0), self.axis) + self.bias
    return size
end


return M