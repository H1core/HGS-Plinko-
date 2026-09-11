local gamecontext = require("app.gameplay.gamecontext")
local service_game_grid = require("app.gameplay.systems.map.service_game_grid")

---@class SystemBallCollectClossestHitbox
local System = class("SystemBallCollectClossestHitbox")

function System:update()
    for _, ball in ipairs(gamecontext.balls) do
        local collision_index =
            service_game_grid.get_closest_obstacle_flat_index(
                ball:get_pos()
            )

        ball.hitbox = gamecontext.collisions[collision_index]
    end
end

return System
