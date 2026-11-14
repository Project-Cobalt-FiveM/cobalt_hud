local Cobalt <const> = exports.cobalt_core:GetCoreObject()

require 'server.stress'
require 'server.alcohol'

RegisterNetEvent('cobalt_hud:server:armorDepleted', function()
    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then return end

    player.Functions.SetMetaData('armor', 0)
end)
