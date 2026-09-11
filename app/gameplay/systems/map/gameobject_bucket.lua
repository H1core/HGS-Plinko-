local ANIM_BIAS_V = vmath.vector3(0,-15,0)
local color = require("libs.color")
---@class GoBucket
---@field go_url userdata
---@field pos vector3
---@field is_animating bool
local M = {}
M.__index = M

function M.new(url)
    return setmetatable({
        go_url = url,
        pos = go.get_position(url),
    }, M)
end

function M:set_color(col_hex)
    go.set(msg.url(nil, self.go_url, "sprite"), "tint", col_hex)
    local url_label = msg.url(nil, self.go_url, "label")
    local url_shadow = msg.url(nil, self.go_url, "label_shadow")
    local darken_col = color.darken(col_hex, 0.35)
    go.set(url_label, "outline", darken_col)
    go.set(url_shadow, "outline", darken_col)
    go.set(url_shadow, "color", darken_col)
end

function M:set_text(text)
    local url_label = msg.url(nil, self.go_url, "label")
    local url_shadow = msg.url(nil, self.go_url, "label_shadow")
    label.set_text(url_label, text)
    label.set_text(url_shadow, text)
end

function M:animate_catch()
    if(self.is_animating) then
        go.cancel_animations(self.go_url)
        go.set(self.go_url, "scale", vmath.vector3(1))
        go.set(self.go_url, "position.y", self.pos.y)
    end

    self.is_animating = true

    go.animate(self.go_url, "scale", go.PLAYBACK_ONCE_PINGPONG, vmath.vector3(1.05), go.EASING_INOUTCUBIC, 0.25)
    go.animate(
        self.go_url,
        "position.y",
        go.PLAYBACK_ONCE_FORWARD,
        self.pos.y + ANIM_BIAS_V.y,
        go.EASING_OUTBACK,
        0.3,
        0,
        function()
            go.animate(self.go_url, "position.y", go.PLAYBACK_ONCE_FORWARD, self.pos.y, go.EASING_OUTBACK, 0.4, 0, function ()
                self.is_animating = false
                go.set(self.go_url, "scale", vmath.vector3(1))
                go.set(self.go_url, "position.y", self.pos.y)
            end)
           
        end
    )
end

return M
