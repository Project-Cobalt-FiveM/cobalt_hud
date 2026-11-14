local state <const> = require 'client.state'
local nui <const> = require 'client.nui'

local minimap <const> = {}

local MAP_WIDTH <const> = 0.1638
local MAP_HEIGHT <const> = 0.183
local MAP_BOTTOM <const> = -0.047

local squaremapLoaded = false
local patched = false
local offsetX = 0.0
local offsetY = 0.0
local lastSafezone = GetSafeZoneSize()
local lastResX, lastResY = GetActiveScreenResolution()
---@type boolean?
local lastShown

---@return boolean
local function loadSquaremap()
    if squaremapLoaded then return true end
    if not pcall(lib.requestStreamedTextureDict, 'squaremap', 5000) then return false end

    AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
    AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
    squaremapLoaded = true
    return true
end

local function holdBigmapClosed()
    CreateThread(function()
        for _ = 1, 10 do
            SetBigmapActive(false, false)
            Wait(1000)
        end
    end)
end

local function reloadComponents()
    SetBigmapActive(true, false)
    Wait(0)
    SetBigmapActive(false, false)
end

---@return { left: integer, top: integer, width: integer, height: integer, insetX: integer, insetY: integer }
local function geometry()
    local resX <const>, resY <const> = GetActiveScreenResolution()
    local aspect <const> = GetAspectRatio(false)

    SetScriptGfxAlign(string.byte('L'), string.byte('B'))
    local mapX <const>, mapY <const> = GetScriptGfxPosition(0.0, MAP_BOTTOM - MAP_HEIGHT)
    ResetScriptGfxAlign()

    SetScriptGfxAlign(string.byte('L'), string.byte('T'))
    local insetX <const>, insetY <const> = GetScriptGfxPosition(0.0, 0.0)
    ResetScriptGfxAlign()

    return {
        left = nui.round(mapX * resX + offsetX),
        top = nui.round(mapY * resY + offsetY),
        width = nui.round(MAP_WIDTH * resX * (16 / 9) / aspect),
        height = nui.round(MAP_HEIGHT * resY),
        insetX = nui.round(insetX * resX),
        insetY = nui.round(insetY * resY),
    }
end

local function placeComponents()
    local resX <const>, resY <const> = GetActiveScreenResolution()
    local aspect <const> = resX / resY
    local x <const> = offsetX / resX + (aspect > 16 / 9 and (16 / 9 - aspect) / 3.6 - 0.008 or 0.0)
    local y <const> = offsetY / resY

    SetMinimapClipType(0)
    SetMinimapComponentPosition('minimap', 'L', 'B', x, MAP_BOTTOM + y, MAP_WIDTH, MAP_HEIGHT)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', x, y, 0.128, 0.20)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', x - 0.01, 0.025 + y, 0.262, 0.300)
end

function minimap.patch()
    if patched or not loadSquaremap() then return end

    placeComponents()
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    reloadComponents()
    holdBigmapClosed()
    patched = true
    nui.send('setMinimapGeo', geometry())
end

---@param offset { x: number, y: number } 1080p reference pixels
function minimap.reposition(offset)
    local _, resY <const> = GetActiveScreenResolution()
    local x <const> = offset.x * resY / 1080
    local y <const> = offset.y * resY / 1080

    if x == offsetX and y == offsetY then return end

    offsetX, offsetY = x, y
    placeComponents()
    reloadComponents()
    nui.send('setMinimapGeo', geometry())
end

function minimap.checkScreen()
    local safezone <const> = GetSafeZoneSize()
    local resX <const>, resY <const> = GetActiveScreenResolution()

    if math.abs(safezone - lastSafezone) <= 0.001 and resX == lastResX and resY == lastResY then return end

    lastSafezone, lastResX, lastResY = safezone, resX, resY
    patched = false
    minimap.patch()
end

---@return boolean
local function wanted()
    if state.editing then return true end

    local settings <const> = state.settings

    if not settings or settings.cinematic then return false end

    return settings.minimap == 'always' or settings.minimap == 'vehicle' and cache.vehicle ~= false
end

function minimap.refresh()
    local available <const> = state.isReady() and not state.isSuppressed()
    local show <const> = available and wanted()

    if show == lastShown then return end

    lastShown = show

    if available then minimap.patch() end

    DisplayRadar(show)
    SetBigmapActive(false, false)
end

lib.onCache('vehicle', function()
    SetTimeout(0, minimap.refresh)
end)

return minimap
