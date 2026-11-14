local config <const> = require 'config.stress'
local state <const> = require 'client.state'

local gain <const> = config.gain
local effects <const> = config.effects
local MPS_TO_UNIT <const> = { kmh = 3.6, mph = 2.236936 }
local toSpeedUnit <const> = MPS_TO_UNIT[config.speedUnit]
local DAMAGE_MELEE <const> = 2
local DAMAGE_BULLET <const> = 3
local EFFECT_TICK <const> = 250
local AIM_TICK <const> = 100

---@type table<integer, true>
local exemptWeapons <const> = {}

for _, hash in ipairs(gain.shooting.exemptWeapons) do
    exemptWeapons[hash] = true
end

---@return number
local function lowestEffectStress()
    local lowest = math.huge

    for _, effect in pairs(effects) do
        if effect.enabled then lowest = math.min(lowest, effect.minStress) end
    end

    return lowest
end

local effectThreshold <const> = lowestEffectStress()

local pendingGain = 0
local watchingShots = false
local watchingVehicle = false
local effectsRunning = false
local blurActive = false
local aimShaking = false

---@return number
local function getStress()
    return LocalPlayer.state.stress or 0
end

---@param role { name: string, onduty: boolean? }?
---@return boolean
local function roleIsExempt(role)
    if not role or not config.exemptJobs[role.name] then return false end

    return not config.exemptOnDutyOnly or role.onduty == true
end

---@return boolean
local function isExempt()
    return roleIsExempt(state.playerData.org) or roleIsExempt(state.playerData.job)
end

local function reportGain()
    TriggerServerEvent('cobalt_hud:server:gainStress', pendingGain)
    pendingGain = 0
end

---@param amount number
local function addStress(amount)
    if not config.enabled or amount <= 0 or isExempt() then return end

    if pendingGain == 0 then SetTimeout(config.report.interval, reportGain) end

    pendingGain += amount
end

local function watchShooting()
    if watchingShots or not gain.shooting.enabled then return end

    watchingShots = true

    CreateThread(function()
        Wait(0)

        while cache.weapon do
            if exemptWeapons[cache.weapon] or not IsPedArmed(cache.ped, 4) then
                Wait(500)
            else
                if IsPedShooting(cache.ped) and math.random() < gain.shooting.chance then
                    addStress(gain.shooting.amount)
                end

                Wait(0)
            end
        end

        watchingShots = false
    end)
end

local function watchDriving()
    if watchingVehicle then return end

    watchingVehicle = true

    CreateThread(function()
        Wait(0)

        local lastSpeed = 0
        local overThresholdFor = 0

        while cache.vehicle do
            local speed <const> = GetEntitySpeed(cache.vehicle) * toSpeedUnit
            local speedLost <const> = lastSpeed - speed
            local crashed <const> = speedLost >= gain.crash.minSpeedLoss and HasEntityCollidedWithAnything(cache.vehicle)

            if gain.crash.enabled and crashed then
                addStress(math.min(gain.crash.max, speedLost * gain.crash.perSpeedLost))
            end

            if gain.speeding.enabled and cache.seat == -1 and speed > gain.speeding.threshold then
                overThresholdFor += 100

                if overThresholdFor >= gain.speeding.interval then
                    addStress(gain.speeding.amount)
                    overThresholdFor = 0
                end
            else
                overThresholdFor = 0
            end

            lastSpeed = speed
            Wait(100)
        end

        watchingVehicle = false
    end)
end

---@param stress number
---@return number?
local function shakeIntensity(stress)
    local intensity

    for _, level in ipairs(effects.shake.levels) do
        if stress >= level.stress then intensity = level.intensity end
    end

    return intensity
end

---@return boolean
local function inMenu()
    return state.menuOpen or IsPauseMenuActive() or IsNuiFocused() or not IsScreenFadedIn()
end

local function blackout()
    local fade <const> = effects.blackout.fade

    DoScreenFadeOut(fade)
    Wait(fade + effects.blackout.duration)
    DoScreenFadeIn(fade)
end

