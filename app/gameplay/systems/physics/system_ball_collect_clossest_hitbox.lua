local gamecontext = require("app.gameplay.gamecontext")
local service_game_grid = require("app.gameplay.systems.service_game_grid")

---@class SystemBallCollectClossestHitbox
local System = class("SystemBallCollectClossestHitbox")

function System:awake()
    self.balls = gamecontext.balls
    self.collisions = gamecontext.collisions
end

function System:update()
    for _, ball in ipairs(self.balls) do
        local collision_index =
            service_game_grid.get_closest_obstacle_flat_index(
                ball:get_pos()
            )

        ball.hitbox = self.collisions[collision_index]
    end
end

return System
