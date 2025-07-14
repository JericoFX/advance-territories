local QBCore = exports['qb-core']:GetCoreObject()

lib.addCommand('territories', {
    help = 'Admin menu for territories',
    restricted = 'group.admin'
}, function(source)
    local territories = {}
    
    for zoneId, territory in pairs(Territories) do
        territories[zoneId] = {
            label = territory.label,
            control = territory.control,
            influence = territory.influence,
            treasury = territory.treasury or 0
        }
    end
    
    TriggerClientEvent('territories:client:adminMenu', source, territories)
end)

RegisterNetEvent('territories:server:adminUpdate', function(zoneId, control, influence)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end
    
    local territory = Territories[zoneId]
    if not territory then return end
    
    territory.control = control
    territory.influence = influence
    
    -- Update all clients
    TriggerClientEvent('territories:client:updateControl', -1, zoneId, control)
    TriggerClientEvent('territories:client:updateInfluence', -1, zoneId, influence)
    
    -- Update database
    MySQL.update('UPDATE territories SET control = ?, influence = ? WHERE zone_id = ?', {
        control, influence, zoneId
    })
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('territory_updated'),
        type = 'success'
    })
end)
