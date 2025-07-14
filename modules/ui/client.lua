-- This module has been deprecated in favor of ox_lib events
-- UI functionality moved to zones module with onEnter/onExit/inside callbacks

local QBCore = exports['qb-core']:GetCoreObject()

-- Police blip for drug sales
RegisterNetEvent('territories:client:policeBlip', function(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(blip, 51)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAlpha(blip, 250)
    SetBlipAsShortRange(blip, false)
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(locale('drug_activity'))
    EndTextCommandSetBlipName(blip)
    
    SetTimeout(60000, function()
        RemoveBlip(blip)
    end)
end)
