local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:server:neutralizeTerritory', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not Utils.isPoliceJob(Player.PlayerData.job.name) then return end

    local currentZone = GetPlayerZone(src)
    if currentZone ~= territoryId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('must_be_in_territory'),
            type = 'error'
        })
        return
    end
    
    local territory = Territories[territoryId]
    if not territory or territory.control == 'neutral' then return end
    
    local policeCount = GetPoliceInZone(territoryId)
    if policeCount < 3 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('need_more_police'),
            type = 'error'
        })
        return
    end
    
    local oldGang = territory.control
    territory.control = 'neutral'
    territory.influence = 0
    
    -- Update all clients
    TriggerClientEvent('territories:client:updateControl', -1, territoryId, 'neutral')
    TriggerClientEvent('territories:client:updateInfluence', -1, territoryId, 0)
    
    -- Notify all
    TriggerClientEvent('ox_lib:notify', -1, {
        title = locale('territory_neutralized'),
        description = locale('police_neutralized_territory', territory.label),
        type = 'info',
        duration = 10000
    })
    
    -- Alert gang
    local gangMembers = GetGangMembers(oldGang)
    for citizenid, member in pairs(gangMembers) do
        if member.isOnline and member.source then
            TriggerClientEvent('ox_lib:notify', member.source, {
                title = locale('territory_lost'),
                description = locale('police_took_territory', territory.label),
                type = 'error',
                duration = 15000
            })
        end
    end
    
    -- Update database
    MySQL.update('UPDATE territories SET control = ?, influence = ? WHERE zone_id = ?', {
        'neutral', 0, territoryId
    })
end)
