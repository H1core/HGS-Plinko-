local service_game_path = require("app.gameplay.systems.balls.service_ball_path")
local service_game_grid = require("app.gameplay.systems.map.service_game_grid")
local provider_bucket_color = require("app.gameplay.systems.map.provider_bucket_color")
local provider_level = require("app.gameplay.systems.provider_level")
local monarch = require("monarch.monarch")

local M = {}

function M.execute()
    local n = #provider_level.get().weights
    service_game_path.build_graph(n)
    service_game_grid.build(n)
    provider_bucket_color.build(n, config.buckets.gradient)
    monarch.show("gameplay", {clear = true})
end

return M