local config <const> = require 'config'
local state <const> = require 'client.state'
local nui <const> = require 'client.nui'
local status <const> = require 'client.status'
local vehicleHud <const> = require 'client.vehicle'
local location <const> = require 'client.location'
local minimap <const> = require 'client.minimap'
local visibility <const> = require 'client.visibility'

require 'client.seatbelt'
require 'client.stress'

local HIDDEN_COMPONENTS <const> = { 1, 2, 3, 4, 6, 7, 8, 9, 13, 14, 19, 20, 21, 22 }
local HIDE_HEALTH_ARMOUR <const> = 3
local SHOW_DELAY <const> = 1500

local minimapScaleform <const> = RequestScaleformMovie('minimap')
local looping = false

local function hideNativeHud()
    for i = 1, #HIDDEN_COMPONENTS do
        HideHudComponentThisFrame(HIDDEN_COMPONENTS[i])
    end

    DisplayAmmoThisFrame(config.displayAmmo)

    BeginScaleformMovieMethod(minimapScaleform, 'SETUP_HEALTH_ARMOUR')
    ScaleformMovieMethodAddParamInt(HIDE_HEALTH_ARMOUR)
    EndScaleformMovieMethod()
end

local function updatePaused()
    local paused <const> = IsPauseMenuActive()

    if paused == state.paused then return end

    state.paused = paused
    nui.send('setPaused', { paused = paused })

    if not paused then minimap.checkScreen() end
end

local function runVisibleLoop()
    if looping then return end

    looping = true

    CreateThread(function()
        local nextStatus, nextVehicle, nextLocation = 0, 0, 0

        while state.visible do
            local now <const> = GetGameTimer()
            local statusDue <const> = now >= nextStatus

            hideNativeHud()

            if statusDue then
                nextStatus = now + config.statusInterval
                updatePaused()
            end

            if not state.paused and not state.menuOpen then
                if statusDue then status.push() end

                if cache.vehicle and now >= nextVehicle then
                    nextVehicle = now + config.vehicleInterval
                    vehicleHud.push()
                end

                if now >= nextLocation then
                    nextLocation = now + config.locationInterval
                    location.push()
                end
            end

            Wait(0)
        end

        looping = false
    end)
end

local function show()
    if not state.isReady() then return end

    minimap.patch()
    state.visible = true
    nui.send('toggleHud', { visible = true })
    status.refresh()
    vehicleHud.refresh()
    location.refresh()
    minimap.refresh()
    runVisibleLoop()
end

local function hide()
    state.visible = false
    nui.send('toggleHud', { visible = false })
    minimap.refresh()
end

local function loadSettings()
    nui.send('loadSettings', lib.callback.await('cobalt_hud:server:getSettings', false))
end

for _, key in ipairs({ 'invOpen', 'hideHud', 'isDead' }) do
    AddStateBagChangeHandler(key, ('player:%s'):format(cache.serverId), function(_, _, value)
        visibility.setHiddenBy(key, value == true)
    end)

    if LocalPlayer.state[key] == true then
        visibility.setHiddenBy(key, true)
    end
end

RegisterNetEvent('cobalt_core:Client:OnPlayerLoaded', function()
    status.loadPlayerData()
    loadSettings()
    state.loaded = true
    Wait(SHOW_DELAY)
    show()
end)

RegisterNetEvent('cobalt_core:Client:OnPlayerUnload', function()
    state.loaded = false
    state.settings = nil
    state.buckled = false

    if state.menuOpen then
        state.menuOpen = false
        SetNuiFocus(false, false)
        nui.send('closeMenu')
    end

    hide()
end)

AddEventHandler('cobalt_hud:setVisible', function(visible)
    if not visible then return hide() end

    status.loadPlayerData()
    show()
end)

RegisterCommand(config.menuCommand, function()
    if not state.isReady() then return end

    state.menuOpen = true
    SetNuiFocus(true, true)
    nui.send('openMenu')
end, false)

RegisterNUICallback('closeMenu', function(_, cb)
    state.menuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('applySettings', function(data, cb)
    cb('ok')

    local settings <const> = type(data) == 'table' and data.settings

    if type(settings) ~= 'table' or type(settings.layout?.minimapOffset) ~= 'table' then return end

    state.settings = settings
    state.editing = data.editing == true
    minimap.reposition(settings.layout.minimapOffset)
    minimap.refresh()
    vehicleHud.refresh()
end)

RegisterNUICallback('saveSettings', function(settings, cb)
    cb('ok')
    TriggerServerEvent('cobalt_hud:server:saveSettings', settings)
end)

---@param resource string
---@param key string
---@return string
local function hiderId(resource, key)
    return ('%s:%s'):format(resource, key)
end

exports('SetHiddenBy', function(key, hidden)
    visibility.setHiddenBy(hiderId(GetInvokingResource() or cache.resource, key), hidden == true)
end)

AddEventHandler('onResourceStop', function(resource)
    local prefix <const> = hiderId(resource, '')

    for id in pairs(state.hiddenBy) do
        if id:sub(1, #prefix) == prefix then
            visibility.setHiddenBy(id, false)
        end
    end
end)

if LocalPlayer.state.LoggedIn then
    status.loadPlayerData()
    state.loaded = true
    CreateThread(function()
        loadSettings()
        Wait(SHOW_DELAY)
        show()
    end)
else
    hide()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then SetNuiFocus(false, false) end
end)
