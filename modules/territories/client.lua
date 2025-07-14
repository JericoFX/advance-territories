local QBCore = exports['qb-core']:GetCoreObject()
local territoryTargets = {}

local function createTerritoryTargets()
    for territoryId, territory in pairs(Territories) do
        if territory.features then
            -- Stash Target
            if territory.features.stash and Config.Stash.enabled then
                local targetId = ('%s_stash'):format(territoryId)
                territoryTargets[targetId] = exports.ox_target:addSphereZone({
                    coords = territory.features.stash.coords,
                    radius = 1.5,
                    debug = Config.Debug,
                    options = {
                        {
                            name = targetId,
                            icon = 'fas fa-box',
                            label = locale('stash_access'),
                            canInteract = function()
                                local playerData = QBCore.Functions.GetPlayerData()
                                return Utils.hasAccess(territory, playerData.gang.name)
                            end,
                            onSelect = function()
                                TriggerEvent('territories:client:openStash', territoryId)
                            end
                        }
                    }
                })
            end
            
            -- Garage Target
            if territory.features.garage and Config.Garage.enabled then
                local targetId = ('%s_garage'):format(territoryId)
                territoryTargets[targetId] = exports.ox_target:addSphereZone({
                    coords = territory.features.garage.coords,
                    radius = 2.0,
                    debug = Config.Debug,
                    options = {
                        {
                            name = targetId,
                            icon = 'fas fa-warehouse',
                            label = locale('garage_access'),
                            canInteract = function()
                                local playerData = QBCore.Functions.GetPlayerData()
                                return Utils.hasAccess(territory, playerData.gang.name)
                            end,
                            onSelect = function()
                                TriggerEvent('territories:client:openGarage', territoryId)
                            end
                        }
                    }
                })
            end
            
            -- Process Target
            if territory.features.process and Config.Processing.enabled then
                local targetId = ('%s_process'):format(territoryId)
                territoryTargets[targetId] = exports.ox_target:addSphereZone({
                    coords = territory.features.process.coords,
                    radius = 1.5,
                    debug = Config.Debug,
                    options = {
                        {
                            name = targetId,
                            icon = 'fas fa-flask',
                            label = locale('process_drugs'),
                            canInteract = function()
                                local playerData = QBCore.Functions.GetPlayerData()
                                return Utils.hasAccess(territory, playerData.gang.name)
                            end,
                            onSelect = function()
                                TriggerEvent('territories:client:openProcess', territoryId)
                            end
                        }
                    }
                })
            end
        end
    end
end

RegisterNetEvent('territories:client:enteredZone', function(zoneId)
    local territory = Territories[zoneId]
    if not territory then return end
    
    lib.showTextUI(locale('entered_territory', territory.label), {
        position = 'top-center',
        icon = 'shield-halved',
        style = {
            borderRadius = 0,
            backgroundColor = '#141517',
            color = 'white'
        }
    })
    
    SetTimeout(3000, function()
        lib.hideTextUI()
    end)
end)

RegisterNetEvent('territories:client:exitedZone', function(zoneId)
    local territory = Territories[zoneId]
    if not territory then return end
    
    lib.notify({
        title = locale('territory'),
        description = locale('left_territory', territory.label),
        type = 'inform'
    })
end)

CreateThread(function()
    Wait(1000)
    createTerritoryTargets()
end)

-- UI Updates
CreateThread(function()
    while true do
        Wait(1000)
        
        local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
        if currentZone then
            local territory = Territories[currentZone]
            if territory then
                SendNUIMessage({
                    action = 'updateTerritory',
                    data = {
                        name = territory.label,
                        control = territory.control,
                        influence = territory.influence
                    }
                })
            end
        else
            SendNUIMessage({
                action = 'hideTerritory'
            })
        end
    end
end)
