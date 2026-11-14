local config <const> = require 'config.alcohol'
local state <const> = require 'client.state'
local visibility <const> = require 'client.visibility'

local stages <const> = config.stages
local blackout <const> = config.blackout
local EFFECT_TICK <const> = 250
local HANGOVER_TICK <const> = 100
local PED_FLAG_DRUNK <const> = 100
local HEAD_BONE <const> = 31086
local ANIM_LOOP <const> = 1
local CONTROL_PAUSE <const> = 199
local CONTROL_PAUSE_ALTERNATE <const> = 200

local alcohol <const> = {}

local level = LocalPlayer.state.alcohol or 0
local effectsRunning = false
local blackingOut = false
local walking = false
local timecycleActive = false
local controlsLocked = false
local audioMuffled = false
local hangoverActive = false
---@type integer?
local steeredVehicle
---@type integer[]
local cameras <const> = {}

---@param value number
---@return integer 0 sober, 1 tipsy, 2 drunk, 3 blacking out
function alcohol.stage(value)
    if value >= stages.blackingOut then return 3 end
    if value >= stages.drunk then return 2 end
    if value >= stages.tipsy then return 1 end

    return 0
end

---@return number
function alcohol.level()
    return level
end

---@param from number
---@param to number
---@param progress number
---@return number
local function lerp(from, to, progress)
    return from + (to - from) * math.max(0, math.min(1, progress))
end

---@param value number
local function updateScreen(value)
    if value < stages.tipsy then
        if timecycleActive then
            ClearExtraTimecycleModifier()
            timecycleActive = false
        end
        return
    end

    local progress <const> = (value - stages.tipsy) / (stages.blackout - stages.tipsy)

    if not timecycleActive then
        SetExtraTimecycleModifier(config.tipsy.timecycle)
        timecycleActive = true
    end

    SetExtraTimecycleModifierStrength(lerp(config.tipsy.strength, 1.0, progress))
end

---@param value number
local function updateShake(value)
    if value < stages.tipsy then return end

    local progress <const> = (value - stages.tipsy) / (stages.drunk - stages.tipsy)
    local amplitude <const> = lerp(config.tipsy.shake, config.drunk.shake, progress)

    if IsGameplayCamShaking() then
        SetGameplayCamShakeAmplitude(amplitude)
    else
        ShakeGameplayCam('DRUNK_SHAKE', amplitude)
    end
end

---@param clipset string
local function setClipset(clipset)
    lib.requestAnimSet(clipset)
    SetPedMovementClipset(cache.ped, clipset, 1.0)
    RemoveAnimSet(clipset)
end

---@param drunk boolean
local function updateWalk(drunk)
    if drunk == walking then return end

    walking = drunk
    SetPedIsDrunk(cache.ped, drunk)
    SetPedConfigFlag(cache.ped, PED_FLAG_DRUNK, drunk)

    if drunk then return setClipset(config.drunk.clipset) end

    ResetPedMovementClipset(cache.ped, 1.0)
end

local function releaseSteering()
    if steeredVehicle and DoesEntityExist(steeredVehicle) then SetVehicleSteerBias(steeredVehicle, 0.0) end

    steeredVehicle = nil
end

---@param drunk boolean
local function updateSteering(drunk)
    if not drunk or not cache.vehicle or cache.seat ~= -1 then return releaseSteering() end

    steeredVehicle = cache.vehicle
    SetVehicleSteerBias(steeredVehicle, (math.random() * 2 - 1) * config.drunk.steerBias)
end

local function clearEffects()
    updateScreen(0)
    updateWalk(false)
    releaseSteering()
    StopGameplayCamShaking(true)
end

local function runEffects()
    if effectsRunning then return end

    effectsRunning = true

    CreateThread(function()
        local sinceSteer = 0

        while level >= stages.tipsy and not blackingOut do
            local active <const> = state.isReady() and not LocalPlayer.state.isDead
            local value <const> = active and level or 0
            local drunk <const> = value >= stages.drunk

            updateScreen(value)
            updateShake(value)
            updateWalk(drunk)

            sinceSteer += EFFECT_TICK

            if sinceSteer >= config.drunk.steerInterval then
                sinceSteer = 0
                updateSteering(drunk)
            end

            Wait(EFFECT_TICK)
        end

        clearEffects()
        effectsRunning = false
    end)
end

---@return boolean
local function interrupted()
    return LocalPlayer.state.isDead == true or not state.isReady()
end

