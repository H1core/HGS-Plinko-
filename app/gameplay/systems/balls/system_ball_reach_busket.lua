local gamecontext = require("app.gameplay.gamecontext")

---@class SystemBallReachBusket
local System = class("SystemBallReachBusket")

local function remove_ball(balls, ball)
    for index = #balls, 1, -1 do
        if balls[index] == ball then
            table.remove(balls, index)
            return true
        end
    end

    return false
end

function System:awake()
    self.balls = gamecontext.balls
    self.buckets = gamecontext.buckets
end

function System:on_bucket_reach(event)
    local bucket = self.buckets[event.basket_index + 1]

    if bucket then
        bucket:animate_catch()
    end

    if remove_ball(self.balls, event.ball) then
        go.delete(event.ball.go_url)
    end
end

return System
