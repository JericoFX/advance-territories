local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:server:openStash', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local playerGang = Player.PlayerData.gang.name
    if not Utils.hasAccess(territory, playerGang) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end
    
    local stashId = ('territory_%s_%s'):format(territoryId, territory.control)
    
    exports.ox_inventory:RegisterStash(stashId, locale('territory_stash', territory.label), Config.Stash.size.slots, Config.Stash.size.weight, false)
    exports.ox_inventory:OpenInventory(src, 'stash', stashId)
end)

AddEventHandler('territories:server:transferStash', function(territoryId, oldGang, newGang)
    if not Config.Stash.transferOnCapture then return end
    
    local oldStashId = ('territory_%s_%s'):format(territoryId, oldGang)
    local newStashId = ('territory_%s_%s'):format(territoryId, newGang)
    
    -- Transfer items logic would go here
    -- This is a simplified version - you'd need to implement the actual transfer
    MySQL.update('UPDATE ox_inventory SET name = ? WHERE name = ?', {newStashId, oldStashId})
end)
