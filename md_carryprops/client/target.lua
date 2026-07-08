Target = {
    system = nil,
    registered = false,
}

local TARGET_OPTION = 'md_carryprops_pickup'

local function DetectTargetSystem()
    local cfg = Config.Interaction.targetSystem or 'auto'

    if cfg == 'ox_target' or cfg == 'auto' then
        if GetResourceState('ox_target') == 'started' then
            return 'ox_target'
        end
    end

    if cfg == 'qb-target' or cfg == 'auto' then
        if GetResourceState('qb-target') == 'started' then
            return 'qb-target'
        end
    end

    return nil
end

local function RegisterOxTarget(models)
    exports.ox_target:addModel(models, {
        {
            name = TARGET_OPTION,
            icon = Config.Interaction.targetIcon or 'fa-solid fa-hand',
            label = Interact.GetTargetLabel(),
            distance = Config.Interaction.targetDistance or 2.5,
            canInteract = function(entity)
                return Interact.CanPickupEntity(entity)
            end,
            onSelect = function(data)
                Interact.Pickup(data.entity)
            end,
        },
    })

    Utils.Debug('ox_target registriert für', #models, 'Models')
end

local function RegisterOxGlobalObject()
    exports.ox_target:addGlobalObject({
        {
            name = TARGET_OPTION,
            icon = Config.Interaction.targetIcon or 'fa-solid fa-hand',
            label = Interact.GetTargetLabel(),
            distance = Config.Interaction.targetDistance or 2.5,
            canInteract = function(entity)
                return Interact.CanPickupEntity(entity)
            end,
            onSelect = function(data)
                Interact.Pickup(data.entity)
            end,
        },
    })

    Utils.Debug('ox_target GlobalObject registriert')
end

local function RegisterQBTarget(models)
    if Config.UseWhitelist and #models == 0 then
        return
    end

    exports['qb-target']:AddTargetModel(models, {
        options = {
            {
                type = 'client',
                event = 'md_carryprops:client:targetPickup',
                icon = Config.Interaction.targetIcon or 'fas fa-hand',
                label = Interact.GetTargetLabel(),
                canInteract = function(entity)
                    return Interact.CanPickupEntity(entity)
                end,
            },
        },
        distance = Config.Interaction.targetDistance or 2.5,
    })

    Utils.Debug('qb-target registriert für', #models, 'Models')
end

local function RegisterQBGlobalObject()
    local ok = pcall(function()
        exports['qb-target']:AddGlobalObject({
            options = {
                {
                    type = 'client',
                    event = 'md_carryprops:client:targetPickup',
                    icon = Config.Interaction.targetIcon or 'fas fa-hand',
                    label = Interact.GetTargetLabel(),
                    canInteract = function(entity)
                        return Interact.CanPickupEntity(entity)
                    end,
                },
            },
            distance = Config.Interaction.targetDistance or 2.5,
        })
    end)

    if ok then
        Utils.Debug('qb-target GlobalObject registriert')
    end
end

function Target.IsEnabled()
    local mode = Config.Interaction.mode or 'target'
    return mode == 'target' or mode == 'both'
end

function Target.IsActive()
    return Target.registered and Target.system ~= nil
end

function Target.Init()
    if not Target.IsEnabled() then
        Utils.Debug('Target-Modus deaktiviert')
        return false
    end

    Target.system = DetectTargetSystem()
    if not Target.system then
        print('[^3md_carryprops^7] Kein Target-System gefunden – Fallback auf Raycast (E-Taste)')
        return false
    end

    if Target.system == 'ox_target' then
        if Config.UseWhitelist then
            local models = Utils.GetTargetModels()
            if #models > 0 then
                RegisterOxTarget(models)
            end
        else
            RegisterOxGlobalObject()
        end
    elseif Target.system == 'qb-target' then
        if Config.UseWhitelist then
            RegisterQBTarget(Utils.GetTargetModels())
        else
            RegisterQBGlobalObject()
        end
    end

    Target.registered = true
    print('[^2md_carryprops^7] Alt-Auge Interaktion aktiv: ' .. Target.system)
    return true
end

function Target.Cleanup()
    if not Target.registered or not Target.system then
        return
    end

    if Target.system == 'ox_target' then
        pcall(function()
            if Config.UseWhitelist then
                exports.ox_target:removeModel(Utils.GetTargetModels(), TARGET_OPTION)
            else
                exports.ox_target:removeGlobalObject(TARGET_OPTION)
            end
        end)
    elseif Target.system == 'qb-target' then
        pcall(function()
            exports['qb-target']:RemoveTargetModel(Utils.GetTargetModels(), Interact.GetTargetLabel())
        end)
    end

    Target.registered = false
    Target.system = nil
end

RegisterNetEvent('md_carryprops:client:targetPickup', function(data)
    local entity = data and data.entity or data
    Interact.Pickup(entity)
end)

CreateThread(function()
    -- Warten bis ox_target / qb-target gestartet ist
    local attempts = 0
    while attempts < 20 do
        if Target.Init() then
            break
        end
        if not Target.IsEnabled() then
            break
        end
        attempts = attempts + 1
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Target.Cleanup()
    end
end)
