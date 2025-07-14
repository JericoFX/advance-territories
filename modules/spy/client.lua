local QBCore = exports['qb-core']:GetCoreObject()
local activeSpy = nil
local spyBlip = nil

RegisterNetEvent('territories:client:spawnSpy', function(coords, territoryId)
    local territory = Territories[territoryId]
    if not territory then return end
    
    lib.notify({
        title = locale('spy_alert'),
        description = locale('spy_detected', territory.label),
        type = 'warning',
        duration = 10000
    })
    
    -- Create spy blip
    if spyBlip then RemoveBlip(spyBlip) end
    spyBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(spyBlip, 480)
    SetBlipScale(spyBlip, 1.0)
    SetBlipColour(spyBlip, 1)
    SetBlipAsShortRange(spyBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(locale('spy_blip'))
    EndTextCommandSetBlipName(spyBlip)
    
    -- Create flashing effect
    SetBlipFlashes(spyBlip, true)
    SetBlipFlashTimer(spyBlip, 5000)
end)

RegisterNetEvent('territories:client:spyEscaped', function()
    if spyBlip then
        RemoveBlip(spyBlip)
        spyBlip = nil
    end
    
    lib.notify({
        title = locale('spy_escaped'),
        description = locale('spy_escaped_desc'),
        type = 'error'
    })
end)

RegisterNetEvent('territories:client:spyCaught', function(reward)
    if spyBlip then
        RemoveBlip(spyBlip)
        spyBlip = nil
    end
    
    lib.notify({
        title = locale('spy_caught'),
        description = locale('spy_caught_reward', reward),
        type = 'success'
    })
end)
