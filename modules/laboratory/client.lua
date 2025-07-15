local QBCore = exports['qb-core']:GetCoreObject()
local target = require 'modules.target.client'
local labEntryTargets = {}
local currentLab = nil

local labCoordinates = {
    weed = vec3(1066.0, -3183.0, -39.0),
    cocaine = vec3(1093.0, -3195.0, -39.0),
    meth = vec3(997.0, -3200.0, -36.0),
    crack = vec3(997.0, -3200.0, -36.0)
}

local function createLabEntryTargets()
    for territoryId, territory in pairs(GlobalState.territories or {}) do
        if territory.features and territory.features.labEntry then
            local entry = territory.features.labEntry
            local targetId = ('%s_lab_entry'):format(territoryId)
            
            labEntryTargets[targetId] = target.addSphereZone({
                coords = entry.coords,
                radius = 1.5,
                debug = Config.Debug,
                options = {
                    {
                        name = targetId,
                        icon = 'fas fa-door-open',
                        label = locale('enter_laboratory'),
                        canInteract = function()
                            local playerData = QBCore.Functions.GetPlayerData()
                            return Utils.hasAccess(territory, playerData.gang.name)
                        end,
                        onSelect = function()
                            enterLaboratory(territoryId, entry.drugType)
                        end
                    }
                }
            })
        end
    end
end

function enterLaboratory(territoryId, drugType)
    local playerData = QBCore.Functions.GetPlayerData()
    
    if not playerData.gang or playerData.gang.name == 'none' then
        lib.notify({
            title = locale('error'),
            description = locale('no_gang'),
            type = 'error'
        })
        return
    end
    
    local labCoords = labCoordinates[drugType]
    if not labCoords then
        lib.notify({
            title = locale('error'),
            description = locale('invalid_drug_type'),
            type = 'error'
        })
        return
    end
    
    currentLab = {
        territoryId = territoryId,
        drugType = drugType,
        exitCoords = GetEntityCoords(PlayerPedId())
    }
    
    TriggerServerEvent('territories:server:enterLaboratory', territoryId, playerData.gang.name)
    
    lib.progressBar({
        duration = 2000,
        label = locale('entering_laboratory'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@keycard@',
            clip = 'exit_door'
        }
    })
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(PlayerPedId(), labCoords.x, labCoords.y, labCoords.z)
    
    Wait(1000)
    DoScreenFadeIn(500)
    
    lib.notify({
        title = locale('laboratory_entered'),
        description = locale('laboratory_entered_desc', drugType),
        type = 'success'
    })
    
    createLabExitTarget()
end

function createLabExitTarget()
    if not currentLab then return end
    
    local exitCoords = vec3(1088.0, -3187.0, -39.0)
    
    local targetId = 'lab_exit_' .. currentLab.territoryId
    
    target.addSphereZone({
        coords = exitCoords,
        radius = 1.5,
        debug = Config.Debug,
        options = {
            {
                name = targetId,
                icon = 'fas fa-door-closed',
                label = locale('exit_laboratory'),
                onSelect = function()
                    exitLaboratory()
                end
            }
        }
    })
end

function exitLaboratory()
    if not currentLab then return end
    
    lib.progressBar({
        duration = 2000,
        label = locale('exiting_laboratory'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@heists@keycard@',
            clip = 'exit_door'
        }
    })
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(PlayerPedId(), currentLab.exitCoords.x, currentLab.exitCoords.y, currentLab.exitCoords.z)
    
    TriggerServerEvent('territories:server:exitLaboratory', currentLab.territoryId)
    
    Wait(1000)
    DoScreenFadeIn(500)
    
    lib.notify({
        title = locale('laboratory_exited'),
        description = locale('laboratory_exited_desc'),
        type = 'success'
    })
    
    currentLab = nil
end

RegisterNetEvent('territories:client:addTerritory', function(territoryId, territory)
    if territory.features and territory.features.labEntry then
        local entry = territory.features.labEntry
        local targetId = ('%s_lab_entry'):format(territoryId)
        
        labEntryTargets[targetId] = target.addSphereZone({
            coords = entry.coords,
            radius = 1.5,
            debug = Config.Debug,
            options = {
                {
                    name = targetId,
                    icon = 'fas fa-door-open',
                    label = locale('enter_laboratory'),
                    canInteract = function()
                        local playerData = QBCore.Functions.GetPlayerData()
                        return Utils.hasAccess(territory, playerData.gang.name)
                    end,
                    onSelect = function()
                        enterLaboratory(territoryId, entry.drugType)
                    end
                }
            }
        })
    end
end)

CreateThread(function()
    Wait(2000)
    createLabEntryTargets()
end)
