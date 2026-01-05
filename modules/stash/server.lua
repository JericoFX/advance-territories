local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:server:openStash', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Config.Stash.enabled then return end

    if GetPlayerZone(src) ~= territoryId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('must_be_in_territory'),
            type = 'error'
        })
        return
    end
    
    local territory = Territories[territoryId]
    if not territory then return end

    local stashCoords = territory.features and territory.features.stash and territory.features.stash.coords or nil
    if stashCoords then
        local ped = GetPlayerPed(src)
        if ped == 0 then return end
        local coords = GetEntityCoords(ped)
        if #(coords - stashCoords) > Config.Interact.distance then
            TriggerClientEvent('ox_lib:notify', src, {
                title = locale('error'),
                description = locale('no_access'),
                type = 'error'
            })
            return
        end
    end
    
    local playerGang = Player.PlayerData.gang.name
    if Config.Stash.requireControl then
        if territory.control ~= playerGang then
            TriggerClientEvent('ox_lib:notify', src, {
                title = locale('error'),
                description = locale('no_access'),
                type = 'error'
            })
            return
        end
    elseif not Utils.hasAccess(territory, playerGang) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end
    
    local stashId = ('territory_%s_%s'):format(territoryId, territory.control)
    
    exports.ox_inventory:RegisterStash(stashId, locale('territory_stash', territory.label), Config.Stash.size.slots, Config.Stash.size.weight, false)
    TriggerClientEvent('ox_inventory:openInventory', src, 'stash', stashId)
end)

AddEventHandler('territories:server:transferStash', function(territoryId, oldGang, newGang)
    if not Config.Stash.transferOnCapture then return end
    
    local oldStashId = ('territory_%s_%s'):format(territoryId, oldGang)
    local newStashId = ('territory_%s_%s'):format(territoryId, newGang)
    
    -- Transfer items logic would go here
    -- This is a simplified version - you'd need to implement the actual transfer
    MySQL.update('UPDATE ox_inventory SET name = ? WHERE name = ?', {newStashId, oldStashId})
end)
