local command_load_snapshot = require("app.gameplay.systems.session.command_load_snapshot")
local command_take_snapshot = require("app.gameplay.systems.session.command_take_snapshot")
local provider_level = require("app.gameplay.systems.provider_level")
---@class SystemLoadSnapshot
local System = class("SystemLoadSnapshot")

function System:awake() 
    command_take_snapshot.init(provider_level.get())

    command_load_snapshot.execute()
end

function System:final()
    command_take_snapshot.execute()
end

return System