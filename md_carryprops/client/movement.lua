Movement = {}

local function IsRestricted()
    return Carry.IsActive() or Push.IsActive() or Placement.IsActive()
end

function Movement.Restrict(ped)
    if not Config.Restrictions then
        return
    end

    if Config.Restrictions.disableSprint then
        DisableControlAction(0, 21, true) -- Sprint
        SetPlayerSprint(PlayerId(), false)
    end

    if Config.Restrictions.disableJump then
        DisableControlAction(0, 22, true) -- Jump
    end

    if IsPedRunning(ped) or IsPedSprinting(ped) then
        SetPedMaxMoveBlendRatio(ped, 1.0)
    end

    local mult = Config.Restrictions.walkSpeedMultiplier or 1.0
    if mult > 0.0 and mult < 1.0 then
        SetPedMoveRateOverride(ped, mult)
    end
end

function Movement.Reset(ped)
    SetPedMoveRateOverride(ped, 1.0)
    SetPedMaxMoveBlendRatio(ped, 3.0)
end

CreateThread(function()
    while true do
        if IsRestricted() then
            Movement.Restrict(PlayerPedId())
            Wait(0)
        else
            Movement.Reset(PlayerPedId())
            Wait(500)
        end
    end
end)
