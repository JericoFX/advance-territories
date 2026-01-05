local QBCore = exports['qb-core']:GetCoreObject()
local sync = require 'modules.sync.server'
local captureProgress = {}
local playersInCaptureZones = {}
local captureTimers = {}
local lastCaptureDeath = {}

-- Capture configuration
local CaptureConfig = {
    tickInterval = 5000, -- 5 seconds per tick
    pointsPerTick = 5, -- 5% per tick
    penaltyPerDeath = 10, -- 10% penalty per death
    requiredProgress = 100, -- 100% to capture
    deathCooldownSeconds = 5 -- TODO: align with design/balance requirements
}

local function getTickInterval()
    if Config.Debug then
        return 1000
    end
    return CaptureConfig.tickInterval
end

local function getPointsPerTick()
    if Config.Debug then
        return 25
    end
    return CaptureConfig.pointsPerTick
end

local function getRequiredProgress()
    return CaptureConfig.requiredProgress
end

local function isPlayerInCaptureZone(source, territoryId)
    local territory = Territories[territoryId]
    if not territory or not territory.capture then return false end
    return GetPlayerZone(source) == territoryId
end

local function cleanupCaptureZonePlayers(territoryId)
    if not playersInCaptureZones[territoryId] then return end

    for playerId, gang in pairs(playersInCaptureZones[territoryId]) do
        local playerZone = GetPlayerZone(playerId)
        if (playerZone and playerZone ~= territoryId) or not isPlayerInCaptureZone(playerId, territoryId) then
            playersInCaptureZones[territoryId][playerId] = nil
        else
            local Player = QBCore.Functions.GetPlayer(playerId)
            if not Player then
                playersInCaptureZones[territoryId][playerId] = nil
            else
                local currentGang = Player.PlayerData.gang.name
                if not Utils.isValidGang(currentGang) and Config.Debug then
                    currentGang = 'neutral'
                end
                playersInCaptureZones[territoryId][playerId] = currentGang
            end
        end
    end

    if not next(playersInCaptureZones[territoryId]) then
        playersInCaptureZones[territoryId] = nil
    end
end

CreateThread(function()
    while true do
        Wait(getTickInterval())
        for territoryId, _ in pairs(playersInCaptureZones) do
            cleanupCaptureZonePlayers(territoryId)
            checkCaptureConditions(territoryId)
        end
    end
end)

