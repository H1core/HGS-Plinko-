local M = {}
local cached_state = {}
local filename = "_mini_storage"

function M.get_file_path(name)
    return sys.get_save_file(sys.get_config_string("project.title", "HGS-Plinko"), name)
end

function M.init(cb_loaded)
    local path = M.get_file_path(filename)
    if path == nil then
        return nil
    end
    
    cached_state = sys.load(path) or {}
    cb_loaded()
end

function M.set(key, v)
    cached_state[key] = v
end

function M.get(key)
    return cached_state[key]
end

function M.save()
    sys.save(M.get_file_path(filename), cached_state)
end

return M
