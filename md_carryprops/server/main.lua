-- =============================================================================
-- md_carryprops – Server
-- =============================================================================

--- Optional: Server-seitige Berechtigungsprüfung für Menü
RegisterNetEvent('md_carryprops:server:requestSpawn', function(model, category)
    local source = source

    if not Config.PropMenu.enabled then
        return
    end

    local allowed, reason = ServerFramework.HasMenuPermission(source)
    if not allowed then
        TriggerClientEvent('md_carryprops:client:notify', source, Config.L(reason), 'error')
        return
    end

    if type(model) ~= 'string' then
        return
    end

    -- Whitelist-Prüfung
    local hash = Utils.GetModelHash(model)
    if Config.UseWhitelist and not Utils.IsPropAllowed(hash) then
        TriggerClientEvent('md_carryprops:client:notify', source, Config.L('cannot_pickup'), 'error')
        return
    end

    TriggerClientEvent('md_carryprops:client:spawnProp', source, model, category)
end)

--- Berechtigung abfragen (Callback-Alternative)
RegisterNetEvent('md_carryprops:server:checkPermission', function()
    local source = source
    local allowed, reason = ServerFramework.HasMenuPermission(source)
    TriggerClientEvent('md_carryprops:client:permissionResult', source, allowed, reason)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        print('[^2md_carryprops^7] Resource gestartet – v1.0.0')
    end
end)
