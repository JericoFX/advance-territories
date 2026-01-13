lib.locale()

local missionActive = nil
local missionBlip = nil
local missionStage = nil
local missionUiShown = false

local completionRadius = 12.0

local function clearMissionUI()
    if missionUiShown then
        lib.hideTextUI()
        missionUiShown = false
    end
end

local function clearMissionBlip()
    if missionBlip then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
end

local function endMission()
    clearMissionUI()
    clearMissionBlip()
    missionActive = nil
    missionStage = nil
end

local function setMissionBlip(coords, label)
    clearMissionBlip()
    missionBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(missionBlip, 480)
    SetBlipScale(missionBlip, 0.9)
    SetBlipColour(missionBlip, 5)
    SetBlipRoute(missionBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(missionBlip)
end

local function getStageTarget()
    if not missionActive then return nil end
    local data = missionActive.data

    if missionActive.type == 'vip_escort' then
        if missionStage == 'pickup' then
            return data.pickup
        end
        return data.dropoff
    end

    if missionActive.type == 'intercept_delivery' then
        if missionStage == 'intercept' then
            return data.spawn
        end
        return data.return_point
    end

    if missionActive.type == 'npc_attack' then
        return data.location
    end

    return nil
end

local function setMissionStage(stage, coords, labelKey)
    missionStage = stage
    if coords then
        setMissionBlip(coords, locale(labelKey))
    end
end

local function completeMission()
    TriggerServerEvent('territories:server:completeMission', missionActive.type)
    endMission()
end

local function failMission(reasonKey)
    TriggerServerEvent('territories:server:failMission', missionActive.type, reasonKey)
    endMission()
end

RegisterNetEvent('territories:client:startMission', function(missionType, missionData)
    if missionActive then
        return
    end

    if not missionType or not missionData then return end

    missionActive = {
        type = missionType,
        data = missionData
    }
    if type(missionData.completionRadius) == 'number' then
        completionRadius = missionData.completionRadius
    end

    if missionType == 'vip_escort' then
        setMissionStage('pickup', missionData.pickup, 'mission_pickup')
    elseif missionType == 'intercept_delivery' then
        setMissionStage('intercept', missionData.spawn, 'mission_intercept')
    elseif missionType == 'npc_attack' then
        setMissionStage('defend', missionData.location, 'mission_defend')
    else
        endMission()
        return
    end

    CreateThread(function()
        while missionActive do
            Wait(500)

            local target = getStageTarget()
            if not target then
                endMission()
                return
            end

            local ped = PlayerPedId()
            if ped == 0 then
                clearMissionUI()
            else
                local coords = GetEntityCoords(ped)
                local targetVec = vec3(target.x, target.y, target.z)
                local distance = #(coords - targetVec)

                if distance <= completionRadius then
                    if not missionUiShown then
                        lib.showTextUI(locale('press_to_complete_mission'), {
                            position = 'left-center',
                            icon = 'bullseye'
                        })
                        missionUiShown = true
                    end

                    if IsControlJustPressed(0, 38) then
                        if missionActive.type == 'vip_escort' and missionStage == 'pickup' then
                            setMissionStage('dropoff', missionActive.data.dropoff, 'mission_dropoff')
                            clearMissionUI()
                        elseif missionActive.type == 'intercept_delivery' and missionStage == 'intercept' then
                            setMissionStage('return', missionActive.data.return_point, 'mission_return')
                            clearMissionUI()
                        else
                            completeMission()
                        end
                    end
                else
                    clearMissionUI()
                end
            end

            if missionActive and missionActive.data.timeLimit and type(missionActive.data.startedAt) == 'number' then
                local elapsed = os.time() - missionActive.data.startedAt
                if elapsed >= missionActive.data.timeLimit then
                    failMission('mission_time_expired')
                end
            end
        end
    end)
end)
