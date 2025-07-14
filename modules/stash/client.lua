local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:client:openStash', function(territoryId)
    local territory = Territories[territoryId]
    if not territory then return end
    
    local playerData = QBCore.Functions.GetPlayerData()
    if not Utils.hasAccess(territory, playerData.gang.name) then
        lib.notify({
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end
    
    local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
    if currentZone ~= territoryId then
        lib.notify({
            title = locale('error'),
            description = locale('not_in_territory'),
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('territories:server:openStash', territoryId)
end)
