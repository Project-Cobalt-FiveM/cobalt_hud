local state <const> = require 'client.state'
local nui <const> = require 'client.nui'
local alcohol <const> = require 'client.alcohol'

local status <const> = {}

---@type table<string, number | boolean>
local last <const> = {}
local maxHealth = GetEntityMaxHealth(cache.ped)
local lastArmour = 0
local stress = LocalPlayer.state.stress or 0
local drink = LocalPlayer.state.alcohol or 0
local proximity = LocalPlayer.state.proximity?.index or 2

lib.onCache('ped', function(ped)
    maxHealth = GetEntityMaxHealth(ped)
end)

---@param value number
---@return integer
local function percent(value)
    return nui.round(math.max(0, math.min(100, value)))
end

---@return integer
local function readHealth()
    if maxHealth <= 100 then return 0 end

    return percent((GetEntityHealth(cache.ped) - 100) / (maxHealth - 100) * 100)
end

---@return integer
local function readArmour()
    local armour <const> = GetPedArmour(cache.ped)

    if lastArmour > 0 and armour <= 0 then
        TriggerServerEvent('cobalt_hud:server:armorDepleted')
    end

    lastArmour = armour
    return armour
end

---@return table<string, number | boolean>
local function read()
    local metadata <const> = state.playerData.metadata or {}

    return {
        health = readHealth(),
        armour = readArmour(),
        hunger = percent(metadata.hunger or 100),
        thirst = percent(metadata.thirst or 100),
        stamina = percent(100 - GetPlayerSprintStaminaRemaining(cache.playerId)),
        stress = percent(stress),
        alcohol = percent(drink),
        alcoholStage = alcohol.stage(drink),
        talking = NetworkIsPlayerTalking(cache.playerId),
        voiceLevel = proximity,
    }
end

function status.push()
    if not state.visible then return end

    nui.sendChanges('updateStatus', last, read())
end

function status.refresh()
    table.wipe(last)
    status.push()
end

function status.loadPlayerData()
    state.playerData = exports.cobalt_core:GetPlayerData() or {}
end

RegisterNetEvent('cobalt_core:Player:SetPlayerData', function(playerData)
    state.playerData = playerData or {}
    status.push()
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst)
    local metadata <const> = state.playerData.metadata or {}

    metadata.hunger = hunger
    metadata.thirst = thirst
    state.playerData.metadata = metadata
    status.push()
end)

local playerBag <const> = ('player:%s'):format(cache.serverId)

AddStateBagChangeHandler('stress', playerBag, function(_, _, value)
    stress = value or 0
    status.push()
end)

AddStateBagChangeHandler('alcohol', playerBag, function(_, _, value)
    drink = value or 0
    status.push()
end)

AddStateBagChangeHandler('proximity', playerBag, function(_, _, value)
    proximity = value?.index or 2
    status.push()
end)

return status
