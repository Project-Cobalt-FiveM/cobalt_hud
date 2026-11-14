---@meta

---@class CobaltHudExports
local CobaltHudExports = {}

---**Client.** Hides the HUD while any `key` set by any resource is hidden, and shows it again once all are cleared. Keys are scoped to the calling resource and cleared when that resource stops.
---@param key string
---@param hidden boolean
function CobaltHudExports:SetHiddenBy(key, hidden) end

---**Server.** Sets a player's stress, clamped.
---@param source integer server id
---@param value number
function CobaltHudExports:SetStress(source, value) end

---**Server.** Adds stress to a player, or relieves it when `amount` is negative; exempt jobs gain none.
---@param source integer server id
---@param amount number
function CobaltHudExports:AddStress(source, amount) end

---**Server.** Adds alcohol to a player, capped at 100; at 100 the player blacks out and wakes up somewhere else.
---@param source integer server id
---@param amount number
function CobaltHudExports:AddAlcohol(source, amount) end

exports.cobalt_hud = CobaltHudExports
