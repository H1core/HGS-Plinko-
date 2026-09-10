local grid = require("app.gameplay.systems.service_game_grid")
local gamecontext = require("app.gameplay.gamecontext")

---@class SystemMatchGameFrame
local System = class("SystemMatchGameFrame")

function System.calculate(width, height, design_width, design_height, bounds, settings)
    if width <= 0 or height <= 0 then return nil end
    local screen_height = settings.REFERENCE_HEIGHT
    local screen_width = screen_height * width / height

    local side = math.min(settings.SIDE_PADDING, screen_width * 0.25)
    local available_width = screen_width - side * 2
    local available_height = screen_height - settings.UI_BOTTOM - settings.TOP_PADDING
    local scale = math.min(
        available_width / (bounds.right - bounds.left),
        available_height / (bounds.top - bounds.bottom)
    )
    local auto_scale = math.min(screen_width / design_width, screen_height / design_height)
    local zoom = math.min(scale / auto_scale, 1.35)

    local effective_scale = zoom * auto_scale
    return {
        zoom = zoom,
        x = (bounds.left + bounds.right) * 0.5,
        y = bounds.bottom + (screen_height * 0.5 - settings.UI_BOTTOM) / effective_scale,
    }
end

function System:awake()
    self.settings = GAMECONSTANT.GAME_FRAME
    self.design_width = sys.get_config_number("display.width", 768)
    self.design_height = sys.get_config_number("display.height", 1336)
    self.window_width, self.window_height = nil, nil
    camera.set_orthographic_mode("/camera#camera", camera.ORTHO_MODE_AUTO_FIT)
    self:update()
end

function System:update()
    local width, height = window.get_size()
    if width <= 0 or height <= 0 then return end
    if width == self.window_width and height == self.window_height then return end

    local settings = self.settings
    local geometry = grid.get_frame_geometry()
    local bounds = {
        left = geometry.left - settings.BUCKET_HALF_WIDTH,
        right = geometry.right + settings.BUCKET_HALF_WIDTH,
        bottom = geometry.bottom - settings.BUCKET_BOTTOM_EXTENT,
        top = math.max(geometry.top + settings.TOP_CLEARANCE,
            gamecontext.spawn_position.y + settings.BALL_RADIUS),
    }
    local fit = System.calculate(width, height, self.design_width,
        self.design_height, bounds, settings)
    local position = go.get_position("/camera")
    position.x, position.y = fit.x, fit.y
    go.set_position(position, "/camera")
    go.set("/camera#camera", "orthographic_zoom", fit.zoom)
    self.window_width, self.window_height = width, height
end

return System
