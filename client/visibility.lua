local state <const> = require 'client.state'
local nui <const> = require 'client.nui'
local minimap <const> = require 'client.minimap'

local visibility <const> = {}

---@param key string
---@param hidden boolean
function visibility.setHiddenBy(key, hidden)
    local before <const> = state.isSuppressed()

    state.hiddenBy[key] = hidden or nil

    local after <const> = state.isSuppressed()

    if before == after then return end

    nui.send(after and 'hideHud' or 'showHud')
    SetTimeout(0, minimap.refresh)
end

return visibility