---Waits `duration` ms, calling `onTick` with progress from 0 to 1 every `tick` ms.
---@param duration integer
---@param onTick? fun(progress: number): false?
---@param tick? integer
---@return boolean finished false when the player died, logged out or `onTick` returned false
local function hold(duration, onTick, tick)
    local started <const> = GetGameTimer()

    while true do
        if interrupted() then return false end

        local progress <const> = math.min((GetGameTimer() - started) / duration, 1)

        if onTick and onTick(progress) == false then return false end
        if progress >= 1 then return true end

        Wait(tick or 50)
    end
end

local function lockControls()
    if controlsLocked then return end

    controlsLocked = true

    CreateThread(function()
        while controlsLocked do
            DisableAllControlActions(0)
            EnableControlAction(0, CONTROL_PAUSE, true)
            EnableControlAction(0, CONTROL_PAUSE_ALTERNATE, true)
            Wait(0)
        end
    end)
end

---@param muffled boolean
local function muffleAudio(muffled)
    if muffled == audioMuffled then return end

    audioMuffled = muffled

    if muffled then
        StartAudioScene(blackout.fadeOut.audioScene)
    else
        StopAudioScene(blackout.fadeOut.audioScene)
    end
end

---@param volume number
local function playSound(volume)
    if GetResourceState('cobalt_sound') ~= 'started' then return end

    exports.cobalt_sound:PlayFrontend(blackout.sound, volume)
end

---@param anim HudBlackoutAnim
---@return boolean
local function loadAnim(anim)
    return pcall(lib.requestAnimDict, anim.dict, 3000)
end

---@param anim HudBlackoutAnim
---@param flag integer
---@return integer duration ms
local function playAnim(anim, flag)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip, 2.0, 2.0, -1, flag, 0.0, false, false, false)

    local duration <const> = math.floor(GetAnimDuration(anim.dict, anim.clip) * 1000)

    RemoveAnimDict(anim.dict)

    return duration
end

---@param coords vector4
---@return vector3
local function groundAt(coords)
    for _ = 1, 50 do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        local found <const>, z <const> = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)

        if found then return vec3(coords.x, coords.y, z) end

        Wait(100)
    end

    return coords.xyz
end

local function stripToUnderwear()
    local outfit <const> = blackout.underwear[GetEntityModel(cache.ped)]

    if not outfit or GetResourceState('illenium-appearance') ~= 'started' then return end

    exports['illenium-appearance']:setPedComponents(cache.ped, outfit.components)
    ClearAllPedProps(cache.ped)
end

---@param position vector3
---@param fov number
---@param shake number
---@return integer
local function createCamera(position, fov, shake)
    local cam <const> = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', position.x, position.y, position.z, 0.0, 0.0, 0.0, fov, false, 2)

    PointCamAtPedBone(cam, cache.ped, HEAD_BONE, 0.0, 0.0, 0.0, true)
    ShakeCam(cam, blackout.shake, shake)
    cameras[#cameras + 1] = cam
    return cam
end

---@param shake number
local function shakeCameras(shake)
    for i = 1, #cameras do
        SetCamShakeAmplitude(cameras[i], shake)
    end
end

local function destroyCameras()
    for i = #cameras, 1, -1 do
        DestroyCam(cameras[i], false)
        cameras[i] = nil
    end
end

local function endHangover()
    if not hangoverActive then return end

    hangoverActive = false
    ClearTimecycleModifier()

    if not walking then ResetPedMovementClipset(cache.ped, 1.0) end
    if level < stages.tipsy then StopGameplayCamShaking(false) end
end

---@return boolean
local function visionGoes()
    local fadeOut <const> = blackout.fadeOut

    pcall(lib.waitFor, function() return not effectsRunning or nil end, nil, 1000)
    lockControls()
    visibility.setHiddenBy('blackout', true)
    muffleAudio(true)
    playSound(fadeOut.volume)
    TriggerScreenblurFadeIn(fadeOut.duration)
    SetTimecycleModifier(blackout.timecycle)
    SetTimecycleModifierStrength(0.0)
    ShakeGameplayCam(blackout.shake, fadeOut.shake)

    local swimming <const> = hold(fadeOut.duration, function(progress)
        SetTimecycleModifierStrength(progress)
    end, 0)

    if not swimming then return false end

    DoScreenFadeOut(blackout.fade)
    return hold(blackout.fade)
end

---@param spot HudBlackoutSpot
---@return boolean lying false when the lying anim failed to load and the ped lies ragdolled
local function layDown(spot)
    local ped <const> = cache.ped

    if cache.vehicle then ClearPedTasksImmediately(ped) end

    StopGameplayCamShaking(true)
    stripToUnderwear()
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, spot.coords.x, spot.coords.y, spot.coords.z, false, false, false, false)

    local ground <const> = groundAt(spot.coords)

    SetEntityCoords(ped, ground.x, ground.y, ground.z, false, false, false, false)
    SetEntityHeading(ped, spot.coords.w)
    pcall(lib.waitFor, function() return HasCollisionLoadedAroundEntity(ped) or nil end, nil, 5000)
    FreezeEntityPosition(ped, false)

    if loadAnim(blackout.wake.lie) then
        playAnim(blackout.wake.lie, ANIM_LOOP)
        return true
    end

    local ragdoll <const> = blackout.black + blackout.wake.closeUp

    SetPedToRagdoll(ped, ragdoll, ragdoll, 0, false, false, false)
    return false
