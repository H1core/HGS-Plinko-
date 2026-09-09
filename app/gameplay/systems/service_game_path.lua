local helper = require "app.gameplay.helper"

local M = {}

local _graph_transitions = {}
local _nodes = {}
local _basket_count = 0
local _depth = 0

-- These actions only decorate a route. The left/right transition is kept, so
-- the selected basket and its configured probability never change.
local STAY_BOUNCE_CHANCE = 0.0
local BOUNCE_CHANCE = 0.15

local function random01(random_function)
    if random_function then
        return random_function()
    end

    return math.random()
end

function M.build_graph(basket_count)
    helper.assert_integer(basket_count, "basket_count", 2)

    _basket_count = basket_count
    _depth = basket_count - 1
    _graph_transitions = {}
    _nodes = {}

    for level = 0, _depth do
        for index = 1, level + 1 do
            local id = helper.get_node_id(level, index)
            local node_type = "route"

            if level == 0 then
                node_type = "top"
            elseif level == _depth then
                node_type = "basket"
            end

            _nodes[id] = {
                id = id,
                level = level,
                index = index,
                type = node_type,
            }

            _graph_transitions[id] = {}

            if level > 0 then
                if index <= level then
                    table.insert(
                        _graph_transitions[id],
                        helper.get_node_id(level - 1, index)
                    )
                end

                if index > 1 then
                    table.insert(
                        _graph_transitions[id],
                        helper.get_node_id(level - 1, index - 1)
                    )
                end
            end
        end
    end
end

local function get_parent_order(node, random_function)
    local parents = _graph_transitions[node.id]
    local result = {}

    for i = 1, #parents do
        result[i] = parents[i]
    end

    if #result == 2 then
        local right_probability = (node.index - 1) / node.level

        if random01(random_function) < right_probability then
            result[1], result[2] = result[2], result[1]
        end
    end

    return result
end

local function find_reverse_path(start_id, random_function)
    local visited = {}
    local path = {}

    local function dfs(node_id)
        if visited[node_id] then
            return false
        end

        visited[node_id] = true
        path[#path + 1] = node_id

        local node = _nodes[node_id]

        if node.level == 0 then
            return true
        end

        local parents = get_parent_order(node, random_function)

        for _, parent_id in ipairs(parents) do
            if dfs(parent_id) then
                return true
            end
        end

        path[#path] = nil
        return false
    end

    if dfs(start_id) then
        return path
    end

    return nil
end

function M.generate_path(basket_index, random_function)
    helper.assert_integer(basket_index, "basket_index", 1)

    local basket_id = helper.get_node_id(_depth, basket_index)
    local reverse_path = find_reverse_path(basket_id, random_function)

    assert(reverse_path, "Path to top was not found")

    local path = {}

    -- DFS строит basket -> top, поэтому разворачиваем в top -> basket.
    for i = #reverse_path, 1, -1 do
        path[#path + 1] = table.deepcopy(_nodes[reverse_path[i]])
    end

    for i = 2, #path do
        local parent = path[i - 1]
        local child = path[i]

        if child.index > parent.index then
            child.direction = 1
            child.direction_name = "right"
        else
            child.direction = -1
            child.direction_name = "left"
        end

        local bounce_roll = random01(random_function)

        if bounce_roll < STAY_BOUNCE_CHANCE then
            child.bounce_type = "stay"
        elseif bounce_roll < STAY_BOUNCE_CHANCE + BOUNCE_CHANCE
        then
            child.bounce_type = "bounce"
        else
            child.bounce_type = "direct"
        end
    end

    return path
end

function M.choose_basket(weights, random_function)
    local total = 0

    for index, weight in ipairs(weights) do
        total = total + weight
    end

    local roll = random01(random_function) * total
    local accumulated = 0

    for index, weight in ipairs(weights) do
        accumulated = accumulated + weight

        if roll < accumulated then
            return index
        end
    end

    return _basket_count
end

function M.generate_weighted_path(weights, random_function)
    local basket_index = M.choose_basket(weights, random_function)
    local path = M.generate_path(basket_index, random_function)

    return basket_index, path
end

function M.get_transitions()
    return _graph_transitions
end

return M
