Utils = {}

--- Debug-Log nur wenn Config.Debug aktiv
function Utils.Debug(...)
    if Config and Config.Debug then
        print('[^3md_carryprops^7]', ...)
    end
end

--- Model-Hash aus String oder Zahl
function Utils.GetModelHash(model)
    if type(model) == 'number' then
        return model
    end
    if type(model) == 'string' then
        return joaat(model)
    end
    return nil
end

--- Model-Name aus Hash (nur für Whitelist-Vergleich)
function Utils.GetModelName(model)
    if type(model) == 'string' then
        return string.lower(model)
    end
    return nil
end

--- Alle Model-Hashes für Target-Registrierung sammeln
function Utils.GetTargetModels()
    local models = {}
    local seen = {}

    local function add(entry)
        local hash = Utils.GetModelHash(entry)
        if hash and not seen[hash] then
            seen[hash] = true
            models[#models + 1] = hash
        end
    end

    for _, entry in ipairs(Config.AllowedProps or {}) do
        add(entry)
    end

    for _, entry in ipairs(Config.MenuProps or {}) do
        if entry.model then
            add(entry.model)
        end
    end

    return models
end

--- Prüft ob ein Model in der Whitelist ist
function Utils.IsPropAllowed(modelHash)
    if not Config.UseWhitelist then
        return true
    end

    for _, entry in ipairs(Config.AllowedProps) do
        local hash = Utils.GetModelHash(entry)
        if hash and hash == modelHash then
            return true
        end
    end

    return false
end

--- Kategorie anhand des Model-Namens ermitteln
function Utils.GetCategoryForModel(modelHash)
    local modelName = nil

    -- Versuche den internen Namen über die Config-Liste zu finden
    for _, entry in ipairs(Config.AllowedProps) do
        if Utils.GetModelHash(entry) == modelHash then
            modelName = Utils.GetModelName(entry) or string.lower(tostring(entry))
            break
        end
    end

    for _, entry in ipairs(Config.MenuProps) do
        if Utils.GetModelHash(entry.model) == modelHash then
            modelName = string.lower(entry.model)
            if entry.category then
                return entry.category
            end
            break
        end
    end

    if not modelName then
        modelName = string.lower(tostring(modelHash))
    end

    for catId, catData in pairs(Config.Categories) do
        for _, keyword in ipairs(catData.keywords) do
            if string.find(modelName, keyword, 1, true) then
                return catId
            end
        end
    end

    return Config.DefaultCategory
end

--- Interaktionsmodus für Kategorie
function Utils.GetModeForCategory(categoryId)
    local cat = Config.Categories[categoryId]
    if cat and cat.mode then
        return cat.mode
    end
    return 'carry'
end

--- Attach-Offset für Kategorie / Model
function Utils.GetAttachOffset(categoryId, modelHash)
    if modelHash and Config.ModelAttachOverrides then
        for modelName, offset in pairs(Config.ModelAttachOverrides) do
            if Utils.GetModelHash(modelName) == modelHash then
                return offset
            end
        end
    end

    return Config.AttachOffsets[categoryId] or Config.AttachOffsets.box or Config.AttachOffsets.default
end

--- Bodenhöhe sicher ermitteln
function Utils.GetGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if found then
        return groundZ
    end

    -- Fallback: mehrere Versuche mit Raycast nach unten
    for i = 1, Config.GroundSnapAttempts do
        local ray = StartShapeTestRay(x, y, z + 5.0, x, y, z - 10.0, 1, 0, 0)
        local _, hit, endCoords = GetShapeTestResult(ray)
        if hit == 1 and endCoords then
            return endCoords.z
        end
        Wait(0)
    end

    return z
end

--- Network-Control anfordern
function Utils.RequestControl(entity, timeout)
    if not DoesEntityExist(entity) then
        return false
    end

    if NetworkHasControlOfEntity(entity) then
        return true
    end

    local endTime = GetGameTimer() + (timeout or 2000)
    NetworkRequestControlOfEntity(entity)

    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < endTime do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

--- Entity sicher auf Boden platzieren und einfrieren
function Utils.SafePlaceEntity(entity, coords, heading)
    if not DoesEntityExist(entity) then
        return false
    end

    Utils.RequestControl(entity)

    local groundZ = Utils.GetGroundZ(coords.x, coords.y, coords.z)
    local finalCoords = vector3(coords.x, coords.y, groundZ)

    DetachEntity(entity, true, true)
    SetEntityCoords(entity, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false, false)
    SetEntityHeading(entity, heading or 0.0)
    PlaceObjectOnGroundProperly(entity)

    -- Finale Position nach Ground-Properly
    local placed = GetEntityCoords(entity)
    groundZ = Utils.GetGroundZ(placed.x, placed.y, placed.z)
    SetEntityCoords(entity, placed.x, placed.y, groundZ, false, false, false, false)

    SetEntityCollision(entity, true, true)
    FreezeEntityPosition(entity, true)
    SetEntityDynamic(entity, false)

    return true
end

--- Prüft ob Spieler interagieren kann
function Utils.CanPlayerInteract(ped)
    if not DoesEntityExist(ped) then
        return false
    end
    if IsEntityDead(ped) then
        return false, 'dead'
    end
    if IsPedInAnyVehicle(ped, false) then
        return false, 'in_vehicle'
    end
    return true
end

--- Raycast von Kamera
function Utils.RaycastFromCamera(distance, flags, ignoreEntity)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = Utils.RotationToDirection(camRot)
    local dest = camCoords + (dir * distance)

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        dest.x, dest.y, dest.z,
        flags or 16, -- Objects
        ignoreEntity or PlayerPedId(),
        0
    )

    local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)
    return hit == 1, entityHit, endCoords
end

function Utils.RotationToDirection(rotation)
    local radX = math.rad(rotation.x)
    local radZ = math.rad(rotation.z)
    local cosX = math.abs(math.cos(radX))

    return vector3(
        -math.sin(radZ) * cosX,
        math.cos(radZ) * cosX,
        math.sin(radX)
    )
end

--- Animation laden und abspielen
function Utils.PlayAnim(ped, dict, anim, flag)
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end

    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag or 49, 0.0, false, false, false)
        return true
    end

    return false
end

function Utils.StopAnim(ped, dict, anim)
    if dict and anim then
        StopAnimTask(ped, dict, anim, 1.0)
    else
        ClearPedTasks(ped)
    end
end

--- Model laden
function Utils.LoadModel(model)
    local hash = Utils.GetModelHash(model)
    if not hash or not IsModelValid(hash) then
        return nil
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end

    if HasModelLoaded(hash) then
        return hash
    end

    return nil
end

function Utils.UnloadModel(hash)
    if hash then
        SetModelAsNoLongerNeeded(hash)
    end
end
