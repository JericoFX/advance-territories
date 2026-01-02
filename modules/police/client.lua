local QBCore = exports['qb-core']:GetCoreObject()

local function startNeutralizeTerritory()
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
end

RegisterNetEvent('territories:client:neutralizeCommand', function()
    startNeutralizeTerritory()
end)

RegisterNetEvent('territories:client:policeBlip', function(coords)
    local Player = QBCore.Functions.GetPlayerData()
    if not Player.job or not Utils.isPoliceJob(Player.job.name) then return end
    
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(locale('drug_activity'))
    EndTextCommandSetBlipName(blip)
    
    SetTimeout(60000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)
