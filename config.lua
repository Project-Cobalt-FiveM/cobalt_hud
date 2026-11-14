---@class HudSeatbeltConfig
---@field enabled boolean
---@field ejectMph number Speed above which an unbuckled occupant goes through the windscreen; needs `setr game_enableFlyThroughWindscreen true`
---@field minDamage number Damage dealt on ejection, 0 to 2000
---@field sounds boolean Play the buckle and unbuckle sounds
---@field volume number 0 to 1
---@field excludedClasses table<integer, true> Vehicle classes without a seatbelt

---@class HudConfig
---@field menuCommand string
---@field statusInterval integer ms between health, armour, stamina and voice reads
---@field vehicleInterval integer ms between speedometer reads
---@field locationInterval integer ms between street and postal reads
---@field warnFuel number Fuel percentage at which the fuel icon turns yellow
---@field warnEngine number Engine health percentage at which the engine icon turns red
---@field displayAmmo boolean Show GTA's ammo count next to the weapon
---@field seatbelt HudSeatbeltConfig

---@type HudConfig
return {
    -- HUD menu and refresh rates
    menuCommand = 'hud', -- chat command that opens the HUD settings menu
    statusInterval = 250, -- milliseconds between health, armour, stamina and voice reads
    vehicleInterval = 100, -- milliseconds between speedometer reads
    locationInterval = 500, -- milliseconds between street and postal reads

    -- Vehicle warnings
    warnFuel = 10, -- fuel percentage at which the fuel icon turns yellow
    warnEngine = 20, -- engine health percentage at which the engine icon turns red

    -- GTA HUD
    displayAmmo = false, -- show GTA's ammo count next to the weapon

    -- Seatbelts
    seatbelt = {
        enabled = true, -- false removes seatbelts and windscreen ejection
        ejectMph = 60, -- mph above which an unbuckled occupant goes through the windscreen; needs `setr game_enableFlyThroughWindscreen true`
        minDamage = 2000, -- damage dealt on ejection, 0 to 2000
        sounds = true, -- play the buckle and unbuckle sounds
        volume = 0.25, -- 0.0 to 1.0
        excludedClasses = { -- vehicle classes without a seatbelt: 8 motorcycles, 13 cycles, 14 boats, 15 helicopters, 16 planes, 21 trains
            [8] = true,
            [13] = true,
            [14] = true,
            [15] = true,
            [16] = true,
            [21] = true,
        },
    },
}
