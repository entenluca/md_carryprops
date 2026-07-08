Placement = {
    active = false,
    entity = nil,
    category = nil,
    rotation = 0.0,
    fromPush = false,
}

function Placement.IsActive()
    return Placement.active
end

function Placement.GetEntity()
    return Placement.entity
end

--- Placement-Modus starten (aus Carry oder Push)
function Placement.Enter()
    local entity, category, fromPush

    if Carry.IsActive() then
        entity = Carry.entity
        category = Carry.category
        fromPush = false

        local ped = PlayerPedId()
        DetachEntity(entity, true, true)
        Utils.StopAnim(ped, Carry.animDict, Carry.animName)

        Carry.active = false
        Carry.entity = nil
        Carry.category = nil
        Carry.animDict = nil
        Carry.animName = nil
    elseif Push.IsActive() then
        entity = Push.entity
        category = Push.category
        fromPush = true

        Utils.StopAnim(PlayerPedId(), Push.animDict, Push.animName)

        Push.active = false
        Push.entity = nil
        Push.category = nil
        Push.animDict = nil
        Push.animName = nil
        Push.lastCoords = nil
    else
        return false
    end

    if not entity or not DoesEntityExist(entity) then
        return false
    end

    Utils.RequestControl(entity)

    Placement.active = true
    Placement.entity = entity
    Placement.category = category
    Placement.rotation = GetEntityHeading(entity)
    Placement.fromPush = fromPush

    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 200, false)

    Utils.Debug('Placement-Modus aktiv')
    return true
end

function Placement.Exit(cancelled)
    if not Placement.active then
        return
    end

    local entity = Placement.entity

    if entity and DoesEntityExist(entity) then
        ResetEntityAlpha(entity)
        SetEntityCollision(entity, true, true)

        if cancelled then
            local ped = PlayerPedId()
            local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
            local heading = GetEntityHeading(ped)
            Utils.SafePlaceEntity(entity, coords, heading)
            Notify.LocaleType('cancelled', 'info')
        end
    end

    Placement.active = false
    Placement.entity = nil
    Placement.category = nil
    Placement.rotation = 0.0
    Placement.fromPush = false
end

function Placement.Confirm()
    if not Placement.active or not Placement.entity then
        return
    end

    local entity = Placement.entity
    if not DoesEntityExist(entity) then
        Placement.Exit(true)
        return
    end

    local coords = GetEntityCoords(entity)
    local heading = Placement.rotation

    ResetEntityAlpha(entity)
    Utils.SafePlaceEntity(entity, coords, heading)

    Placement.active = false
    Placement.entity = nil
    Placement.category = nil
    Placement.rotation = 0.0
    Placement.fromPush = false

    Notify.LocaleType('placed', 'success')
end

--- Hover-Position und Rotation im Placement-Modus
function Placement.Update()
    if not Placement.active or not Placement.entity then
        return
    end

    local ped = PlayerPedId()
    local entity = Placement.entity

    if not DoesEntityExist(entity) then
        Placement.Exit(true)
        return
    end

    if not Utils.CanPlayerInteract(ped) then
        Placement.Exit(true)
        return
    end

    Utils.RequestControl(entity)

    -- Position vor dem Spieler (Kamera-Richtung bevorzugt)
    local camRot = GetGameplayCamRot(2)
    local dir = Utils.RotationToDirection(camRot)
    local pedCoords = GetEntityCoords(ped)
    local dist = Config.PlacementDistance

    local targetX = pedCoords.x + dir.x * dist
    local targetY = pedCoords.y + dir.y * dist
    local groundZ = Utils.GetGroundZ(targetX, targetY, pedCoords.z) + Config.PlacementHeight

    -- Sanftes Bewegen
    local current = GetEntityCoords(entity)
    local lerp = 0.4
    local newX = current.x + (targetX - current.x) * lerp
    local newY = current.y + (targetY - current.y) * lerp
    local newZ = current.z + (groundZ - current.z) * lerp

    SetEntityCoords(entity, newX, newY, newZ, false, false, false, false)
    SetEntityHeading(entity, Placement.rotation)

    -- Mausrad-Rotation
    if IsControlJustPressed(0, Config.Keys.scrollUp) or IsDisabledControlJustPressed(0, Config.Keys.scrollUp) then
        Placement.rotation = Placement.rotation + Config.RotationSpeed
    elseif IsControlJustPressed(0, Config.Keys.scrollDown) or IsDisabledControlJustPressed(0, Config.Keys.scrollDown) then
        Placement.rotation = Placement.rotation - Config.RotationSpeed
    end

    -- Steuerungshinweise
    Placement.DrawHints()
end

function Placement.DrawHints()
    local hints = {
        '~g~' .. Config.L('place') .. '~w~ [LMB]',
        '~r~' .. Config.L('cancel') .. '~w~ [RMB/Bksp]',
        '~y~' .. Config.L('rotate') .. '~w~ [Scroll]',
    }

    for i, text in ipairs(hints) do
        SetTextFont(4)
        SetTextScale(0.35, 0.35)
        SetTextColour(255, 255, 255, 200)
        SetTextCentre(true)
        SetTextDropshadow(1, 0, 0, 0, 200)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(0.5, 0.82 + (i * 0.025))
    end
end

function Placement.HandleInput()
    if not Placement.active then
        return
    end

    DisableControlAction(0, Config.Keys.place, true)
    DisableControlAction(0, Config.Keys.cancel, true)
    DisableControlAction(0, Config.Keys.cancelAlt, true)

    if IsDisabledControlJustPressed(0, Config.Keys.place) then
        Placement.Confirm()
    elseif IsDisabledControlJustPressed(0, Config.Keys.cancel)
        or IsDisabledControlJustPressed(0, Config.Keys.cancelAlt) then
        Placement.Exit(true)
    end
end

--- Placement-Thread
CreateThread(function()
    while true do
        if Placement.active then
            Placement.Update()
            Placement.HandleInput()
            Wait(0)
        else
            Wait(500)
        end
    end
end)
