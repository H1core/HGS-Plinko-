local PALETTE_DATA = {}
local COLOR_WHITE = vmath.vector4(1, 1, 1, 1)
local COLOR_X = hash("color.x")
local COLOR_Y = hash("color.y")
local COLOR_Z = hash("color.z")

local M = {}


local vector_one = vmath.vector4(1,1,1,1)
function M.lighten(color, k)
	return color + (vector_one - color) * k
end

---Lerp colors via color HSB values
---@param t number Lerp value. 0 - color1, 1 - color2
---@param color1 vector4 Color 1
---@param color2 vector4 Color 2
---@return vector4 result Color between color1 and color2
function M.lerp(t, color1, color2)
	local h1, s1, v1 = M.rgb2hsb(color1.x, color1.y, color1.z)
	local h2, s2, v2 = M.rgb2hsb(color2.x, color2.y, color2.z)

	local h = h1 + (h2 - h1) * t
	local s = s1 + (s2 - s1) * t
	local v = v1 + (v2 - v1) * t

	local r, g, b, a = M.hsb2rgb(h, s, v)
	a = a or 1
	return vmath.vector4(r, g, b, a)
end



---Convert hex color to rgb values.
---@param hex string Hex color. #00BBAA or 00BBAA or #0BA or 0BA
---@return number, number, number, number?
function M.hex2rgb(hex)
	if not hex or #hex < 3 then
		return 0, 0, 0
	end

	hex = hex:gsub("^#", "")
	if #hex == 3 then
		hex = hex:gsub("(.)", "%1%1")
	end

	return tonumber("0x" .. hex:sub(1,2)) / 255,
		   tonumber("0x" .. hex:sub(3,4)) / 255,
		   tonumber("0x" .. hex:sub(5,6)) / 255,
		   #hex >= 8 and tonumber("0x" .. hex:sub(7, 8)) / 255 or 1
end


---Convert hex color to vector4.
---@param hex string Hex color. #00BBAA or 00BBAA or #0BA or 0BA
---@param alpha number|nil Alpha value. Default is 1
---@return vector4
function M.hex2vector4(hex, alpha)
	local r, g, b, a = M.hex2rgb(hex)
	return vmath.vector4(r, g, b, a or alpha or 1)
end

---Convert hex color to vector4.
---@param hex string Hex color. #00BBAA or 00BBAA or #0BA or 0BA
---@param alpha number|nil Alpha value. Default is 1
---@return vector3|vector4
function M.hex2vector(hex, alpha)
	local r, g, b, a = M.hex2rgb(hex)
	return vmath.vector(r, g, b, a)
end
---@param hex string Hex color. #00BBAA or 00BBAA or #0BA or 0BA
---@param alpha number|nil Alpha value. Default is 1
---@return vector3
function M.hex2vector3(hex, alpha)
	local r, g, b = M.hex2rgb(hex)
	return vmath.vector3(r, g, b)
end


---Convert hsb color to rgb colo
---@param r number Red value
---@param g number Green value
---@param b number Blue value
---@param alpha number|nil Alpha value. Default is 1
function M.rgb2hsb(r, g, b, alpha)
	alpha = alpha or 1
	local min, max = math.min(r, g, b), math.max(r, g, b)
	local delta = max - min
	local h, s, v = 0, max, max

	s = max ~= 0 and delta / max or 0

	if delta ~= 0 then
		if r == max then
			h = (g - b) / delta
		elseif g == max then
			h = 2 + (b - r) / delta
		else
			h = 4 + (r - g) / delta
		end
		h = (h / 6) % 1
	end

	alpha = alpha > 1 and alpha / 100 or alpha

	return h, s, v, alpha
end


---Convert hsb color to rgb color
---@param h number Hue
---@param s number Saturation
---@param v number Value
---@param alpha number|nil Alpha value. Default is 1
function M.hsb2rgb(h, s, v, alpha)
	local r, g, b
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)

	i = i % 6

	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end

	return r, g, b, alpha
end


---Convert rgb color to hex color
---@param red number Red value
---@param green number Green value
---@param blue number Blue value
function M.rgb2hex(red, green, blue)
	local r = string.format("%x", math.floor(red * 255))
	local g = string.format("%x", math.floor(green * 255))
	local b = string.format("%x", math.floor(blue * 255))
	return string.upper((#r == 1 and "0" or "") .. r .. (#g == 1 and "0" or "") .. g .. (#b == 1 and "0" or "") .. b)
end


return M