-- Track players in capture zones
lib.callback.register('territories:enterCaptureZone', function(source, territoryId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    if Config.Debug then
        print(('[CAPTURE] enterCaptureZone src=%s territory=%s'):format(source, tostring(territoryId)))
    end

    if not isPlayerInCaptureZone(source, territoryId) then
        if Config.Debug then
            print(('[CAPTURE] enterCaptureZone rejected (not in zone) src=%s territory=%s'):format(source, tostring(territoryId)))
        end
        return false
    end

    local gang = Player.PlayerData.gang.name
    if not Utils.isValidGang(gang) then
        if Config.Debug then
            gang = 'neutral'
        else
            return false
        end
    end
    
    if not playersInCaptureZones[territoryId] then
        playersInCaptureZones[territoryId] = {}
    end
    
    playersInCaptureZones[territoryId][source] = gang
    cleanupCaptureZonePlayers(territoryId)
    checkCaptureConditions(territoryId)
    if Config.Debug then
        print(('[CAPTURE] enterCaptureZone ok src=%s territory=%s gang=%s'):format(source, tostring(territoryId), tostring(gang)))
    end
    return true
end)

lib.callback.register('territories:exitCaptureZone', function(source, territoryId)
    if Config.Debug then
        print(('[CAPTURE] exitCaptureZone src=%s territory=%s'):format(source, tostring(territoryId)))
    end
    if playersInCaptureZones[territoryId] then
        playersInCaptureZones[territoryId][source] = nil
        if not next(playersInCaptureZones[territoryId]) then
            playersInCaptureZones[territoryId] = nil
        end
    end
    cleanupCaptureZonePlayers(territoryId)
    checkCaptureConditions(territoryId)
    return true
end)

function checkCaptureConditions(territoryId)
    local territory = Territories[territoryId]
    if not territory then return end

    cleanupCaptureZonePlayers(territoryId)
    
    -- Count gangs in zone
    local gangCounts = {}
    if playersInCaptureZones[territoryId] then
        for playerId, gang in pairs(playersInCaptureZones[territoryId]) do
            if Utils.isValidGang(gang) or Config.Debug then
                gangCounts[gang] = (gangCounts[gang] or 0) + 1
            end
        end
    end
    
    -- Find dominant gang
    local dominantGang = nil
    local maxCount = 0
    
    local minMembers = Config.Territory.control.minMembers
    if Config.Debug and minMembers > 1 then
        minMembers = 1
    end

    for gang, count in pairs(gangCounts) do
        if count >= minMembers and count > maxCount then
            dominantGang = gang
            maxCount = count
        end
    end
    if Config.Debug then
        print(('[CAPTURE] checkCaptureConditions territory=%s dominant=%s maxCount=%s minMembers=%s control=%s'):format(
            tostring(territoryId), tostring(dominantGang), tostring(maxCount), tostring(minMembers), tostring(territory.control)
        ))
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
    if Config.Debug then
        print(('[CAPTURE] startCapture territory=%s gang=%s'):format(tostring(territoryId), tostring(gang)))
    end

    -- Check police (skip in debug mode)
    if not Config.Debug then
        local policeCount = Utils.getPoliceCount()
        if policeCount < Config.Police.minOnDuty then
            if playersInCaptureZones[territoryId] then
                for playerId, playerGang in pairs(playersInCaptureZones[territoryId]) do
                    if playerGang == gang then
                        TriggerClientEvent('ox_lib:notify', playerId, {
                            title = locale('error'),
                            description = locale('need_more_police'),
                            type = 'error'
                        })
                    end
                end
            end
            return
        end
    end
    
    captureProgress[territoryId] = {
        gang = gang,
        progress = 0,
        startTime = os.time()
    }
    
    sync.updateCaptureProgress(territoryId, gang, 0)

    local duration = math.floor((getRequiredProgress() / getPointsPerTick()) * getTickInterval())
    TriggerClientEvent('territories:client:startCapture', -1, territoryId, duration)
    
    -- Notify all
    TriggerClientEvent('territories:client:captureStarted', -1, territoryId, gang)
    
    -- Alert police
    alertPolice(territoryId)
    
    -- Start capture timer
    captureTimers[territoryId] = CreateThread(function()
        while captureProgress[territoryId] do
            Wait(getTickInterval())
            updateCaptureProgress(territoryId)
        end
    end)
end

function updateCaptureProgress(territoryId)
    local capture = captureProgress[territoryId]
    if not capture then return end

    local territory = Territories[territoryId]
    if not territory then return end

    cleanupCaptureZonePlayers(territoryId)
    
    -- Check if gang still has members in zone
    local minMembers = Config.Territory.control.minMembers
    if Config.Debug and minMembers > 1 then
        minMembers = 1
    end

    local gangMembers = GetGangMembersInZone(territoryId, capture.gang)
    if gangMembers < minMembers then
        if Config.Debug then
            print(('[CAPTURE] updateCaptureProgress stop (members=%s min=%s) territory=%s gang=%s'):format(
                tostring(gangMembers), tostring(minMembers), tostring(territoryId), tostring(capture.gang)
            ))
        end
        stopCapture(territoryId)
        return
    end

    -- Update progress
    capture.progress = capture.progress + getPointsPerTick()
    if Config.Debug then
        print(('[CAPTURE] progress territory=%s gang=%s progress=%s'):format(
            tostring(territoryId), tostring(capture.gang), tostring(capture.progress)
        ))
    end
    
    -- Update GlobalState
    sync.updateCaptureProgress(territoryId, capture.gang, capture.progress)
    
    -- Check if complete
    if capture.progress >= getRequiredProgress() then
        completeCapture(territoryId)
    end
end

function completeCapture(territoryId)
    local capture = captureProgress[territoryId]
    if not capture then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local oldGang = territory.control
    local newGang = capture.gang
    if Config.Debug and not Utils.isValidGang(newGang) then
        newGang = 'neutral'
    end
    territory.control = newGang
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
    if Config.Debug then
        print(('[CAPTURE] stopCapture territory=%s'):format(tostring(territoryId)))
    end
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
        if player and player.PlayerData and player.PlayerData.job then
            local job = player.PlayerData.job
            if Utils.isPoliceJob(job.name) and (job.onduty == nil or job.onduty) then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = locale('police_alert'),
                description = locale('territory_under_attack', territory.label),
                type = 'error',
                duration = 10000
            })
            end
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
RegisterNetEvent('territories:server:playerDeathInCapture', function(territoryId)
    local capture = captureProgress[territoryId]
    if not capture then return end
    
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local playerState = Player(src) and Player(src).state
    if not playerState or not playerState.isDead then
        return
    end

    local now = os.time()
    if lastCaptureDeath[src] and now - lastCaptureDeath[src] < CaptureConfig.deathCooldownSeconds then
        return
    end
    lastCaptureDeath[src] = now

    if not isPlayerInCaptureZone(src, territoryId) then
        return
    end
    
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
            if not next(players) then
                playersInCaptureZones[territoryId] = nil
            end
            checkCaptureConditions(territoryId)
        end
    end
end)
