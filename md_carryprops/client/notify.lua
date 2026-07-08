Notify = {}

--- Flexible Notification – erkennt ox_lib, QBCore, ESX, Fallback
function Notify.Send(message, nType)
    nType = nType or 'info'

    if GetResourceState('ox_lib') == 'started' then
        local ok = pcall(function()
            exports.ox_lib:notify({
                title = 'md_carryprops',
                description = message,
                type = nType == 'error' and 'error' or (nType == 'success' and 'success' or 'inform'),
            })
        end)
        if ok then return end
    end

    if Framework.name == 'qbcore' then
        local ok = pcall(function()
            local QBCore = exports['qb-core']:GetCoreObject()
            QBCore.Functions.Notify(message, nType)
        end)
        if ok then return end
    end

    if Framework.name == 'esx' then
        local ok = pcall(function()
            local ESX = exports['es_extended']:getSharedObject()
            ESX.ShowNotification(message)
        end)
        if ok then return end
    end

    -- GTA Fallback
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

function Notify.Locale(key)
    Notify.Send(Config.L(key))
end

function Notify.LocaleType(key, nType)
    Notify.Send(Config.L(key), nType)
end

RegisterNetEvent('md_carryprops:client:notify', function(message, nType)
    Notify.Send(message, nType)
end)
