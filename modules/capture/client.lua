local sync = require 'modules.sync.client'
local capturePoints = {}
local captureTimers = {}
local activeCapture = nil
local activeCaptureProgress = 0
local activeCaptureTerritoryLabel = nil

local function getProgressColor(progress)
    if progress >= 75 then
        return 46, 204, 113
    elseif progress >= 50 then
        return 241, 196, 15
    elseif progress >= 25 then
        return 230, 126, 34
    end
    return 231, 76, 60
end

local function drawCaptureText()
    if not activeCapture or not activeCaptureTerritoryLabel then return end

    local percent = math.min(math.max(activeCaptureProgress or 0, 0), 100)
    local r, g, b = getProgressColor(percent)

    SetTextFont(4)
    SetTextScale(0.6, 0.6)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(255, 255, 255, 255)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(activeCaptureTerritoryLabel)
    EndTextCommandDisplayText(0.5, 0.06)

    SetTextFont(4)
    SetTextScale(0.55, 0.55)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(r, g, b, 255)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(('%d%%'):format(percent))
    EndTextCommandDisplayText(0.5, 0.09)
end

CreateThread(function()
    while true do
        if activeCapture then
            drawCaptureText()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

local function createCapturePoint(territoryId, territory)
    if not territory.capture then return end

    local pointId = ('%s_capture'):format(territoryId)

    if capturePoints[pointId] then
        capturePoints[pointId]:remove()
        capturePoints[pointId] = nil
    end

    capturePoints[pointId] = lib.points.new({
        coords = territory.capture.point,
        distance = territory.capture.radius,
        onEnter = function()
            lib.callback('territories:enterCaptureZone', false, function(success)
                if success then
                    TriggerEvent('territories:client:inCaptureZone', territoryId)
                end
            end, territoryId)
        end,
        onExit = function()
            lib.callback('territories:exitCaptureZone', false, function(success)
                if success then
                    TriggerEvent('territories:client:leftCaptureZone', territoryId)
                end
            end, territoryId)
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
    local remainingTime = duration
    activeCaptureProgress = 0
    activeCaptureTerritoryLabel = territory and territory.label or nil
    
    lib.notify({
        title = locale('territory_capture'),
        description = locale('capture_started_time', territory.label, math.ceil(duration / 60000)),
        type = 'inform'
    })
    
    CreateThread(function()
        while remainingTime > 0 and activeCapture == territoryId do
            Wait(1000)  -- Wait 1 second
            remainingTime = remainingTime - 1000
        end

        if activeCapture == territoryId then
            lib.notify({
                title = locale('territory_capture'),
                description = locale('capture_duration_ended'),
                type = 'inform'
            })
        end

        activeCapture = nil
        activeCaptureProgress = 0
        activeCaptureTerritoryLabel = nil
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

RegisterNetEvent('territories:client:captureProgressUpdated', function(territoryId, data)
    local territory = Territories[territoryId]
    if not territory then return end
    
    if not data then return end

    activeCapture = territoryId
    activeCaptureProgress = data.progress or 0
    activeCaptureTerritoryLabel = territory.label
end)

RegisterNetEvent('territories:client:addTerritory', function(territoryId, territoryData)
    Territories[territoryId] = territoryData
    createCapturePoint(territoryId, territoryData)
end)

RegisterNetEvent('territories:client:captureProgressRemoved', function(territoryId)
    if activeCapture == territoryId then
        activeCapture = nil
        activeCaptureProgress = 0
        activeCaptureTerritoryLabel = nil
    end
end)

CreateThread(function()
    Wait(1000)
    createCapturePoints()
    sync.requestCaptureState()
end)