---@param stress number
local function updateBlur(stress)
    local blur <const> = effects.blur

    if blur.enabled and stress >= blur.minStress then
        local progress <const> = (stress - blur.minStress) / math.max(1, 100 - blur.minStress)

        SetExtraTimecycleModifier(blur.modifier)
        SetExtraTimecycleModifierStrength(blur.minStrength + (1 - blur.minStrength) * progress)
        blurActive = true
    elseif blurActive then
        ClearExtraTimecycleModifier()
        blurActive = false
    end
end

---@param stress number
---@return boolean aiming
local function updateAimShake(stress)
    local aim <const> = effects.aim
    local aiming <const> = aim.enabled and stress >= aim.minStress and IsPlayerFreeAiming(cache.playerId)

    if aiming then
        local amplitude <const> = aim.maxShake * stress / 100

        if aimShaking and IsGameplayCamShaking() then
            SetGameplayCamShakeAmplitude(amplitude)
        else
            ShakeGameplayCam('HAND_SHAKE', amplitude)
            aimShaking = true
        end
    elseif aimShaking then
        StopGameplayCamShaking(false)
        aimShaking = false
    end

    return aiming
end

---@param stress number
local function shake(stress)
    local intensity <const> = effects.shake.enabled and stress >= effects.shake.minStress and shakeIntensity(stress)

    if intensity then ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity) end
end

---@param stress number
local function maybeBlackout(stress)
    local settings <const> = effects.blackout

    if not settings.enabled or stress < settings.minStress then return end
    if math.random() >= settings.chance or inMenu() then return end

    CreateThread(blackout)
end

---@param stress number
local function heartbeat(stress)
    if not effects.heartbeat.enabled or stress < effects.heartbeat.minStress then return end
    if GetResourceState('cobalt_sound') ~= 'started' then return end

    exports.cobalt_sound:PlayFrontend('heartbeat', effects.heartbeat.volume)
end

local function runEffects()
    if effectsRunning then return end

    effectsRunning = true

    CreateThread(function()
        local sinceSecond, sinceShake, sinceBlackout = 0, 0, 0
        local stress = getStress()

        while stress >= effectThreshold do
            local active <const> = state.isReady() and not IsEntityDead(cache.ped)
            local tick <const> = updateAimShake(active and stress or 0) and AIM_TICK or EFFECT_TICK

            Wait(tick)
            sinceSecond += tick

            if sinceSecond >= 1000 then
                updateBlur(active and stress or 0)

                if active then
                    sinceShake += sinceSecond
                    sinceBlackout += sinceSecond
                    heartbeat(stress)

                    if sinceShake >= effects.shake.interval then
                        sinceShake = 0
                        shake(stress)
                    end

                    if sinceBlackout >= effects.blackout.interval then
                        sinceBlackout = 0
                        maybeBlackout(stress)
                    end
                end

                sinceSecond = 0
            end

            stress = getStress()
        end

        updateBlur(0)
        updateAimShake(0)
        effectsRunning = false
    end)
end

lib.onCache('weapon', function(weapon)
    if weapon then watchShooting() end
end)

lib.onCache('vehicle', function(vehicle)
    if vehicle then watchDriving() end
end)

AddStateBagChangeHandler('stress', ('player:%s'):format(cache.serverId), function(_, _, value)
    if (value or 0) >= effectThreshold then SetTimeout(0, runEffects) end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim <const>, attacker <const>, weapon <const> = args[1], args[2], args[7]
    local ped <const> = cache.ped
    local damageType <const> = GetWeaponDamageType(weapon)

    if gain.melee.enabled and attacker == ped and victim ~= ped and damageType == DAMAGE_MELEE then
        addStress(gain.melee.amount)
    elseif gain.shotAt.enabled and victim == ped and attacker ~= ped and damageType == DAMAGE_BULLET then
        addStress(gain.shotAt.amount)
    end
end)

if getStress() >= effectThreshold then runEffects() end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if blurActive then ClearExtraTimecycleModifier() end

    StopGameplayCamShaking(true)

    if not IsScreenFadedIn() then DoScreenFadeIn(0) end
end)
