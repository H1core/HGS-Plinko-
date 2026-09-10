local service_game_path = require("app.gameplay.systems.service_game_path")
local go_ball = require("app.gameplay.systems.balls.gameobejct_ball")
local gamecontext = require("app.gameplay.gamecontext")


local M = {}
local _it = 0
function M.execute()
    local rnd_inst = xoshiro256.seed(socket.gettime() + _it)
    _it = _it + 1
    local func_rand = function ()
        return xoshiro256.random(rnd_inst)
    end
    local basket = service_game_path.choose_basket(config.buckets.weights, func_rand)
    local path = service_game_path.generate_path(basket, func_rand)

    local url_go = factory.create("/factories#factory_ball", vmath.vector3(0, 300, 0))
    local ball = go_ball.new(url_go, path, func_rand) --[[@as GoBall]]

    table.insert(gamecontext.balls,ball)
end

return M 
