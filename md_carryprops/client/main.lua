-- =============================================================================
-- md_carryprops – Client Main
-- =============================================================================

local State = {
    targetEntity = nil,
    targetCategory = nil,
    targetMode = nil,
}

local function UsesRaycastInteraction()
    local mode = Config.Interaction.mode or 'target'

    if mode == 'raycast' then
        return true
    end

    if mode == 'both' then
        return true
    end

    -- target-Modus: Raycast nur als Fallback wenn kein Target-System läuft
    if mode == 'target' and not Target.IsActive() then
        return true
    end

    return false
end

--- Grünes Hand-Symbol in der Bildschirmmitte (nur Raycast-Modus)
local function DrawHandIcon()
    if not Config.HandIcon.enabled then
        return
    end

    local cfg = Config.HandIcon
    SetTextFont(4)
    SetTextScale(cfg.scale, cfg.scale)
    SetTextColour(cfg.color.r, cfg.color.g, cfg.color.b, cfg.color.a)
    SetTextCentre(true)
    SetTextDropshadow(2, 0, 0, 0, 180)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(cfg.text)
    EndTextCommandDisplayText(0.5, 0.48 + cfg.offsetY)

    SetTextFont(4)
    SetTextScale(0.32, 0.32)
    SetTextColour(200, 255, 200, 180)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName('[E] ' .. Config.L('pickup'))
    EndTextCommandDisplayText(0.5, 0.54 + cfg.offsetY)
end

--- Ziel-Entity per Raycast finden
local function FindTargetProp()
    local ped = PlayerPedId()
    local hit, entity, _ = Utils.RaycastFromCamera(Config.MaxRaycastDistance, 16, ped)

    if not hit or not entity or entity == 0 then
        return nil
    end

    if not Interact.CanPickupEntity(entity) then
        return nil
    end

    local model = GetEntityModel(entity)
    local category = Utils.GetCategoryForModel(model)
    local mode = Utils.GetModeForCategory(category)

    return entity, category, mode
end

--- Eingaben während Carry/Push (nicht im Placement-Modus)
local function HandleActiveInput()
    if Placement.IsActive() then
        return
    end

    if not Carry.IsActive() and not Push.IsActive() then
        return
    end

    if IsControlJustPressed(0, Config.Keys.placementMode) then
        Placement.Enter()
        return
    end

    if IsControlJustPressed(0, Config.Keys.drop) then
        if Carry.IsActive() then
            Carry.Drop()
        elseif Push.IsActive() then
            Push.Drop()
        end
        return
    end

    local y = 0.88
    local hints = {
        '[G] ' .. Config.L('place_mode'),
        '[X] ' .. Config.L('drop'),
    }

    for _, hint in ipairs(hints) do
        SetTextFont(4)
        SetTextScale(0.33, 0.33)
        SetTextColour(255, 255, 255, 180)
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(hint)
        EndTextCommandDisplayText(0.5, y)
        y = y + 0.025
    end
end

--- Aufnahme per E-Taste (Raycast-Fallback)
local function HandlePickupInput()
    if Carry.IsActive() or Push.IsActive() or Placement.IsActive() then
        return
    end

    if not State.targetEntity or not DoesEntityExist(State.targetEntity) then
        return
    end

    DrawHandIcon()

    if IsControlJustPressed(0, Config.Keys.pickup) then
        Interact.Pickup(State.targetEntity)
    end
end

--- Haupt-Interaktions-Thread (performant)
CreateThread(function()
    while true do
        local sleep = Config.IdleWait

        if Placement.IsActive() then
            sleep = Config.ActiveWait
        elseif Carry.IsActive() or Push.IsActive() then
            HandleActiveInput()
            sleep = Config.ActiveWait
        elseif UsesRaycastInteraction() then
            local ped = PlayerPedId()
            local canInteract = Utils.CanPlayerInteract(ped)

            if canInteract then
                local entity, category, mode = FindTargetProp()
                State.targetEntity = entity
                State.targetCategory = category
                State.targetMode = mode

                if entity then
                    HandlePickupInput()
                    sleep = Config.NearbyWait
                end
            else
                State.targetEntity = nil
                State.targetCategory = nil
                State.targetMode = nil
            end
        else
            State.targetEntity = nil
            State.targetCategory = nil
            State.targetMode = nil
        end

        Wait(sleep)
    end
end)

--- Cleanup bei Resource-Stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    if Placement.IsActive() then
        Placement.Exit(true)
    elseif Carry.IsActive() then
        Carry.Stop(true)
    elseif Push.IsActive() then
        Push.Stop(true)
    end
end)

RegisterNetEvent('md_carryprops:client:spawnProp', function(model, category)
    Carry.SpawnAndHold(model, category)
end)

Utils.Debug('md_carryprops Client geladen')
