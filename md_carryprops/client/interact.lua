Interact = {}

-- Target-Stub: muss vor main.lua verfügbar sein (auch wenn target.lua fehlt oder später lädt)
Target = Target or {
    system = nil,
    registered = false,
}

function Target.IsEnabled()
    local mode = Config.Interaction and Config.Interaction.mode or 'target'
    return mode == 'target' or mode == 'both'
end

function Target.IsActive()
    return Target.registered == true and Target.system ~= nil
end

--- Zentrale Aufnahme-Logik (Raycast, ox_target, qb-target)
function Interact.Pickup(entity)
    if Carry.IsActive() or Push.IsActive() or Placement.IsActive() then
        Notify.LocaleType('already_carrying', 'error')
        return false
    end

    if not entity or not DoesEntityExist(entity) then
        Notify.LocaleType('no_prop', 'error')
        return false
    end

    if GetEntityType(entity) ~= 3 then
        Notify.LocaleType('cannot_pickup', 'error')
        return false
    end

    local ped = PlayerPedId()
    local canInteract, reason = Utils.CanPlayerInteract(ped)
    if not canInteract then
        Notify.LocaleType(reason, 'error')
        return false
    end

    local model = GetEntityModel(entity)
    if not Utils.IsPropAllowed(model) then
        Notify.LocaleType('cannot_pickup', 'error')
        return false
    end

    local category = Utils.GetCategoryForModel(model)
    local mode = Utils.GetModeForCategory(category)

    if mode == 'push' then
        return Push.Start(entity, category)
    end

    return Carry.Start(entity, category, mode)
end

function Interact.CanPickupEntity(entity)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    if GetEntityType(entity) ~= 3 then
        return false
    end

    if Carry.IsActive() or Push.IsActive() or Placement.IsActive() then
        return false
    end

    local canInteract = Utils.CanPlayerInteract(PlayerPedId())
    if not canInteract then
        return false
    end

    return Utils.IsPropAllowed(GetEntityModel(entity))
end

function Interact.GetTargetLabel()
    local cfg = Config.Interaction
    if cfg and cfg.targetLabel and cfg.targetLabel ~= '' then
        return cfg.targetLabel
    end
    return Config.L('pickup')
end
