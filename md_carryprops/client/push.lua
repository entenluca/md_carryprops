Push = {
    active = false,
    entity = nil,
    category = nil,
    animDict = nil,
    animName = nil,
    lastCoords = nil,
}

function Push.IsActive()
    return Push.active and Push.entity and DoesEntityExist(Push.entity)
end

function Push.GetEntity()
    return Push.entity
end

function Push.Start(entity, category)
    local ped = PlayerPedId()
    local canInteract, reason = Utils.CanPlayerInteract(ped)
    if not canInteract then
        Notify.LocaleType(reason, 'error')
        return false
    end

    if Carry.IsActive() or Push.IsActive() then
        Notify.LocaleType('already_carrying', 'error')
        return false
    end

    if not DoesEntityExist(entity) then
        return false
    end

    if not Utils.RequestControl(entity) then
        Notify.LocaleType('cannot_pickup', 'error')
        return false
    end

    category = category or Utils.GetCategoryForModel(GetEntityModel(entity))
    local anim = Config.Animations.push

    Utils.PlayAnim(ped, anim.dict, anim.anim, anim.flag)

    DetachEntity(entity, true, true)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetEntityDynamic(entity, false)

    Push.active = true
    Push.entity = entity
    Push.category = category
    Push.animDict = anim.dict
    Push.animName = anim.anim
    Push.lastCoords = GetEntityCoords(entity)

    Utils.Debug('Push gestartet:', category)
    return true
end

function Push.Stop(placeOnGround)
    if not Push.active then
        return
    end

    local ped = PlayerPedId()
    local entity = Push.entity

    if entity and DoesEntityExist(entity) then
        if placeOnGround then
            local coords = GetEntityCoords(entity)
            local heading = GetEntityHeading(entity)
            Utils.SafePlaceEntity(entity, coords, heading)
        else
            FreezeEntityPosition(entity, true)
        end
    end

    if Push.animDict and Push.animName then
        Utils.StopAnim(ped, Push.animDict, Push.animName)
    end

    Push.active = false
    Push.entity = nil
    Push.category = nil
    Push.animDict = nil
    Push.animName = nil
    Push.lastCoords = nil
end

function Push.Drop()
    if not Push.IsActive() then
        return
    end

    local entity = Push.entity
    local heading = GetEntityHeading(entity)
    local coords = GetEntityCoords(entity)

    Utils.SafePlaceEntity(entity, coords, heading)
    Utils.StopAnim(PlayerPedId(), Push.animDict, Push.animName)

    Push.active = false
    Push.entity = nil
    Push.category = nil
    Push.animDict = nil
    Push.animName = nil
    Push.lastCoords = nil

    Notify.LocaleType('dropped', 'success')
end

--- Sanfte Schiebe-Logik – Entity vor dem Spieler positionieren
function Push.Update()
    if not Push.IsActive() then
        return
    end

    local ped = PlayerPedId()
    local entity = Push.entity
    local offset = Config.PushOffset

    if not Utils.CanPlayerInteract(ped) then
        Push.Drop()
        return
    end

    Utils.RequestControl(entity)

    local target = GetOffsetFromEntityInWorldCoords(ped, offset.x, offset.y, offset.z)
    local groundZ = Utils.GetGroundZ(target.x, target.y, target.z)
    local pedHeading = GetEntityHeading(ped)

    -- Interpolation für ruckelfreie Bewegung
    local current = GetEntityCoords(entity)
    local lerpFactor = 0.35
    local newX = current.x + (target.x - current.x) * lerpFactor
    local newY = current.y + (target.y - current.y) * lerpFactor
    local newZ = current.z + (groundZ - current.z) * lerpFactor

    SetEntityCoords(entity, newX, newY, newZ, false, false, false, false)
    SetEntityHeading(entity, pedHeading)
    FreezeEntityPosition(entity, true)

    Push.lastCoords = vector3(newX, newY, newZ)
end

--- Schiebe-Update-Thread
CreateThread(function()
    while true do
        if Push.IsActive() then
            Push.Update()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

--- Animations-Wiederholung
CreateThread(function()
    while true do
        if Push.IsActive() then
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, Push.animDict, Push.animName, 3) then
                Utils.PlayAnim(ped, Push.animDict, Push.animName, Config.Animations.push.flag)
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)
