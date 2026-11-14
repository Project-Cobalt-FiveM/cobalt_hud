local Cobalt <const> = exports.cobalt_core:GetCoreObject()

local MAX_COORD <const> = 10000
local SAVE_COOLDOWN_MS <const> = 1000

---@type table<integer, integer>
local lastSaveAt <const> = {}

local BAR_RULES <const> = {
    always        = true,
    hidden        = true,
    ['below:100'] = true,
    ['below:90']  = true,
    ['below:75']  = true,
    ['below:50']  = true,
    ['below:25']  = true,
    ['above:0']   = true,
}
local VOICE_RULES <const> = { always = true, hidden = true, talking = true }

local RULES <const> = {
    voice   = VOICE_RULES,
    health  = BAR_RULES,
    armor   = BAR_RULES,
    hunger  = BAR_RULES,
    thirst  = BAR_RULES,
    stamina = BAR_RULES,
    stress  = BAR_RULES,
    alcohol = BAR_RULES,
}

local MINIMAP_MODES <const> = { always = true, vehicle = true, off = true }
local SPEED_UNITS <const> = { mph = true, kmh = true }
local GRID_SIZES <const> = { [8] = true, [16] = true, [32] = true, [64] = true }

---@param p unknown
---@return { x: integer, y: integer }?
local function point(p)
    if type(p) ~= 'table' then return nil end

    local x <const>, y <const> = tonumber(p.x), tonumber(p.y)

    if not x or not y then return nil end
    if math.abs(x) > MAX_COORD or math.abs(y) > MAX_COORD then return nil end

    return { x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
end

---@param s unknown
---@return table?
local function sanitize(s)
    if type(s) ~= 'table' then return nil end

    if type(s.status) ~= 'table' or type(s.layout) ~= 'table' or type(s.editor) ~= 'table' then
        return nil
    end

    if not MINIMAP_MODES[s.minimap] or not SPEED_UNITS[s.unit] or not GRID_SIZES[s.editor.grid] then
        return nil
    end

    local status <const> = {}
    for id, allowed in pairs(RULES) do
        if not allowed[s.status[id]] then return nil end
        status[id] = s.status[id]
    end

    local minimapOffset <const> = point(s.layout.minimapOffset)
    if not minimapOffset then return nil end

    return {
        minimap   = s.minimap,
        cinematic = s.cinematic == true,
        unit      = s.unit,
        status    = status,
        layout    = {
            minimapOffset = minimapOffset,
            status        = point(s.layout.status),
            speedometer   = point(s.layout.speedometer),
        },
        editor    = {
            snap     = s.editor.snap == true,
            grid     = s.editor.grid,
            showGrid = s.editor.showGrid == true,
        },
    }
end

---@param source integer
---@return string?
local function citizenId(source)
    local player <const> = Cobalt.Functions.GetPlayer(source)
    return player and player.PlayerData.citizenid
end

lib.callback.register('cobalt_hud:server:getSettings', function(source)
    local cid <const> = citizenId(source)

    if not cid then return nil end

    local settings <const> = MySQL.scalar.await('SELECT settings FROM hud_settings WHERE citizenid = ?', { cid })
    return settings and json.decode(settings)
end)

RegisterNetEvent('cobalt_hud:server:saveSettings', function(raw)
    local src <const> = source
    local now <const> = GetGameTimer()

    if lastSaveAt[src] and now - lastSaveAt[src] < SAVE_COOLDOWN_MS then return end
    lastSaveAt[src] = now

    local cid <const> = citizenId(src)

    if not cid then return end

    local settings <const> = sanitize(raw)

    if not settings then return end

    MySQL.update.await([[
        INSERT INTO hud_settings (citizenid, settings) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE settings = VALUES(settings), updated_at = CURRENT_TIMESTAMP
    ]], { cid, json.encode(settings) })
end)

AddEventHandler('playerDropped', function()
    lastSaveAt[source] = nil
end)
