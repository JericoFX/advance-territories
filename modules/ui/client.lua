local QBCore = exports['qb-core']:GetCoreObject()
local showingUI = false

CreateThread(function()
    while true do
        Wait(1000)
        
        local currentZone = GetCurrentZone()
        if currentZone and not showingUI then
            local territory = Territories[currentZone]
            if territory then
                showingUI = true
                lib.showTextUI(locale('zone_info', territory.control, territory.influence), {
                    position = 'top-center',
                    icon = 'shield-halved',
                    style = {
                        borderRadius = 0,
                        backgroundColor = '#141517',
                        color = 'white'
                    }
                })
            end
        elseif not currentZone and showingUI then
            showingUI = false
            lib.hideTextUI()
        end
    end
end)

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
