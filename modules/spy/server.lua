local QBCore = exports['qb-core']:GetCoreObject()
local activeSpies = {}

-- Spy system configuration
local SpyConfig = {
    spawnChance = 5, -- % per check
    checkInterval = 300000, -- 5 minutes
    maxDuration = 600000, -- 10 minutes
    successReward = 2500,
    influenceLoss = 10
}

CreateThread(function()
    while true do
        Wait(SpyConfig.checkInterval)
        
        for territoryId, territory in pairs(Territories) do
            if territory.control ~= 'neutral' and not activeSpies[territoryId] then
                local chance = math.random(1, 100)
                
                if chance <= SpyConfig.spawnChance then
                    spawnSpy(territoryId)
                end
            end
        end
    end
end)

function spawnSpy(territoryId)
    local territory = Territories[territoryId]
    if not territory then return end
    
    -- Get random position in territory
    local spyPos = getRandomPositionInTerritory(territoryId)
    if not spyPos then return end
    
    activeSpies[territoryId] = {
        position = spyPos,
        startTime = os.time(),
        caught = false
    }
    
    -- Notify gang members
    local gangMembers = QBCore.Functions.GetGangMembers(territory.control)
    for citizenid, member in pairs(gangMembers) do
        if member.isOnline then
            local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if player then
                TriggerClientEvent('territories:client:spawnSpy', player.PlayerData.source, spyPos, territoryId)
            end
        end
    end
    
    -- Set timer for spy escape
    SetTimeout(SpyConfig.maxDuration, function()
        if activeSpies[territoryId] and not activeSpies[territoryId].caught then
            spyEscaped(territoryId)
        end
    end)
end

function spyEscaped(territoryId)
    local territory = Territories[territoryId]
    if not territory then return end
    
    activeSpies[territoryId] = nil
    
    -- Reduce influence
    territory.influence = math.max(0, territory.influence - SpyConfig.influenceLoss)
    TriggerClientEvent('territories:client:updateInfluence', -1, territoryId, territory.influence)
    
    -- Notify gang
    local gangMembers = QBCore.Functions.GetGangMembers(territory.control)
    for citizenid, member in pairs(gangMembers) do
        if member.isOnline then
            local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
            if player then
                TriggerClientEvent('territories:client:spyEscaped', player.PlayerData.source)
            end
        end
    end
    
    MySQL.update('UPDATE territories SET influence = ? WHERE zone_id = ?', {
        territory.influence, territoryId
    })
end

RegisterNetEvent('territories:server:catchSpy', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local spy = activeSpies[territoryId]
    if not spy or spy.caught then return end
    
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    
    if #(coords - spy.position) > 10.0 then return end
    
    spy.caught = true
    activeSpies[territoryId] = nil
    
    -- Give reward
    Player.Functions.AddMoney('cash', SpyConfig.successReward)
    
    -- Notify
    TriggerClientEvent('territories:client:spyCaught', src, SpyConfig.successReward)
end)

function getRandomPositionInTerritory(territoryId)
    local territory = Territories[territoryId]
    if not territory then return nil end
    
    if territory.zone.type == 'poly' then
        -- Get center of polygon
        local x, y, z = 0, 0, 0
        for _, point in ipairs(territory.zone.points) do
            x = x + point.x
            y = y + point.y  
            z = z + point.z
        end
        return vec3(x / #territory.zone.points, y / #territory.zone.points, z / #territory.zone.points)
    elseif territory.zone.type == 'box' then
        return territory.zone.coords
    end
    
    return nil
end
