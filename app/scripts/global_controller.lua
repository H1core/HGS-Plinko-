local M = {}

local controllers = {}

function M.add_controller(instance)
    table.insert(controllers, instance)
end

function M.update(dt)
    for _ , controller in ipairs(controllers) do
        controller.update(dt)
    end
end

return M