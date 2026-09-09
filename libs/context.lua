local M = {}

---@return function
function M.bind_context(func, func_self, ctx)
    local old_context = ctx or event_context_manager.get()
    return function(...)
        local current_context = event_context_manager.get()
        event_context_manager.set(old_context)
        local res
        if func_self then
            res = {func(func_self, ...)}
        else
            res = {func(...)}
        end
        event_context_manager.set(current_context)
        return unpack(res)
    end
end

return M