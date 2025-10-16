local QBCore = exports['qb-core']:GetCoreObject()
local sync = require 'modules.sync.server'
local captureProgress = {}
local playersInCaptureZones = {}
local captureTimers = {}

-- Capture configuration
local CaptureConfig = {
    tickInterval = 5000, -- 5 seconds per tick
    pointsPerTick = 5, -- 5% per tick
    penaltyPerDeath = 10, -- 10% penalty per death
    requiredProgress = 100 -- 100% to capture
}

-- Track players in capture zones
lib.callback.register('territories:enterCaptureZone', function(source, territoryId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.isValidGang(gang) then return false end
    
    if not playersInCaptureZones[territoryId] then
        playersInCaptureZones[territoryId] = {}
    end
    
    playersInCaptureZones[territoryId][source] = gang
    checkCaptureConditions(territoryId)
    return true
end)

lib.callback.register('territories:exitCaptureZone', function(source, territoryId)
    if playersInCaptureZones[territoryId] then
        playersInCaptureZones[territoryId][source] = nil
    end
    checkCaptureConditions(territoryId)
    return true
end)

function checkCaptureConditions(territoryId)
    local territory = Territories[territoryId]
    if not territory then return end
    
    -- Count gangs in zone
    local gangCounts = {}
    if playersInCaptureZones[territoryId] then
        for playerId, gang in pairs(playersInCaptureZones[territoryId]) do
            if Utils.isValidGang(gang) then
                gangCounts[gang] = (gangCounts[gang] or 0) + 1
            end
        end
    end
    
    -- Find dominant gang
    local dominantGang = nil
    local maxCount = 0
    
    for gang, count in pairs(gangCounts) do
        if count >= Config.Territory.control.minMembers and count > maxCount then
            dominantGang = gang
            maxCount = count
        end
    end
    
    -- Start or update capture
    if dominantGang and dominantGang ~= territory.control then
        if not captureProgress[territoryId] or captureProgress[territoryId].gang ~= dominantGang then
            startCapture(territoryId, dominantGang)
        end
    elseif captureProgress[territoryId] then
        -- Stop capture if conditions not met
        stopCapture(territoryId)
    end
end

function startCapture(territoryId, gang)
    local territory = Territories[territoryId]
    if not territory then return end
    
    -- Check police
    local policeCount = QBCore.Functions.GetDutyCount('police')
    if policeCount < Config.Police.minOnDuty then return end
    
    captureProgress[territoryId] = {
        gang = gang,
        progress = 0,
        startTime = os.time()
    }
    
    sync.updateCaptureProgress(territoryId, gang, 0)
    
    -- Notify all
    TriggerClientEvent('territories:client:captureStarted', -1, territoryId, gang)
    
    -- Alert police
    alertPolice(territoryId)
    
    -- Start capture timer
    captureTimers[territoryId] = CreateThread(function()
        while captureProgress[territoryId] do
            Wait(CaptureConfig.tickInterval)
            updateCaptureProgress(territoryId)
        end
    end)
end

function updateCaptureProgress(territoryId)
    local capture = captureProgress[territoryId]
    if not capture then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    -- Check if gang still has members in zone
    local gangMembers = GetGangMembersInZone(territoryId, capture.gang)
    if gangMembers < Config.Territory.control.minMembers then
        stopCapture(territoryId)
        return
    end
    
    -- Update progress
    capture.progress = capture.progress + CaptureConfig.pointsPerTick
    
    -- Update GlobalState
    sync.updateCaptureProgress(territoryId, capture.gang, capture.progress)
    
    -- Check if complete
    if capture.progress >= CaptureConfig.requiredProgress then
        completeCapture(territoryId)
    end
end

function completeCapture(territoryId)
    local capture = captureProgress[territoryId]
    if not capture then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local oldGang = territory.control
    territory.control = capture.gang
    territory.influence = Config.Territory.control.maxInfluence
    
    -- Clean up
    captureProgress[territoryId] = nil
    if captureTimers[territoryId] then
        captureTimers[territoryId] = nil
    end
    
    sync.removeCaptureProgress(territoryId)
    sync.updateTerritoryControl(territoryId, capture.gang)
    sync.updateTerritoryInfluence(territoryId, territory.influence)
    
    -- Notify
    TriggerClientEvent('ox_lib:notify', -1, {
        title = locale('territory_captured'),
        description = locale('gang_captured_territory', capture.gang, territory.label),
        type = 'success',
        duration = 10000
    })
    
    -- Transfer assets
    if Config.Garage.transferOnCapture then
        TriggerEvent('territories:server:transferGarageVehicles', territoryId, oldGang, capture.gang)
    end
    
    if Config.Stash.transferOnCapture then
        TriggerEvent('territories:server:transferStash', territoryId, oldGang, capture.gang)
    end
    
    -- Rewards
    rewardCapturers(territoryId, capture.gang)
    
    -- Update database
    MySQL.update('UPDATE territories SET control = ?, influence = ? WHERE zone_id = ?', {
        capture.gang, territory.influence, territoryId
    })
end

function stopCapture(territoryId)
    captureProgress[territoryId] = nil
    if captureTimers[territoryId] then
        captureTimers[territoryId] = nil
    end
    
    sync.removeCaptureProgress(territoryId)
    
    TriggerClientEvent('ox_lib:notify', -1, {
        title = locale('capture_stopped'),
        description = locale('capture_conditions_not_met'),
        type = 'warning'
    })
end

function alertPolice(territoryId)
    local territory = Territories[territoryId]
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and Utils.isPoliceJob(player.PlayerData.job.name) then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = locale('police_alert'),
                description = locale('territory_under_attack', territory.label),
                type = 'error',
                duration = 10000
            })
        end
    end
end

function rewardCapturers(territoryId, gang)
    local gangMembers = GetGangMembers(gang)

    for citizenid, member in pairs(gangMembers) do
        if member.isOnline and member.source then
            if GetPlayerZone(member.source) == territoryId then
                local player = QBCore.Functions.GetPlayer(member.source)
                if player then
                    player.Functions.AddMoney('cash', Config.Rewards.capture.money)
                end
            end
        end
    end
end

-- Death penalty
RegisterNetEvent('territories:server:playerDeathInCapture', function(territoryId, killerGang)
    local capture = captureProgress[territoryId]
    if not capture then return end
    
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local victimGang = Player.PlayerData.gang.name
    
    -- Apply penalty if victim is from capturing gang
    if victimGang == capture.gang then
        capture.progress = math.max(0, capture.progress - CaptureConfig.penaltyPerDeath)
        
        TriggerClientEvent('ox_lib:notify', -1, {
            title = locale('capture_penalty'),
            description = locale('death_penalty_applied', CaptureConfig.penaltyPerDeath),
            type = 'error'
        })
    end
end)

-- Cleanup on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    for territoryId, players in pairs(playersInCaptureZones) do
        if players[src] then
            players[src] = nil
            checkCaptureConditions(territoryId)
        end
    end
end)
