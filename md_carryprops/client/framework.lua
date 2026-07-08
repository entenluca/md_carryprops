Framework = {
    name = 'standalone',
    ready = false,
}

local ESX, QBCore

--- Framework automatisch erkennen (Client)
function Framework.Init()
    if GetResourceState('es_extended') == 'started' then
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if not ok then
            TriggerEvent('esx:getSharedObject', function(o) ESX = o end)
            Wait(100)
        else
            ESX = obj
        end
        if ESX then
            Framework.name = 'esx'
            Framework.ready = true
            Utils.Debug('Framework erkannt: ESX')
            return
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok and obj then
            QBCore = obj
            Framework.name = 'qbcore'
            Framework.ready = true
            Utils.Debug('Framework erkannt: QBCore')
            return
        end
    end

    Framework.name = 'standalone'
    Framework.ready = true
    Utils.Debug('Framework: Standalone-Modus')
end

--- Spieler-Job abrufen
function Framework.GetPlayerJob()
    if Framework.name == 'esx' and ESX then
        local data = ESX.GetPlayerData()
        if data and data.job then
            return data.job.name, data.job.grade
        end
    elseif Framework.name == 'qbcore' and QBCore then
        local data = QBCore.Functions.GetPlayerData()
        if data and data.job then
            return data.job.name, data.job.grade and data.job.grade.level or 0
        end
    end
    return nil, nil
end

--- Prüft Prop-Menü-Berechtigung
function Framework.HasMenuPermission()
    local menuCfg = Config.PropMenu

    if not menuCfg.enabled or menuCfg.permissionMode == 'disabled' then
        return false, 'menu_disabled'
    end

    if menuCfg.permissionMode == 'everyone' then
        return true
    end

    if menuCfg.permissionMode == 'jobs' then
        if Framework.name == 'standalone' then
            return false, 'no_framework'
        end

        local jobName = Framework.GetPlayerJob()
        if not jobName then
            return false, 'no_permission'
        end

        if menuCfg.allowedJobs[jobName] then
            return true
        end

        return false, 'no_permission'
    end

    return false, 'menu_disabled'
end

--- Menü-System erkennen
function Framework.GetMenuType()
    local cfg = Config.PropMenu.menuType
    if cfg ~= 'auto' then
        return cfg
    end

    if GetResourceState('ox_lib') == 'started' then
        return 'ox_lib'
    end
    if GetResourceState('qb-menu') == 'started' then
        return 'qb-menu'
    end
    if GetResourceState('esx_menu_default') == 'started' then
        return 'esx_menu'
    end

    return 'fallback'
end

CreateThread(function()
    Wait(500)
    Framework.Init()
end)
