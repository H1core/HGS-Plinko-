local M = {}

---@class MathExtension
local Math = {}

---@generic Number: number
---@param val Number
---@param min Number
---@param max Number
---@return Number
function Math.clamp(val, min , max)
    if(val < min) then
        return min
    end

    if(val > max) then
        return max
    end

    return val
end

function Math.clamp01(val)
    return Math.clamp(val, 0, 1)
end

---@param a Position|vector3    
---@param b Position|vector3
function Math.distance(a, b)
    return math.sqrt(
        (a.x - b.x) * (a.x - b.x) 
        + 
        (a.y - b.y) * (a.y - b.y)
    )
end

function Math.sign(n)
    if n > 0 then return 1 elseif n < 0 then return -1 else return 0 end
end

function Math.round(a)
    return math.floor(a + 0.5)
end

function Math.wrap1(x, n)
	return ((x - 1) % n) + 1
end

function Math.screen_to_world_2d(screen_pos, camera_url)
    local proj = camera.get_projection(camera_url)
    local view = camera.get_view(camera_url)
    local w, h = window.get_size() 
    local nx = (2 * screen_pos.x / w) - 1
    local ny = (2 * screen_pos.y / h) - 1
    local inv = vmath.inv(proj * view)
    local nz = -1
    local wx = nx * inv.m00 + ny * inv.m01 + nz * inv.m02 + inv.m03
    local wy = nx * inv.m10 + ny * inv.m11 + nz * inv.m12 + inv.m13
    local wz = nx * inv.m20 + ny * inv.m21 + nz * inv.m22 + inv.m23
    local ww = nx * inv.m30 + ny * inv.m31 + nz * inv.m32 + inv.m33
    return vmath.vector3(wx / ww, wy / ww, wz / ww)
end

function Math.screen_to_world_at_z(screen_pos, camera_url, target_z)
    target_z = target_z or 0

    local proj = camera.get_projection(camera_url)
    local view = camera.get_view(camera_url)
    local w, h = window.get_size()
    local inv = vmath.inv(proj * view)

    local nx = (2 * screen_pos.x / w) - 1
    local ny = (2 * screen_pos.y / h) - 1
    local function unproject(nz)
        local wx = nx * inv.m00 + ny * inv.m01 + nz * inv.m02 + inv.m03
        local wy = nx * inv.m10 + ny * inv.m11 + nz * inv.m12 + inv.m13
        local wz = nx * inv.m20 + ny * inv.m21 + nz * inv.m22 + inv.m23
        local ww = nx * inv.m30 + ny * inv.m31 + nz * inv.m32 + inv.m33
        return vmath.vector3(wx / ww, wy / ww, wz / ww)
    end

    local near = unproject(-1)
    local far  = unproject(1)

    local dz = far.z - near.z
    if math.abs(dz) < 0.0001 then
        return near  
    end
    local t = (target_z - near.z) / dz

    return vmath.vector3(
        near.x + t * (far.x - near.x),
        near.y + t * (far.y - near.y),
        target_z
    )
end

local VECTOR_ONE = vmath.vector3(1,1,1)

---@param v vector3
function Math.invert(v)
    return VECTOR_ONE - v
end

local old_math = _G.math or {}
---@meta MathExtension
_G.math = setmetatable(old_math, {
    __index = Math
})

---@param b vector3
---@return vector3
_G.vmath.abs = function (b)
    local a = vmath.vector3(b)
    if(a.x < 0) then a.x = -a.x end
    if(a.y < 0) then a.y = -a.y end
    if(a.z < 0) then a.z = -a.z end
    return a
end

return M