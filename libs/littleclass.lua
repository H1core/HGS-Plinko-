local LittleClass = setmetatable({}, {
    __call = function(_, name)
        assert(type(name) == "string", "LittleClass: name must be a string")

        local cls = { name = name }

        setmetatable(cls, {
            __call = function(c, ...)
                local instance = setmetatable({ class = c }, { __index = c })

                if c.initialize then
                    instance:initialize(...)
                end

                return instance
            end
        })

        return cls
    end
})

_G.class = LittleClass

return LittleClass