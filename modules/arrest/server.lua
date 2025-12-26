local QBCore = exports['qb-core']:GetCoreObject()

-- Configuration
local ArrestConfig = {
    influencePenalty = 5, -- Lose 5% influence per arrest
    reputationPenalty = 10 -- Territory reputation penalty
}

RegisterNetEvent('territories:server:playerArrested', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentZone = GetPlayerZone(src)
    if not currentZone or currentZone ~= territoryId then
        return
    end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local gang = Player.PlayerData.gang.name
    
    -- Only affect if arrested player's gang controls the territory
    if territory.control == gang then
        -- Reduce influence
        territory.influence = math.max(0, territory.influence - ArrestConfig.influencePenalty)
        
        -- Update all clients
        TriggerClientEvent('territories:client:updateInfluence', -1, territoryId, territory.influence)
        
        -- Notify gang members
        local gangMembers = GetGangMembers(gang)
        for citizenid, member in pairs(gangMembers) do
            if member.isOnline and member.source then
                TriggerClientEvent('ox_lib:notify', member.source, {
                    title = locale('arrest_penalty'),
                    description = locale('member_arrested_penalty', Player.PlayerData.charinfo.firstname, ArrestConfig.influencePenalty),
                    type = 'error',
                    duration = 8000
                })
            end
        end
        
        -- Update database
        MySQL.update('UPDATE territories SET influence = ? WHERE zone_id = ?', {
            territory.influence, territoryId
        })
        
        -- Log for police activity
        TriggerEvent('territories:server:logPoliceActivity', territoryId, 'arrest', gang)
    end
end)

-- Track police activity in territories
AddEventHandler('territories:server:logPoliceActivity', function(territoryId, activityType, gang)
    -- Could be used for statistics or further features
    if Config.Debug then
        print(('[TERRITORIES] Police %s in %s (Gang: %s)'):format(activityType, territoryId, gang))
    end
end)
