---@class HudSettings
---@field minimap 'always' | 'vehicle' | 'off'
---@field cinematic boolean
---@field unit 'mph' | 'kmh'
---@field status table<string, string>
---@field layout { minimapOffset: { x: number, y: number } }

---@class HudState
---@field playerData table
---@field loaded boolean
---@field visible boolean
---@field paused boolean
---@field menuOpen boolean
---@field editing boolean
---@field buckled boolean
---@field settings HudSettings?
---@field hiddenBy table<string, true>
local state <const> = {
    playerData = {},
    loaded = false,
    visible = false,
    paused = false,
    menuOpen = false,
    editing = false,
    buckled = false,
    settings = nil,
    hiddenBy = {},
}

---@return boolean
function state.isReady()
    return state.loaded and LocalPlayer.state.LoggedIn == true
end

---@return boolean
function state.isSuppressed()
    return next(state.hiddenBy) ~= nil
end

return state
