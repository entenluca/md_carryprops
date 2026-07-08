Validation = Validation or {}

local lastNotifyAt = 0
local NOTIFY_COOLDOWN = 1500

local function GetCfg(key, fallback)
    if Config.Restrictions and Config.Restrictions[key] ~= nil then
        return Config.Restrictions[key]
    end
    return fallback
end

local function SafeCoords(coords)
    if type(coords) == 'vector3' then
        return coords
    end
    if type(coords) == 'table' and coords.x and coords.y and coords.z then
        return vector3(coords.x, coords.y, coords.z)
    end
    return nil
end

--- Raycast nach unten
local function RaycastDown(x, y, z, ignoreEntity, flags)
    local ray = StartShapeTestRay(x, y, z + 1.5, x, y, z - 5.0, flags or 17, ignoreEntity or 0, 0)
    local retval, hit, hitCoords, _, hitEntity = GetShapeTestResult(ray)
    if retval == 0 then
        return false
    end
    return hit == 1, hitEntity, hitCoords
end

--- Raycast horizontal
local function RaycastHorizontal(x, y, z, dirX, dirY, distance, ignoreEntity)
    local ray = StartShapeTestRay(
        x, y, z,
        x + dirX * distance, y + dirY * distance, z,
        1,
        ignoreEntity or 0,
        0
    )
    local retval, hit, hitCoords = GetShapeTestResult(ray)
    if retval == 0 then
        return false
    end
    return hit == 1, hitCoords
end

--- Prüft Überlappung mit anderen Objekten
local function IsOverlappingProps(entity, coords, minDim, maxDim)
    local padding = GetCfg('placementOverlapPadding', 0.2)
    local radiusX = math.max(math.abs(minDim.x), math.abs(maxDim.x)) + padding
    local radiusY = math.max(math.abs(minDim.y), math.abs(maxDim.y)) + padding
    local myBottom = coords.z + minDim.z
    local myTop = coords.z + maxDim.z

    local pool = GetGamePool('CObject')
    if not pool then
        return false
    end

    for _, obj in ipairs(pool) do
        if obj ~= entity and DoesEntityExist(obj) then
            local objCoords = GetEntityCoords(obj)
            local dx = math.abs(coords.x - objCoords.x)
            local dy = math.abs(coords.y - objCoords.y)

            if dx < radiusX + 0.5 and dy < radiusY + 0.5 then
                local oMin, oMax = GetModelDimensions(GetEntityModel(obj))
                local oBottom = objCoords.z + oMin.z
                local oTop = objCoords.z + oMax.z

                if myBottom < oTop - 0.05 and myTop > oBottom + 0.05 then
                    return true
                end
            end
        end
    end

    return false
end

--- Prüft ob das Objekt auf einem anderen Prop stehen würde
local function IsStackedOnProp(entity, coords, minDim, maxDim)
    local hit, hitEntity, hitCoords = RaycastDown(
        coords.x, coords.y, coords.z + (maxDim.z - minDim.z) + 0.5,
        entity,
        16
    )

    if hit and hitEntity and hitEntity ~= 0 and hitEntity ~= entity and GetEntityType(hitEntity) == 3 then
        local groundZ = Utils.GetGroundZ(coords.x, coords.y, coords.z)
        if hitCoords and hitCoords.z > groundZ + 0.12 then
            return true
        end
    end

    return false
end

--- Prüft Wandnähe / Platzierung in Wänden
local function IsTooCloseToWall(entity, coords, heading, minDim, maxDim)
    local wallDist = GetCfg('wallCheckDistance', 0.35)
    local checkRadius = math.max(
        math.abs(maxDim.x - minDim.x),
        math.abs(maxDim.y - minDim.y)
    ) * 0.5
    local midZ = coords.z + (maxDim.z + minDim.z) * 0.5
    local rad = math.rad(heading or 0.0)

    local directions = {
        { math.sin(rad), -math.cos(rad) },
        { -math.sin(rad), math.cos(rad) },
        { math.cos(rad), math.sin(rad) },
        { -math.cos(rad), -math.sin(rad) },
    }

    local closeHits = 0
    local castDist = checkRadius + wallDist

    for _, dir in ipairs(directions) do
        local hit, hitPos = RaycastHorizontal(coords.x, coords.y, midZ, dir[1], dir[2], castDist, entity)
        if hit and hitPos then
            local dist = #(vector3(coords.x, coords.y, midZ) - hitPos)
            if dist < checkRadius + wallDist * 0.6 then
                return true
            end
            if dist < wallDist then
                closeHits = closeHits + 1
            end
        end
    end

    return closeHits >= 2
end

function Validation.CanPlace(entity, coords, heading)
    if not GetCfg('validatePlacement', true) then
        return true
    end

    if not entity or not DoesEntityExist(entity) then
        return false, 'placement_invalid'
    end

    local safeCoords = SafeCoords(coords)
    if not safeCoords then
        return false, 'placement_invalid'
    end

    local model = GetEntityModel(entity)
    if not model or model == 0 then
        return false, 'placement_invalid'
    end

    local minDim, maxDim = GetModelDimensions(model)
    if not minDim or not maxDim then
        return true
    end

    if IsOverlappingProps(entity, safeCoords, minDim, maxDim) then
        return false, 'placement_blocked_prop'
    end

    if IsStackedOnProp(entity, safeCoords, minDim, maxDim) then
        return false, 'placement_blocked_prop'
    end

    if IsTooCloseToWall(entity, safeCoords, heading, minDim, maxDim) then
        return false, 'placement_blocked_wall'
    end

    return true
end

function Validation.NotifyBlocked(reason)
    local now = GetGameTimer()
    if now - lastNotifyAt < NOTIFY_COOLDOWN then
        return
    end
    lastNotifyAt = now

    if Notify and Notify.LocaleType then
        Notify.LocaleType(reason or 'placement_invalid', 'error')
    end
end

function Validation.TryPlace(entity, coords, heading)
    local ok, canPlace, reason = pcall(function()
        return Validation.CanPlace(entity, coords, heading)
    end)

    if not ok then
        Utils.Debug('Validation.TryPlace Fehler:', canPlace)
        return true
    end

    if not canPlace then
        Validation.NotifyBlocked(reason)
        return false
    end

    return true
end
