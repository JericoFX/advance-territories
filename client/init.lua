local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    lib.locale()
    TriggerServerEvent('territories:server:syncTerritories')
end)

-- Variable to track current zone
local currentZone = nil

RegisterNetEvent('territories:client:enteredZone', function(zoneId)
    currentZone = zoneId
end)

RegisterNetEvent('territories:client:exitedZone', function(zoneId)
    currentZone = nil
end)

-- Monitor death using statebags
AddStateBagChangeHandler('isDead', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    if value and currentZone then
        local killerPed = GetPedSourceOfDeath(PlayerPedId())
        if killerPed and IsEntityAPed(killerPed) and IsPedAPlayer(killerPed) then
            local killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(killerPed))
            TriggerServerEvent('territories:server:playerDeath', currentZone, killerServerId)
            
            -- Check if in capture zone for penalty
            local territory = Territories[currentZone]
            if territory and territory.capture then
                local coords = GetEntityCoords(PlayerPedId())
                if #(coords - territory.capture.point) <= territory.capture.radius then
                    TriggerServerEvent('territories:server:playerDeathInCapture', currentZone)
                end
            end
        end
    end
end)

-- Sync territories on resource start
CreateThread(function()
    TriggerServerEvent('territories:server:syncTerritories')
end)
