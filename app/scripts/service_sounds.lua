local context = require("libs.context")
local GATE_TIME = 0.1
local EMPTY_TABLE = {}
local gate_timings = {}
local active_sounds_instances = {}
local SOUNDS_ID_CACHE = {}
local Service = {}

function Service.init()
    Service.play = context.bind_context(Service.play)
    ---@param sound_id number|hash|string sound_id
    ---@param properties { delay?:number, gain?:number, pan?:number, speed?:number, start_time?:number, start_frame?:number, ignore_gate: bool?, gate:number? }
    _G.play_sound = function (sound_id, properties)
        Service.play(sound_id, properties)
    end
end


---@param sound_id number|hash|string sound_id
---@param properties { delay?:number, gain?:number, pan?:number, speed?:number, start_time?:number, start_frame?:number, ignore_gate: bool?, gate:number? }
function Service.play(sound_id,properties)
    properties = properties or EMPTY_TABLE

    if(not properties.ignore_gate) then
        local last_t = gate_timings[sound_id] or 0
        local cur_t = socket.gettime()
        if(cur_t <= last_t) then return end
        gate_timings[sound_id] = cur_t + (properties.gate or GATE_TIME)
    end

    if(not SOUNDS_ID_CACHE[sound_id]) then
        SOUNDS_ID_CACHE[sound_id] = "/sounds#"..sound_id
    end
    local msg_id = SOUNDS_ID_CACHE[sound_id] 
    
    table.insert(
        active_sounds_instances, 
        sound.play(msg_id, properties, function (_, _, message)
            local exposed_play_id = message.play_id
            local index = table.find(active_sounds_instances, exposed_play_id)
            if(index) then
                table.remove(active_sounds_instances, index)
            end
        end)
    )
end

return Service
