Carry = {
    active = false,
    entity = nil,
    category = nil,
    mode = nil,
    animDict = nil,
    animName = nil,
}

function Carry.IsActive()
    return Carry.active and Carry.entity and DoesEntityExist(Carry.entity)
end

function Carry.GetEntity()
    return Carry.entity
end

local function GetCarryAnimation(category)
    if category == 'construction' then
        return Config.Animations.carryOneHand or Config.Animations.carry
    end
    return Config.Animations.carry
end

function Carry.ApplyAttach(entity, ped, category)
    if not DoesEntityExist(entity) or not DoesEntityExist(ped) then
        return
    end

    local model = GetEntityModel(entity)
    local offset = Utils.GetAttachOffset(category, model)

    DetachEntity(entity, true, true)

    AttachEntityToEntity(
        entity, ped, GetPedBoneIndex(ped, offset.bone),
        offset.x, offset.y, offset.z,
        offset.rx, offset.ry, offset.rz,
        true, true, false, true, 1, true
    )
end

function Carry.Start(entity, category, mode)
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

    local model = GetEntityModel(entity)
    if not Utils.IsPropAllowed(model) then
        Notify.LocaleType('cannot_pickup', 'error')
        return false
    end

    category = category or Utils.GetCategoryForModel(model)
    mode = mode or Utils.GetModeForCategory(category)

    if mode == 'push' then
        return Push.Start(entity, category)
    end

    if not Utils.RequestControl(entity) then
        Notify.LocaleType('cannot_pickup', 'error')
        return false
    end

    local anim = GetCarryAnimation(category)

    DetachEntity(entity, true, true)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)

    Utils.PlayAnim(ped, anim.dict, anim.anim, anim.flag)

    -- Kurz warten bis Animation läuft, dann sauber attachieren
    Wait(100)
    Carry.ApplyAttach(entity, ped, category)

    Carry.active = true
    Carry.entity = entity
    Carry.category = category
    Carry.mode = mode
    Carry.animDict = anim.dict
    Carry.animName = anim.anim

    Utils.Debug('Carry gestartet:', category)
    return true
end

function Carry.Stop(placeOnGround)
    if not Carry.active then
        return
    end

    local ped = PlayerPedId()
    local entity = Carry.entity

    if entity and DoesEntityExist(entity) then
        DetachEntity(entity, true, true)
        SetEntityCollision(entity, true, true)
        FreezeEntityPosition(entity, false)

        if placeOnGround then
            local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.8, 0.0)
            local heading = GetEntityHeading(ped)
            Utils.SafePlaceEntity(entity, coords, heading)
        end
    end

    if Carry.animDict and Carry.animName then
        Utils.StopAnim(ped, Carry.animDict, Carry.animName)
    end

    Carry.active = false
    Carry.entity = nil
    Carry.category = nil
    Carry.mode = nil
    Carry.animDict = nil
    Carry.animName = nil
end

function Carry.Drop()
    if not Carry.IsActive() then
        return
    end

    local ped = PlayerPedId()
    local entity = Carry.entity
    local heading = GetEntityHeading(ped)
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.9, 0.0)

    if Validation and Validation.TryPlace and not Validation.TryPlace(entity, coords, heading) then
        return
    end

    DetachEntity(entity, true, true)
    Utils.SafePlaceEntity(entity, coords, heading)
    Utils.StopAnim(ped, Carry.animDict, Carry.animName)

    Carry.active = false
    Carry.entity = nil
    Carry.category = nil
    Carry.mode = nil
    Carry.animDict = nil
    Carry.animName = nil

    Notify.LocaleType('dropped', 'success')
end

--- Prop aus Menü direkt in die Hand spawnen
function Carry.SpawnAndHold(modelName, category)
    local ped = PlayerPedId()
    local canInteract, reason = Utils.CanPlayerInteract(ped)
    if not canInteract then
        Notify.LocaleType(reason, 'error')
        return
    end

    if Carry.IsActive() or Push.IsActive() then
        Notify.LocaleType('already_carrying', 'error')
        return
    end

    local hash = Utils.LoadModel(modelName)
    if not hash then
        Notify.Send('Ungültiges Prop-Model: ' .. tostring(modelName), 'error')
        return
    end

    local coords = GetEntityCoords(ped)
    local entity = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)

    if not DoesEntityExist(entity) then
        Utils.UnloadModel(hash)
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    SetNetworkIdCanMigrate(netId, true)
    SetEntityAsMissionEntity(entity, true, true)

    category = category or Utils.GetCategoryForModel(hash)
    local mode = Utils.GetModeForCategory(category)

    Utils.UnloadModel(hash)

    if mode == 'push' then
        Push.Start(entity, category)
    else
        Carry.Start(entity, category, mode)
    end

    Notify.LocaleType('prop_spawned', 'success')
end

--- Animations-Thread (nur wenn aktiv)
CreateThread(function()
    while true do
        if Carry.IsActive() then
            local ped = PlayerPedId()
            local entity = Carry.entity

            if not IsEntityPlayingAnim(ped, Carry.animDict, Carry.animName, 3) then
                Utils.PlayAnim(ped, Carry.animDict, Carry.animName, Config.Animations.carry.flag)
                Wait(50)
                Carry.ApplyAttach(entity, ped, Carry.category)
            end

            Wait(500)
        else
            Wait(1000)
        end
    end
end)
