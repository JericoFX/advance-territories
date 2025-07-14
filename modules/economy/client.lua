local QBCore = exports['qb-core']:GetCoreObject()

RegisterCommand('collect', function()
    local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
    if not currentZone then
        lib.notify({
            title = locale('error'),
            description = locale('not_in_territory'),
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('territories:server:collectIncome', currentZone)
end, false)
