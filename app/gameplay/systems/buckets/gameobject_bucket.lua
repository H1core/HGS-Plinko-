local ANIM_BIAS_V = vmath.vector3(0,-15,0)

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
