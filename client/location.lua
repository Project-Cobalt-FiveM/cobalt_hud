local state <const> = require 'client.state'
local nui <const> = require 'client.nui'

local location <const> = {}

---@type table<string, string | boolean>
local last <const> = {}

---@param coords vector3
---@return string
local function nearestPostal(coords)
    if GetResourceState('cobalt_map') ~= 'started' then return '' end

    return exports.cobalt_map:GetNearestPostal(coords)?.code or ''
end

---@param coords vector3
---@return string
local function streetName(coords)
    local hash <const> = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

    return hash ~= 0 and GetStreetNameFromHashKey(hash) or ''
end

---@param coords vector3
---@return string
local function areaName(coords)
    return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
end

function location.push()
    if not state.visible then return end

    if IsRadarHidden() then
        nui.sendChanges('updateLocation', last, { shown = false })
        return
    end

    local coords <const> = GetEntityCoords(cache.ped)

    nui.sendChanges('updateLocation', last, {
        shown = true,
        street = streetName(coords),
        area = areaName(coords),
        postal = nearestPostal(coords),
    })
end

function location.refresh()
    table.wipe(last)
    location.push()
end

return location
