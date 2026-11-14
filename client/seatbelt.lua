local config <const> = require 'config'
local state <const> = require 'client.state'

local seatbelt <const> = config.seatbelt
local MPH_TO_MPS <const> = 1 / 2.236936
local CONTROL_EXIT <const> = 75
local CONTROL_INDICATOR_LEFT <const> = 174
local CONTROL_INDICATOR_RIGHT <const> = 175
local CONTROL_HAZARDS <const> = 173

local watching = false

---@param buckled boolean
local function setEjection(buckled)
    if buckled then
        SetFlyThroughWindscreenParams(10000.0, 10000.0, 17.0, 500.0)
        return
    end

    SetFlyThroughWindscreenParams(
        seatbelt.ejectMph * MPH_TO_MPS,
        (seatbelt.ejectMph + 10) * MPH_TO_MPS,
        17.0,
        seatbelt.minDamage
    )
end

---@param buckled boolean
local function setBuckled(buckled)
    state.buckled = seatbelt.enabled and buckled
    setEjection(state.buckled)
end

---@param vehicle integer | false
---@return boolean
local function hasSeatbelt(vehicle)
    return vehicle ~= false and not seatbelt.excludedClasses[GetVehicleClass(vehicle)]
end

local function toggleSeatbelt()
    if not hasSeatbelt(cache.vehicle) then return end

    setBuckled(not state.buckled)

    if seatbelt.sounds and GetResourceState('cobalt_sound') == 'started' then
        exports.cobalt_sound:PlayFrontend(state.buckled and 'buckle' or 'unbuckle', seatbelt.volume)
    end

    exports.cobalt_core:Notify(
        state.buckled and 'Seatbelt fastened' or 'Seatbelt removed',
        state.buckled and 'success' or 'error',
        3000
    )
end

---@param vehicle integer
---@param from 0 | 1
---@param indicator 1 | 2 | 3
local function toggleIndicator(vehicle, from, indicator)
    local on <const> = GetVehicleIndicatorLights(vehicle) ~= indicator

    if indicator == 3 then
        SetVehicleIndicatorLights(vehicle, 0, on)
        SetVehicleIndicatorLights(vehicle, 1, on)
    else
        SetVehicleIndicatorLights(vehicle, from, on)
        SetVehicleIndicatorLights(vehicle, 1 - from, false)
    end

    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
end

---@param vehicle integer
local function handleDriverControls(vehicle)
    DisableControlAction(0, CONTROL_INDICATOR_LEFT, true)
    DisableControlAction(0, CONTROL_INDICATOR_RIGHT, true)
    DisableControlAction(0, CONTROL_HAZARDS, true)

    if IsDisabledControlJustPressed(0, CONTROL_INDICATOR_LEFT) then toggleIndicator(vehicle, 1, 1) end
    if IsDisabledControlJustPressed(0, CONTROL_INDICATOR_RIGHT) then toggleIndicator(vehicle, 0, 2) end
    if IsDisabledControlJustPressed(0, CONTROL_HAZARDS) then toggleIndicator(vehicle, 0, 3) end
end

local function holdExit()
    DisableControlAction(0, CONTROL_EXIT, true)
    DisableControlAction(27, CONTROL_EXIT, true)

    if IsDisabledControlJustPressed(0, CONTROL_EXIT) then
        exports.cobalt_core:Notify('Remove your seatbelt first', 'error', 3000)
    end
end

local function watchVehicle()
    if watching then return end

    watching = true

    CreateThread(function()
        local current

        while cache.vehicle do
            local vehicle <const> = cache.vehicle

            if vehicle ~= current then
                if current and state.buckled then setBuckled(false) end
                if not hasSeatbelt(vehicle) then setBuckled(false) end

                current = vehicle
            end

            local driving <const> = cache.seat == -1

            if state.buckled then holdExit() end
            if driving then handleDriverControls(vehicle) end

            Wait((state.buckled or driving) and 0 or 250)
        end

        watching = false
        if state.buckled then setBuckled(false) end
    end)
end

lib.onCache('vehicle', function(vehicle)
    if vehicle then SetTimeout(0, watchVehicle) end
end)

if seatbelt.enabled then
    setEjection(false)

    RegisterCommand('+seatbelt', toggleSeatbelt, false)
    RegisterCommand('-seatbelt', function() end, false)
    RegisterKeyMapping('+seatbelt', 'Toggle Seatbelt', 'keyboard', 'b')
end

if cache.vehicle then watchVehicle() end
