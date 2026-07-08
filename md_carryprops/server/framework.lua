ServerFramework = {
    name = 'standalone',
    ready = false,
}

local ESX, QBCore

function ServerFramework.Init()
    if GetResourceState('es_extended') == 'started' then
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            ServerFramework.name = 'esx'
            ServerFramework.ready = true
            print('[^2md_carryprops^7] Server Framework: ESX')
            return
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok and obj then
            QBCore = obj
            ServerFramework.name = 'qbcore'
            ServerFramework.ready = true
            print('[^2md_carryprops^7] Server Framework: QBCore')
            return
        end
    end

    ServerFramework.name = 'standalone'
    ServerFramework.ready = true
    print('[^2md_carryprops^7] Server Framework: Standalone')
end

function ServerFramework.GetPlayerJob(source)
    if ServerFramework.name == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.job.name, xPlayer.job.grade
        end
    elseif ServerFramework.name == 'qbcore' and QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.job.name, Player.PlayerData.job.grade.level
        end
    end
    return nil, nil
end

function ServerFramework.HasMenuPermission(source)
    local menuCfg = Config.PropMenu

    if not menuCfg.enabled or menuCfg.permissionMode == 'disabled' then
        return false, 'menu_disabled'
    end

    if menuCfg.permissionMode == 'everyone' then
        return true
    end

    if menuCfg.permissionMode == 'jobs' then
        if ServerFramework.name == 'standalone' then
            return false, 'no_framework'
        end

        local jobName = ServerFramework.GetPlayerJob(source)
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

CreateThread(function()
    Wait(500)
    ServerFramework.Init()
end)
