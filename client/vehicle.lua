local config <const> = require 'config'
local state <const> = require 'client.state'
local nui <const> = require 'client.nui'

local vehicleHud <const> = {}

local MPS_TO_UNIT <const> = { mph = 2.236936, kmh = 3.6 }

---@type table<string, number | boolean | string>
local last <const> = {}
local shown = false

---@param running boolean
---@param gear integer
---@return 'P' | 'R' | 'D'
local function driveState(running, gear)
    if not running then return 'P' end
    if gear == 0 then return 'R' end

    return 'D'
end

---@param vehicle integer
---@return 'on' | 'off' | false
local function seatbelt(vehicle)
    if not config.seatbelt.enabled or config.seatbelt.excludedClasses[GetVehicleClass(vehicle)] then return false end

    return state.buckled and 'on' or 'off'
end

---@param vehicle integer
---@return table<string, number | boolean | string>
local function read(vehicle)
    local unit <const> = state.settings?.unit or 'mph'
    local gear <const> = GetVehicleCurrentGear(vehicle)
    local running <const> = GetIsVehicleEngineRunning(vehicle)
    local vehicleState <const> = Entity(vehicle).state
    local fuel <const> = nui.round(vehicleState.fuel or GetVehicleFuelLevel(vehicle))
    local engine <const> = GetVehicleEngineHealth(vehicle) / 10
    local _, lightsOn <const>, highbeamsOn <const> = GetVehicleLightsState(vehicle)

    return {
        show = true,
        speed = nui.round(GetEntitySpeed(vehicle) * (MPS_TO_UNIT[unit] or MPS_TO_UNIT.mph)),
        rpm = math.floor(GetVehicleCurrentRpm(vehicle) * 100),
        gear = gear,
        drive = driveState(running, gear),
        engineOn = running,
        fuel = fuel,
        fuelLow = fuel <= config.warnFuel,
        engineWarn = engine <= config.warnEngine or vehicleState.checkEngine == true,
        seatbelt = seatbelt(vehicle),
        lights = lightsOn == 1 or highbeamsOn == 1,
    }
end

function vehicleHud.push()
    if not state.visible then return end

    local vehicle <const> = cache.vehicle

    if vehicle then
        shown = true
        nui.sendChanges('updateVehicle', last, read(vehicle))
    elseif shown then
        shown = false
        table.wipe(last)
        nui.send('updateVehicle', { show = false })
    end
end

function vehicleHud.refresh()
    table.wipe(last)
    vehicleHud.push()
end

lib.onCache('vehicle', function()
    SetTimeout(0, vehicleHud.push)
end)

return vehicleHud
