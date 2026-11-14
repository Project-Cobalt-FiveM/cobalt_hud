return {
    -- Stress, tracked from 0 to 100
    enabled = true, -- false turns stress off

    exemptJobs = { -- job names that never gain stress
        police = true, -- job name = true
        ambulance = true,
    },
    exemptOnDutyOnly = true, -- exempt those jobs only while on duty

    -- What raises stress
    gain = {
        shooting = {
            enabled = true, -- false turns this source off
            amount = 1, -- stress per shot that rolls under chance
            chance = 0.4, -- 0 to 1, rolled per shot
            exemptWeapons = { -- weapons that never add stress
                `WEAPON_STUNGUN`,
                `WEAPON_STUNGUN_MP`,
                `WEAPON_PETROLCAN`,
                `WEAPON_FIREEXTINGUISHER`,
                `WEAPON_HAZARDCAN`,
                `WEAPON_SNOWBALL`,
                `WEAPON_BALL`,
                `WEAPON_FLARE`,
            },
        },
        crash = {
            enabled = true,
            minSpeedLoss = 25, -- smallest speed drop in speedUnit that counts as a crash
            perSpeedLost = 0.3, -- stress per speedUnit lost in the crash
            max = 15, -- most stress one crash can add
        },
        speeding = {
            enabled = true,
            threshold = 140, -- speed in speedUnit above which driving adds stress
            amount = 1, -- stress added each interval spent over the threshold
            interval = 10000, -- milliseconds
        },
        melee = {
            enabled = true,
            amount = 1, -- stress per melee hit the player lands
        },
        shotAt = {
            enabled = true,
            amount = 2, -- stress per bullet that hits the player
        },
    },

    speedUnit = 'kmh', -- unit for the crash and speeding speeds

    -- What lowers stress
    relief = {
        decay = 1, -- stress removed every decayInterval, always
        decayInterval = 30000, -- milliseconds
        idleDecay = 2, -- extra stress removed every decayInterval while on foot and still, or seated in a stopped vehicle
    },

    -- Effects at high stress; minStress is the stress at which each one starts
    effects = {
        shake = {
            enabled = true, -- false turns this effect off
            minStress = 50, -- stress at which it starts
            interval = 12000, -- milliseconds between shakes
            levels = { -- shake intensity from each stress level up; the highest level reached wins
                { stress = 50, intensity = 0.04 },
                { stress = 75, intensity = 0.08 },
                { stress = 90, intensity = 0.14 },
            },
        },
        blackout = {
            enabled = true,
            minStress = 85,
            chance = 0.2, -- 0 to 1, rolled every interval
            interval = 30000, -- milliseconds
            duration = 1200, -- milliseconds the screen stays black
            fade = 400, -- milliseconds for each fade
        },
        blur = {
            enabled = true,
            minStress = 70,
            modifier = 'drug_drive_blend01', -- timecycle modifier applied while stressed
            minStrength = 0.3, -- strength at minStress, rising to 1.0 at 100 stress
        },
        heartbeat = {
            enabled = false,
            minStress = 80,
            volume = 0.4, -- heartbeat sound volume, 0 to 1
        },
        aim = {
            enabled = true,
            minStress = 60,
            maxShake = 0.6, -- hand shake amplitude while aiming at 100 stress
        },
    },

    -- How the client reports stress to the server
    report = {
        interval = 2000, -- milliseconds the client batches gains before sending them
        maxAmount = 25, -- most stress the server accepts from one client report
        minInterval = 1000, -- milliseconds the server requires between reports from one player
    },
}
