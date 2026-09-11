local function _deepcopy(original, seen)
    if type(original) ~= 'table' then 
        return original 
    end

    seen = seen or {}

    if seen[original] then
        return seen[original]
    end

    local _clone = {}
    seen[original] = _clone

    for original_key, original_value in next, original do
        _clone[_deepcopy(original_key, seen)] = _deepcopy(original_value, seen)
    end

    setmetatable(_clone, _deepcopy(getmetatable(original), seen))

    return _clone
end

local function get(a, ...)
        if type(a) == 'table' then
            local res = a
            local keys = { ... }
            for n, v in ipairs(keys) do
                if type(res) == 'table' then
                    res = res[v]
                else
                    return nil
                end
            end 
            return res
        end
    end

local function _find(a, val)
    for key, value in pairs(a) do
        if (value == val) then
            return key
        end
    end
    return nil
end
local __lua_table_concat = table.concat
local __lua_table_sort = table.sort
local __lua_next = next

---@type fun(nseq?: integer): table
local __lua_table_new = (function()
    -- https://luajit.org/extensions.html
    -- https://www.lua.org/manual/5.5/manual.html#pdf-table.create
    -- https://create.roblox.com/docs/reference/engine/libraries/table#create
    -- https://forum.defold.com/t/solved-is-luajit-table-new-function-available-in-defold/78623

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_new = table and table.new
        if table_new then return function(nseq) return table_new(nseq or 0, 0) end end
    end

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_create = table and table.create
        if table_create then return function(nseq) return table_create(nseq or 0) end end
    end

    do
        local table_new_loader = package and package.preload and package.preload['table.new']
        local table_new = table_new_loader and table_new_loader()
        if table_new then return function(nseq) return table_new(nseq or 0, 0) end end
    end

    ---@return table
    return function() return {} end
end)()

---@type fun(tab: table, no_clear_array_part?: boolean, no_clear_hash_part?: boolean)
local __lua_table_clear = (function()
    -- https://luajit.org/extensions.html
    -- https://create.roblox.com/docs/reference/engine/libraries/table#clear
    -- https://forum.defold.com/t/solved-is-luajit-table-new-function-available-in-defold/78623

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_clear = table and table.clear
        if table_clear then return table_clear end
    end

    do
        local table_clear_loader = package and package.preload and package.preload['table.clear']
        local table_clear = table_clear_loader and table_clear_loader()
        if table_clear then return table_clear end
    end

    ---@param tab table
    ---@param no_clear_array_part? boolean
    ---@param no_clear_hash_part? boolean
    return function(tab, no_clear_array_part, no_clear_hash_part)
        if not no_clear_array_part then
            for i = 1, #tab do tab[i] = nil end
        end

        if not no_clear_hash_part then
            for k in __lua_next, tab do tab[k] = nil end
        end
    end
end)()

---@type fun(a1: table, f: integer, e: integer, t: integer, a2?: table): table
local __lua_table_move = (function()
    -- https://luajit.org/extensions.html
    -- https://www.lua.org/manual/5.3/manual.html#pdf-table.move
    -- https://create.roblox.com/docs/reference/engine/libraries/table#move
    -- https://forum.defold.com/t/solved-is-luajit-table-new-function-available-in-defold/78623
    -- https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lib_table.c#L132

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_move = table and table.move
        if table_move then return table_move end
    end

    do
        local table_move_loader = package and package.preload and package.preload['table.move']
        local table_move = table_move_loader and table_move_loader()
        if table_move then return table_move end
    end

    ---@type fun(a1: table, f: integer, e: integer, t: integer, a2?: table): table
    return function(a1, f, e, t, a2)
        if a2 == nil then
            a2 = a1
        end

        if e < f then
            return a2
        end

        local d = t - f

        if t > e or t <= f or a2 ~= a1 then
            for i = f, e do
                a2[i + d] = a1[i]
            end
        else
            for i = e, f, -1 do
                a2[i + d] = a1[i]
            end
        end

        return a2
    end
end)()

---@type fun(lst: table, i: integer, j: integer): ...
local __lua_table_unpack = (function()
    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_unpack = unpack
        if table_unpack then return table_unpack end
    end

    do
        ---@diagnostic disable-next-line: deprecated, undefined-field
        local table_unpack = table and table.unpack
        if table_unpack then return table_unpack end
    end
end)()


---@param table table
---@param item any
---@return boolean
_G.table.has = function (table, item)
    for k, v in pairs(table) do
        if(v == item) then
            return true
        end
    end

    return false
end


---@param t table
---@return table cloned_table @Returns cloned table
_G.table.clone = function (t)
    local clone = {}
    for k , v in pairs(t) do
        clone[k] = v
    end 
    return clone
end

---@param a table
---@param b table
_G.table.extend = function (a, b)
    for _ , val in ipairs(b) do
        table.insert(a, val)
    end
    return a
end
---@param a table
---@param b table
_G.table.merge = function (a,b)
    for key , val in pairs(b) do
        a[key] = val
    end
    return a 
end


---@param original table
---@return table clone absolute copy of table
_G.table.deepcopy = function (original)
    return _deepcopy(original)
end

_G.table.get = function(a, ...)
    if type(a) == 'table' then
        local res = a
        local keys = { ... }
        for n, v in ipairs(keys) do
            if type(res) == 'table' then
                res = res[v]
            else
                return nil
            end
        end 
        return res
    end
end

_G.table.find = function(a, val)
    return _find(a, val)
end

_G.table.remove_element = function (list, element)
    local index = _find(list, element)
    table.remove(list, index)
end

_G.table.clear = __lua_table_clear
_G.table.unpack =__lua_table_unpack
_G.table.move = __lua_table_move

