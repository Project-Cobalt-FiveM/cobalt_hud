local config <const> = require 'config.alcohol'

---@type table<integer, true>
local drinkers <const> = {}
---@type table<integer, true>
local blackedOut <const> = {}

---@param source integer
---@return number
local function getAlcohol(source)
    return Player(source).state.alcohol or 0
end

---@param source integer
---@param value number
local function setAlcohol(source, value)
    local level <const> = math.floor(math.max(0, math.min(config.stages.blackout, value)) * 10 + 0.5) / 10

    drinkers[source] = level > 0 or nil

    if level >= config.stages.blackout then blackedOut[source] = true end

    Player(source).state:set('alcohol', level, true)
end

---@param source integer
---@param amount number
local function addAlcohol(source, amount)
    if not config.enabled or type(amount) ~= 'number' or amount <= 0 then return end
    if not DoesPlayerExist(tostring(source)) then return end

    setAlcohol(source, getAlcohol(source) + amount)
end

RegisterNetEvent('cobalt_hud:server:soberUp', function()
    local src <const> = source

    if not blackedOut[src] then return end

    blackedOut[src] = nil
    setAlcohol(src, 0)
end)

SetInterval(function()
    for src in pairs(drinkers) do
        if not blackedOut[src] then setAlcohol(src, getAlcohol(src) - config.decay.amount) end
    end
end, config.decay.interval)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    blackedOut[source] = nil
    setAlcohol(source, 0)
end)

AddEventHandler('playerDropped', function()
    drinkers[source] = nil
    blackedOut[source] = nil
end)

exports('AddAlcohol', addAlcohol)
