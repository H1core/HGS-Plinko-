local service_game_path = require("app.gameplay.systems.balls.service_ball_path")
local provider_level = require("app.gameplay.systems.provider_level")
local go_ball = require("app.gameplay.systems.balls.gameobejct_ball")
local gamecontext = require("app.gameplay.gamecontext")

local M = {}

---@return GoBall
function M.execute(seed)
    local rnd_inst = xoshiro256.seed(seed)
    local func_rand = function ()
        return xoshiro256.random(rnd_inst)
    end
    local basket = service_game_path.choose_basket(provider_level.get().weights, func_rand)
    local path = service_game_path.generate_path(basket, func_rand)
    local url_go = factory.create(
        "/factories#factory_ball",
        gamecontext.spawn_position
    )
    local ball = go_ball.new(url_go, path, seed, func_rand) --[[@as GoBall]]
    table.insert(gamecontext.balls, ball)
    return ball
end

return M
