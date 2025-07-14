local QBCore = exports['qb-core']:GetCoreObject()
local capturePoints = {}
local captureTimers = {}

local function createCapturePoint(territoryId, territory)
    if not territory.capture then return end
    
    local pointId = ('%s_capture'):format(territoryId)
    
    capturePoints[pointId] = lib.points.new({
        coords = territory.capture.point,
        distance = territory.capture.radius,
        onEnter = function()
            TriggerServerEvent('territories:server:enterCaptureZone', territoryId)
        end,
        onExit = function()
            TriggerServerEvent('territories:server:exitCaptureZone', territoryId)
        end
    })
end

local function createCapturePoints()
    for territoryId, territory in pairs(Territories) do
        createCapturePoint(territoryId, territory)
    end
end

RegisterNetEvent('territories:client:startCapture', function(territoryId, duration)
    activeCapture = territoryId
    local territory = Territories[territoryId]
    local ped = PlayerPedId()
    local remainingTime = duration
    
    lib.notify({
        title = locale('territory_capture'),
        description = locale('capture_started_time', territory.label, math.ceil(duration / 60000)),
        type = 'inform'
    })
    
    CreateThread(function()
        while remainingTime > 0 and activeCapture == territoryId do
            Wait(1000)  -- Wait 1 second
            remainingTime = remainingTime - 1000
            local progressPercent = math.ceil(((duration - remainingTime) / duration) * 100)
            
            -- Display progress on screen
            local gangName = QBCore.Functions.GetPlayerData().gang.label or QBCore.Functions.GetPlayerData().gang.name
            lib.showTextUI((locale('capturing_progress')):format(progressPercent, gangName), {
                position = 'top-center'
            })
        end
        
        lib.hideTextUI()  
        
        if activeCapture == territoryId then
            TriggerServerEvent('territories:server:completeCapture', territoryId)
        end
        
        activeCapture = nil
    end)
end)

RegisterNetEvent('territories:client:captureStarted', function(territoryId, gang)
    local territory = Territories[territoryId]
    
    lib.notify({
        title = locale('territory_alert'),
        description = locale('capture_started', gang, territory.label),
        type = 'warning',
        duration = 8000
    })
end)

RegisterNetEvent('territories:client:updateCaptureProgress', function(territoryId, gang, progress)
    local territory = Territories[territoryId]
    if not territory then return end
    
    if captureTimers[territoryId] then
        lib.notify({
            title = locale('capture_progress'),
            description = locale('capture_progress_update', gang, territory.label, progress),
            type = 'inform'
        })
    end
end)

RegisterNetEvent('territories:client:addTerritory', function(territoryId, territoryData)
    Territories[territoryId] = territoryData
    createCapturePoint(territoryId, territoryData)
    
    -- Create zone
    if territoryData.zone.type == 'poly' then
        lib.zones.poly({
            points = territoryData.zone.points,
            thickness = territoryData.zone.thickness,
            debug = Config.Debug,
            onEnter = function()
                TriggerEvent('territories:client:enteredZone', territoryId)
                TriggerServerEvent('territories:server:enteredZone', territoryId)
            end,
            onExit = function()
                TriggerEvent('territories:client:exitedZone', territoryId)
                TriggerServerEvent('territories:server:exitedZone', territoryId)
            end
        })
    elseif territoryData.zone.type == 'box' then
        lib.zones.box({
            coords = territoryData.zone.coords,
            size = territoryData.zone.size,
            rotation = territoryData.zone.rotation or 0,
            debug = Config.Debug,
            onEnter = function()
                TriggerEvent('territories:client:enteredZone', territoryId)
                TriggerServerEvent('territories:server:enteredZone', territoryId)
            end,
            onExit = function()
                TriggerEvent('territories:client:exitedZone', territoryId)
                TriggerServerEvent('territories:server:exitedZone', territoryId)
            end
        })
    end
end)

CreateThread(function()
    Wait(1000)
    createCapturePoints()
end)
