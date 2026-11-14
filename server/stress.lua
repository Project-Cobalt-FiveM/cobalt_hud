local Cobalt <const> = exports.cobalt_core:GetCoreObject()
local config <const> = require 'config.stress'

local IDLE_SPEED <const> = 0.5

---@type table<integer, integer>
local lastGainAt <const> = {}
---@type table<integer, number>
local stressOf <const> = {}

---@param value number
---@return number
local function clampStress(value)
    return math.floor(math.max(0, math.min(100, value)) * 10 + 0.5) / 10
end

---@param role { name: string, onduty: boolean? }?
---@return boolean
local function roleIsExempt(role)
    if not role or not config.exemptJobs[role.name] then return false end

    return not config.exemptOnDutyOnly or role.onduty == true
end

---@param source integer
---@return boolean
local function isExempt(source)
    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then return true end

    return roleIsExempt(player.PlayerData.job)
end

---@param source integer
---@return number
local function getStress(source)
    return stressOf[source] or 0
end

---@param source integer
---@param value number
local function setStress(source, value)
    local stress <const> = clampStress(value)

    stressOf[source] = stress
    Player(source).state:set('stress', stress, true)

    local player <const> = Cobalt.Functions.GetPlayer(source)

    if player and player.PlayerData.metadata.stress ~= stress then
        player.Functions.SetMetaData('stress', stress)
    end
end

---@param source integer
---@param amount number
local function addStress(source, amount)
    if not config.enabled or type(amount) ~= 'number' or amount <= 0 then return end
    if isExempt(source) then return end

    setStress(source, getStress(source) + amount)
end

---@param source integer
---@param amount number
local function relieveStress(source, amount)
    if type(amount) ~= 'number' or amount <= 0 then return end

    setStress(source, getStress(source) - amount)
end

---@param bucket table<integer, integer>
---@param source integer
---@return boolean
local function takeReportSlot(bucket, source)
    local now <const> = GetGameTimer()

    if bucket[source] and now - bucket[source] < config.report.minInterval then return false end

    bucket[source] = now
    return true
end

---@param amount number
local function onClientGain(amount)
    local src <const> = source

    if type(amount) ~= 'number' then return end
    if not takeReportSlot(lastGainAt, src) then return end

    addStress(src, math.min(amount, config.report.maxAmount))
end

RegisterNetEvent('cobalt_hud:server:gainStress', onClientGain)
RegisterNetEvent('hud:server:GainStress', onClientGain)

---@param source integer
---@return boolean
local function isIdle(source)
    local ped <const> = GetPlayerPed(source)
    local vehicle <const> = GetVehiclePedIsIn(ped, false)

    return GetEntitySpeed(vehicle ~= 0 and vehicle or ped) < IDLE_SPEED
end

local function decayStress()
    for _, src in ipairs(Cobalt.Functions.GetPlayers()) do
        if getStress(src) > 0 then
            relieveStress(src, config.relief.decay + (isIdle(src) and config.relief.idleDecay or 0))
        end
    end
end

SetInterval(decayStress, config.relief.decayInterval)

---@param player table
local function loadStress(player)
    setStress(player.PlayerData.source, player.PlayerData.metadata.stress or 0)
end

AddEventHandler('cobalt_core:Server:PlayerLoaded', loadStress)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    for _, src in ipairs(Cobalt.Functions.GetPlayers()) do
        local player <const> = Cobalt.Functions.GetPlayer(src)

        if player then loadStress(player) end
    end
end)

AddEventHandler('playerDropped', function()
    lastGainAt[source] = nil
    stressOf[source] = nil
end)

exports('SetStress', setStress)
exports('AddStress', function(source, amount)
    if type(amount) == 'number' and amount < 0 then return relieveStress(source, -amount) end

    addStress(source, amount)
end)
