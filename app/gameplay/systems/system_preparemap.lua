local gamecontext = require("app.gameplay.gamecontext")
local service_game_grid = require("app.gameplay.systems.service_game_grid")
local collision_circle = require("app.gameplay.systems.physics.collision_circle")
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

    ---@return userdata
    ---@param pos vector3
    self.create_bucket = function (pos)
        local url_go_bucket = factory.create("/factories#factory_bucket", pos)
        go.set_parent(url_go_bucket, gamecontext.frame)
        table.insert(gamecontext.buckets, gameobject_bucket.new(url_go_bucket))
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

    local n = #config.baskets
    -- N configured outcomes require N baskets and N - 1 peg rows.
    for i = 0, n - 1 do
        self.create_bucket(service_game_grid.get_bucket_pos(i))
    end

    for i = 0, n - 2 do
        for j = 0, i do
            self.create_obstacle(service_game_grid.get_obstacle_pos(i, j))
            
        end
    end
end

return M
