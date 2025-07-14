local QBCore = exports['qb-core']:GetCoreObject()

-- Police can neutralize territories
lib.addCommand('neutralize', {
    help = locale('neutralize_help'),
    restricted = false
}, function()
    local playerData = QBCore.Functions.GetPlayerData()
    
    if not Utils.isPoliceJob(playerData.job.name) then
        lib.notify({
            title = locale('error'),
            description = locale('not_police'),
            type = 'error'
        })
        return
    end
    
    local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
    if not currentZone then
        lib.notify({
            title = locale('error'),
            description = locale('not_in_territory'),
            type = 'error'
        })
        return
    end
    
    local territory = Territories[currentZone]
    if territory.control == 'neutral' then
        lib.notify({
            title = locale('error'),
            description = locale('already_neutral'),
            type = 'error'
        })
        return
    end
    
    -- Start neutralization progress
    if lib.progressCircle({
        duration = 30000,
        label = locale('neutralizing_territory'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@ornate_bank@hack',
            clip = 'hack_enter'
        }
    }) then
        TriggerServerEvent('territories:server:neutralizeTerritory', currentZone)
    else
        lib.notify({
            title = locale('cancelled'),
            description = locale('neutralization_cancelled'),
            type = 'error'
        })
    end
end)
