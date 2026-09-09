local M = {}

function M.get_node_id(level, index)
    return level * (level + 1) / 2 + index
end

function M.assert_integer(value, name, minimum)
    assert(
        type(value) == "number"
            and value == math.floor(value)
            and (minimum == nil or value >= minimum),
        string.format(
            "%s must be an integer%s",
            name,
            minimum and (" >= " .. minimum) or ""
        )
    )
end

function M.assert_positive_number(value, name)
    assert(
        type(value) == "number" and value > 0,
        name .. " must be greater than zero"
    )
end

return M