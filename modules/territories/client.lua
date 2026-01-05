local QBCore = exports['qb-core']:GetCoreObject()
local target = require 'modules.target.client'
local territoryTargets = {}

local function removeTarget(targetId)
    if territoryTargets[targetId] then
        target.removeZone(territoryTargets[targetId])
        territoryTargets[targetId] = nil
    end
end

local function createTargetsForTerritory(territoryId, territory)
    if not territory or not territory.features then return end

    -- Stash Target
    if territory.features.stash and Config.Stash.enabled then
        local targetId = ('%s_stash'):format(territoryId)
        removeTarget(targetId)
        territoryTargets[targetId] = target.addSphereZone({
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
        removeTarget(targetId)
        territoryTargets[targetId] = target.addSphereZone({
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
        removeTarget(targetId)
        territoryTargets[targetId] = target.addSphereZone({
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

local function createTerritoryTargets()
    for territoryId, territory in pairs(Territories) do
        createTargetsForTerritory(territoryId, territory)
    end
end

-- Zone enter/exit notifications are handled in zones module

-- Create targets immediately when module loads
CreateThread(function()
    createTerritoryTargets()
end)

-- UI is handled by ox_lib in zones module

RegisterNetEvent('territories:client:addTerritory', function(territoryId, territoryData)
    Territories[territoryId] = territoryData
    createTargetsForTerritory(territoryId, territoryData)
end)
