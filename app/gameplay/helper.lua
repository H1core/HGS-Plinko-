local M = {}

function M.get_node_id(level, index)
    return level * (level + 1) / 2 + index
end

function M.level_hash(level_state)
    local h = 5381
    local function hash_number(n)
        h = (h * 33 + math.floor(n)) % 0x7FFFFFFF
    end

    local function traverse(value)
        if type(value) == "number" then
            hash_number(value)
        elseif type(value) == "table" then
            for _, v in pairs(value) do
                traverse(v)
            end
        end
    end   
    
    traverse(level_state)
    return h
    
end


return M