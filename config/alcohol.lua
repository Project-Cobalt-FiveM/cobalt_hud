---@class HudBlackoutSpot
---@field label string
---@field coords vector4 Ground height is found at runtime, so `z` only needs to sit above the spot

---@class HudBlackoutAnim
---@field dict string
---@field clip string

---@class HudUnderwear
---@field components { component_id: integer, drawable: integer, texture: integer }[]

return {
    -- Alcohol from drinks, tracked from 0 to 100
    enabled = true, -- false turns drunkenness off

    -- How fast it wears off
    decay = {
        amount = 1, -- alcohol removed every interval
        interval = 10000, -- milliseconds
    },

    -- Alcohol level at which each stage starts, 0 to 100
    stages = {
        tipsy = 25, -- light sway and blur
        drunk = 50, -- drunk walk and steering pull
        blackingOut = 85, -- vision starts to go
        blackout = 100, -- the player passes out and wakes somewhere else
    },

    -- Tipsy stage effects
    tipsy = {
        shake = 0.3, -- camera sway at the tipsy threshold, rising to drunk.shake
        timecycle = 'Drunk', -- screen filter used while drinking
        strength = 0.15, -- timecycle strength at the tipsy threshold, rising to 1.0 at blackout
    },

    -- Drunk stage effects
    drunk = {
        shake = 1.0, -- camera sway at the drunk threshold, rising to blackout
        clipset = 'move_m@drunk@verydrunk', -- walk style while drunk
        steerBias = 0.25, -- largest steering pull for a drunk driver, -1 to 1
        steerInterval = 1500, -- milliseconds between steering pull changes
    },

    -- Blacking out and waking up somewhere else
    blackout = {
        fade = 1500, -- milliseconds for the screen fade to and from black
        black = 3500, -- milliseconds the screen stays black after the teleport
        timecycle = 'Drunk', -- timecycle that blurs and doubles the view, faded in on the way out and out on the way back
        shake = 'DRUNK_SHAKE', -- native camera shake used throughout
        sound = 'heartbeat', -- cobalt_sound file played as vision goes and again on waking

        fadeOut = {
            duration = 5000, -- milliseconds the vision swims and blurs before the screen goes black
            shake = 2.5, -- gameplay camera sway while vision goes
            audioScene = 'CHARACTER_CHANGE_IN_SKY_SCENE', -- native audio scene that muffles the world until the player is back on their feet
            volume = 0.7, -- heartbeat volume as vision goes, 0 to 1
        },

        wake = {
            ---@type HudBlackoutAnim
            lie = { dict = 'amb@world_human_sunbathe@male@back@base', clip = 'base' }, -- loops while the player lies on the ground
            ---@type HudBlackoutAnim
            getUp = { dict = 'amb@world_human_sunbathe@male@back@exit', clip = 'exit' }, -- played once as the camera pulls back
            fallbackGetUp = 3000, -- milliseconds of the native get-up when an anim dict can't load
            closeUp = 4500, -- milliseconds the camera stays close on the face before the get-up
            closeHeight = 0.7, -- meters above the head for the close-up
            closeFov = 30.0, -- field of view of the close-up camera, in degrees
            wideFov = 50.0, -- field of view as the camera pulls back, in degrees
            shake = 2.0, -- script camera sway at the close-up, easing to hangover.shake
            strength = 1.0, -- timecycle strength at the close-up, easing to hangover.strength
            easeOut = 2500, -- milliseconds the camera eases back to the gameplay camera
            volume = 0.5, -- heartbeat volume on waking, 0 to 1
        },

        hangover = {
            duration = 60000, -- milliseconds the after-effects take to wear off once the player can move
            shake = 0.6, -- gameplay camera sway at the start of the hangover
            strength = 0.45, -- timecycle strength at the start of the hangover
            clipset = 'move_m@drunk@slightlydrunk', -- walk style during the hangover
        },

        ---@type HudBlackoutSpot[]
        spots = { -- where a blacked-out player wakes up, picked at random
            { label = 'Mount Chiliad summit', coords = vec4(501.75, 5604.29, 800.0, 175.0) },
            { label = 'Muscle Sands', coords = vec4(-1201.0, -1567.0, 8.0, 120.0) },
            { label = 'Vespucci canals', coords = vec4(-1065.0, -1007.0, 6.0, 30.0) },
            { label = 'Little Bighorn Ave, Textile City', coords = vec4(499.0, -585.0, 30.0, 260.0) },
            { label = 'Maze Bank Tower roof', coords = vec4(-75.0, -818.0, 330.0, 160.0) },
            { label = 'Sandy Shores trailer', coords = vec4(1975.0, 3815.0, 36.0, 300.0) },
            { label = 'Grapeseed field', coords = vec4(2440.0, 4760.0, 38.0, 45.0) },
        },

        ---@type table<integer, HudUnderwear>
        underwear = { -- clothes a blacked-out player wakes up in, keyed by ped model; component_id is the clothing slot, drawable and texture pick the item; props are removed, and models not listed keep their clothes
            [`mp_m_freemode_01`] = {
                components = {
                    { component_id = 3, drawable = 15, texture = 0 },
                    { component_id = 4, drawable = 61, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 6, drawable = 34, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 8, drawable = 15, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 15, texture = 0 },
                },
            },
            [`mp_f_freemode_01`] = {
                components = {
                    { component_id = 3, drawable = 15, texture = 0 },
                    { component_id = 4, drawable = 17, texture = 0 },
                    { component_id = 5, drawable = 0, texture = 0 },
                    { component_id = 6, drawable = 35, texture = 0 },
                    { component_id = 7, drawable = 0, texture = 0 },
                    { component_id = 8, drawable = 14, texture = 0 },
                    { component_id = 9, drawable = 0, texture = 0 },
                    { component_id = 10, drawable = 0, texture = 0 },
                    { component_id = 11, drawable = 15, texture = 0 },
                },
            },
        },
    },
}
