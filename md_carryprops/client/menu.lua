PropMenu = {}

local searchFilter = ''

--- Native GTA-Tastatureingabe für Suche
function PropMenu.NativeSearch()
    local result = nil
    DisplayOnscreenKeyboard(1, 'FMMC_KEY_TIP8', '', searchFilter, '', '', '', 60)

    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end

    if UpdateOnscreenKeyboard() == 1 then
        result = GetOnscreenKeyboardResult()
    end

    return result
end

function PropMenu.GetFilteredProps(filter)
    local list = {}
    filter = filter and string.lower(filter) or ''

    for _, prop in ipairs(Config.MenuProps) do
        local label = string.lower(prop.label or '')
        local model = string.lower(prop.model or '')
        if filter == '' or string.find(label, filter, 1, true) or string.find(model, filter, 1, true) then
            list[#list + 1] = prop
        end
    end

    return list
end

function PropMenu.SelectProp(prop)
    if not prop or not prop.model then
        return
    end
    Carry.SpawnAndHold(prop.model, prop.category)
end

--- ox_lib Context-Menü
function PropMenu.OpenOxLib(props)
    local options = {}

    options[#options + 1] = {
        title = '🔍 ' .. Config.L('menu_search'),
        description = searchFilter ~= '' and searchFilter or Config.L('search_prompt'),
        onSelect = function()
            local input = PropMenu.NativeSearch()
            if input ~= nil then
                searchFilter = input
            end
            PropMenu.Open()
        end,
    }

    if searchFilter ~= '' then
        options[#options + 1] = {
            title = '✖ Filter löschen',
            onSelect = function()
                searchFilter = ''
                PropMenu.Open()
            end,
        }
    end

    for i, prop in ipairs(props) do
        options[#options + 1] = {
            title = prop.label,
            description = prop.model,
            onSelect = function()
                PropMenu.SelectProp(prop)
            end,
        }
    end

    exports.ox_lib:registerContext({
        id = 'md_carryprops_menu',
        title = Config.L('menu_title'),
        options = options,
    })
    exports.ox_lib:showContext('md_carryprops_menu')
end

--- qb-menu
function PropMenu.OpenQB(props)
    local menu = {
        { header = Config.L('menu_title'), isMenuHeader = true },
        {
            header = '🔍 ' .. Config.L('menu_search'),
            txt = searchFilter ~= '' and searchFilter or Config.L('search_prompt'),
            params = {
                event = 'md_carryprops:client:menuSearch',
            },
        },
    }

    if searchFilter ~= '' then
        menu[#menu + 1] = {
            header = '✖ Filter löschen',
            params = { event = 'md_carryprops:client:menuClearSearch' },
        }
    end

    for _, prop in ipairs(props) do
        menu[#menu + 1] = {
            header = prop.label,
            txt = prop.model,
            params = {
                event = 'md_carryprops:client:menuSelect',
                args = { model = prop.model, category = prop.category },
            },
        }
    end

    menu[#menu + 1] = {
        header = Config.L('menu_close'),
        params = { event = 'qb-menu:client:closeMenu' },
    }

    exports['qb-menu']:openMenu(menu)
end

--- ESX Menu Default
function PropMenu.OpenESX(props, ESX)
    local elements = {
        { label = '🔍 ' .. Config.L('menu_search') .. (searchFilter ~= '' and (' (' .. searchFilter .. ')') or ''), value = '__search__' },
    }

    if searchFilter ~= '' then
        elements[#elements + 1] = { label = '✖ Filter löschen', value = '__clear__' }
    end

    for _, prop in ipairs(props) do
        elements[#elements + 1] = {
            label = prop.label .. ' [' .. prop.model .. ']',
            value = prop.model,
            category = prop.category,
        }
    end

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'prop_menu', {
        title = Config.L('menu_title'),
        align = 'top-left',
        elements = elements,
    }, function(data, menu)
        if data.current.value == '__search__' then
            menu.close()
            local input = PropMenu.NativeSearch()
            if input ~= nil then
                searchFilter = input
            end
            PropMenu.Open()
        elseif data.current.value == '__clear__' then
            menu.close()
            searchFilter = ''
            PropMenu.Open()
        else
            menu.close()
            PropMenu.SelectProp({ model = data.current.value, category = data.current.category })
        end
    end, function(_, menu)
        menu.close()
    end)
end

--- Fallback: Native-Liste mit Pfeiltasten
function PropMenu.OpenFallback(props)
    if #props == 0 then
        Notify.Send('Keine Props gefunden.', 'error')
        return
    end

    local index = 1
    local open = true

    CreateThread(function()
        while open do
            local prop = props[index]
            local text = string.format(
                '~b~%s~w~\n%s\n~g~[~w~Enter~g~]~w~ Auswählen  ~r~[~w~Backspace~r~]~w~ Schließen\n~y~[~w~↑/↓~y~]~w~ Navigieren  ~b~[~w~S~b~]~w~ Suchen\n%s',
                Config.L('menu_title'),
                prop.label .. ' (' .. prop.model .. ')',
                searchFilter ~= '' and ('Filter: ' .. searchFilter) or ''
            )

            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(255, 255, 255, 230)
            SetTextCentre(true)
            SetTextDropshadow(1, 0, 0, 0, 200)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(text)
            EndTextCommandDisplayText(0.5, 0.35)

            if IsControlJustPressed(0, 172) then -- Pfeil hoch
                index = index - 1
                if index < 1 then index = #props end
            elseif IsControlJustPressed(0, 173) then -- Pfeil runter
                index = index + 1
                if index > #props then index = 1 end
            elseif IsControlJustPressed(0, 191) then -- Enter
                open = false
                PropMenu.SelectProp(prop)
            elseif IsControlJustPressed(0, 177) then -- Backspace
                open = false
            elseif IsControlJustPressed(0, 31) then -- S
                local input = PropMenu.NativeSearch()
                if input ~= nil then
                    searchFilter = input
                    props = PropMenu.GetFilteredProps(searchFilter)
                    index = 1
                    if #props == 0 then
                        Notify.Send('Keine Props gefunden.', 'error')
                        open = false
                    end
                end
            end

            Wait(0)
        end
    end)
end

function PropMenu.Open()
    local allowed, reason = Framework.HasMenuPermission()
    if not allowed then
        Notify.LocaleType(reason, 'error')
        return
    end

    local props = PropMenu.GetFilteredProps(searchFilter)
    local menuType = Framework.GetMenuType()

    Utils.Debug('Menü öffnen:', menuType, 'Props:', #props)

    if menuType == 'ox_lib' then
        local ok = pcall(function()
            PropMenu.OpenOxLib(props)
        end)
        if ok then return end
    elseif menuType == 'qb-menu' then
        local ok = pcall(function()
            PropMenu.OpenQB(props)
        end)
        if ok then return end
    elseif menuType == 'esx_menu' then
        local ok, esxObj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and esxObj then
            local opened = pcall(function()
                PropMenu.OpenESX(props, esxObj)
            end)
            if opened then return end
        end
    end

    PropMenu.OpenFallback(props)
end

-- QB-Menu Events
RegisterNetEvent('md_carryprops:client:menuSearch', function()
    local input = PropMenu.NativeSearch()
    if input ~= nil then
        searchFilter = input
    end
    PropMenu.Open()
end)

RegisterNetEvent('md_carryprops:client:menuClearSearch', function()
    searchFilter = ''
    PropMenu.Open()
end)

RegisterNetEvent('md_carryprops:client:menuSelect', function(args)
    if args then
        PropMenu.SelectProp(args)
    end
end)

-- Command
RegisterCommand(Config.PropMenu.command, function()
    if not Config.PropMenu.enabled then
        Notify.LocaleType('menu_disabled', 'error')
        return
    end
    PropMenu.Open()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.PropMenu.command, 'Prop-Menü öffnen')
