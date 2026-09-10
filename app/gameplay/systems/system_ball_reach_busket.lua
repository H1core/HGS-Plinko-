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
    gamecontext.ball_reach_busket_events = {}
    self.events = gamecontext.ball_reach_busket_events
    self.balls = gamecontext.balls
    self.buckets = gamecontext.buckets
end

function System:update()
    for event_index = #self.events, 1, -1 do
        local event = self.events[event_index]
        self.events[event_index] = nil

        local bucket = self.buckets[event.basket_index + 1]

        if bucket then
            bucket:animate_catch()
        end

        if remove_ball(self.balls, event.ball) then
            go.delete(event.ball.go_url)
        end
    end
end

return System