end

---@param lying boolean
---@return integer duration ms
local function getUp(lying)
    if lying and loadAnim(blackout.wake.getUp) then return playAnim(blackout.wake.getUp, 0) end

    if lying then SetPedToRagdoll(cache.ped, 500, 500, 0, false, false, false) end

    return blackout.wake.fallbackGetUp
end

---@param lying boolean
---@return boolean
local function wakeUp(lying)
    local ped <const> = cache.ped
    local wake <const> = blackout.wake
    local hangover <const> = blackout.hangover
    local head <const> = GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0)
    local close <const> = createCamera(head + vec3(0.25, 0.25, wake.closeHeight), wake.closeFov, wake.shake)
    local wide <const> = createCamera(GetOffsetFromEntityInWorldCoords(ped, 1.6, -2.2, 1.0), wake.wideFov, wake.shake)

    SetCamActive(close, true)
    RenderScriptCams(true, false, 0, true, false)
    SetTimecycleModifierStrength(wake.strength)
    DoScreenFadeIn(blackout.fade)
    playSound(wake.volume)

    if not hold(wake.closeUp) then return false end

    local duration <const> = getUp(lying)

    muffleAudio(false)
    TriggerScreenblurFadeOut(duration)
    SetCamActiveWithInterp(wide, close, duration, 1, 1)

    local standing <const> = hold(duration, function(progress)
        SetTimecycleModifierStrength(lerp(wake.strength, hangover.strength, progress))
        shakeCameras(lerp(wake.shake, hangover.shake, progress))
    end, 0)

    if not standing then return false end

    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)
    ShakeGameplayCam(blackout.shake, hangover.shake)
    RenderScriptCams(false, true, wake.easeOut, true, false)

    if not hold(wake.easeOut) then return false end

    destroyCameras()
    return true
end

local function startHangover()
    local hangover <const> = blackout.hangover

    hangoverActive = true
    setClipset(hangover.clipset)

    CreateThread(function()
        hold(hangover.duration, function(progress)
            if not hangoverActive or level >= stages.tipsy then return false end

            SetTimecycleModifierStrength(lerp(hangover.strength, 0.0, progress))
            SetGameplayCamShakeAmplitude(lerp(hangover.shake, 0.0, progress))
        end, HANGOVER_TICK)

        endHangover()
    end)
end

---@param woke boolean
local function finishBlackout(woke)
    controlsLocked = false
    muffleAudio(false)
    visibility.setHiddenBy('blackout', false)
    FreezeEntityPosition(cache.ped, false)

    if #cameras > 0 then
        RenderScriptCams(false, false, 0, true, false)
        destroyCameras()
    end

    if woke then return end

    TriggerScreenblurFadeOut(500)
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)

    if not IsScreenFadedIn() and not IsScreenFadingIn() then DoScreenFadeIn(500) end
end

---@return boolean woke false when the player died or logged out partway
local function passOut()
    endHangover()

    if not visionGoes() then return false end

    TriggerServerEvent('cobalt_hud:server:soberUp')

    local lying <const> = layDown(blackout.spots[math.random(#blackout.spots)])

    if not hold(blackout.black) or not wakeUp(lying) then return false end

    startHangover()
    exports.cobalt_core:Notify(blackout.notify, 'info', 6000)
    return true
end

local function tryBlackout()
    if blackingOut or level < stages.blackout then return end
    if interrupted() then return end

    blackingOut = true

    CreateThread(function()
        finishBlackout(passOut())
        blackingOut = false
    end)
end

local playerBag <const> = ('player:%s'):format(cache.serverId)

AddStateBagChangeHandler('alcohol', playerBag, function(_, _, value)
    level = value or 0

    if level >= stages.blackout then return SetTimeout(0, tryBlackout) end
    if level >= stages.tipsy then SetTimeout(0, runEffects) end
end)

AddStateBagChangeHandler('isDead', playerBag, function(_, _, dead)
    if dead then return SetTimeout(0, endHangover) end

    SetTimeout(0, tryBlackout)
end)

if level >= stages.tipsy then runEffects() end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    clearEffects()
    endHangover()

    if blackingOut then finishBlackout(false) end
end)

return alcohol
