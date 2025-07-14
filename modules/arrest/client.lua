local QBCore = exports['qb-core']:GetCoreObject()
local currentZone = nil
local wasArrested = false

-- Get current zone from zones module
RegisterNetEvent('territories:client:enteredZone', function(zoneId)
    currentZone = zoneId
end)

RegisterNetEvent('territories:client:exitedZone', function(zoneId)
    currentZone = nil
end)

-- Monitor arrest status using statebags
AddStateBagChangeHandler('ishandcuffed', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    if value and not wasArrested then
        wasArrested = true
        if currentZone then
            TriggerServerEvent('territories:server:playerArrested', currentZone)
        end
    elseif not value then
        wasArrested = false
    end
end)
