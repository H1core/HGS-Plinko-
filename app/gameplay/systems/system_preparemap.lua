local gamecontext = require("app.gameplay.gamecontext")
local service_game_grid = require("app.gameplay.systems.service_game_grid")
local collision_circle = require("app.gameplay.systems.physics.collision_circle")
local provider_bucket_color = require("app.gameplay.systems.buckets.provider_bucket_color")
local gameobject_bucket = require("app.gameplay.systems.buckets.gameobject_bucket")

---@class SystemPrepareMap
local M = class("SystemMap")

function M:initialize()
    
end

function M:awake()
    ---@class GameContext
    ---@field buckets GoBucket[]
    ---@field collisions Collision[]

    local collisions = {}
    gamecontext.collisions = collisions
    gamecontext.balls = {}
    gamecontext.buckets = {}

    local top_obstacle = service_game_grid.get_obstacle_pos(0, 0)
    local frame_settings = GAMECONSTANT.GAME_FRAME
    gamecontext.spawn_position = vmath.vector3(
        top_obstacle.x,
        top_obstacle.y + frame_settings.BALL_RADIUS + frame_settings.SPAWN_Y_BIAS,
        top_obstacle.z
    )

    ---@return userdata
    ---@param pos vector3
    self.create_bucket = function (i, pos)
        local url_go_bucket = factory.create("/factories#factory_bucket", pos)
        go.set_parent(url_go_bucket, gamecontext.frame)
        local go_bucket = gameobject_bucket.new(url_go_bucket)
        table.insert(gamecontext.buckets, go_bucket)
        go_bucket:set_color(provider_bucket_color.get(i))
        go_bucket:set_text(config.buckets.values[i + 1])
        return url_go_bucket
    end
    ---@return userdata
    ---@param pos vector3
    self.create_obstacle = function (pos)
        local url_go_obstacle = factory.create("/factories#factory_obstacle", pos)
        go.set_parent(url_go_obstacle, gamecontext.frame)
        table.insert(collisions, collision_circle.new(pos, 10))
        return url_go_obstacle
    end

    local n = #config.buckets.weights

    for i = 0, n - 1 do
        self.create_bucket(i, service_game_grid.get_bucket_pos(i))
    end

    for i = 0, n - 2 do
        for j = 0, i do
            self.create_obstacle(service_game_grid.get_obstacle_pos(i, j))
        end
    end
end

return M
