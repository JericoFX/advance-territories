local Zones = {}
local currentZone = nil
local blips = {}
local sync = require 'modules.sync.client'
local uiShown = false
local lastZoneInfo = nil

local textUiOptions = {
    position = 'top-center',
    icon = 'shield-halved',
    style = {
        borderRadius = 0,
        backgroundColor = '#141517',
        color = 'white'
    }
}

local function showTerritoryUI(territory)
    if not territory then return end

    local zoneInfo = locale('zone_info', territory.control, territory.influence)

    if uiShown and zoneInfo == lastZoneInfo then
        return
    end

    if uiShown then
        lib.hideTextUI()
    else
        uiShown = true
    end

    lastZoneInfo = zoneInfo
    lib.showTextUI(zoneInfo, textUiOptions)
end

local function hideTerritoryUI()
    if uiShown then
        uiShown = false
        lastZoneInfo = nil
        lib.hideTextUI()
    end
end

local function createZone(id, data)
    if Zones[id] then
        Zones[id]:remove()
        Zones[id] = nil
    end

    local territory = data

    if territory.zone.type == 'poly' then
        Zones[id] = lib.zones.poly({
            points = territory.zone.points,
            thickness = territory.zone.thickness,
            debug = Config.Debug,
            onEnter = function()
                currentZone = id
                showTerritoryUI(territory)

                -- Show entry notification
                lib.notify({
                    title = locale('territory'),
                    description = locale('entered_territory', territory.label),
                    type = 'inform',
                    position = 'top',
                    duration = 3000
                })
                
                TriggerEvent('territories:client:enteredZone', id)
                lib.callback('territories:enterZone', false, function(success)
                    if not success then
                        currentZone = nil
                        hideTerritoryUI()
                    end
                end, id)
            end,
            onExit = function()
                currentZone = nil
                hideTerritoryUI()

                -- Show exit notification
                lib.notify({
                    title = locale('territory'),
                    description = locale('left_territory', territory.label),
                    type = 'inform'
                })

                TriggerEvent('territories:client:exitedZone', id)
                lib.callback('territories:exitZone', false, function(success)
                end, id)
            end,
            inside = function()
                if currentZone == id then
                    showTerritoryUI(territory)
                end
            end
        })
    elseif territory.zone.type == 'box' then
        Zones[id] = lib.zones.box({
            coords = territory.zone.coords,
            size = territory.zone.size,
            rotation = territory.zone.rotation or 0,
            debug = Config.Debug,
            onEnter = function()
                currentZone = id
                showTerritoryUI(territory)
                
                -- Show entry notification
                lib.notify({
                    title = locale('territory'),
                    description = locale('entered_territory', territory.label),
                    type = 'inform',
                    position = 'top',
                    duration = 3000
                })
                
                TriggerEvent('territories:client:enteredZone', id)
                lib.callback('territories:enterZone', false, function(success)
                    if not success then
                        currentZone = nil
                        hideTerritoryUI()
                    end
                end, id)
            end,
            onExit = function()
                currentZone = nil
                hideTerritoryUI()

                -- Show exit notification
                lib.notify({
                    title = locale('territory'),
                    description = locale('left_territory', territory.label),
                    type = 'inform'
                })

                TriggerEvent('territories:client:exitedZone', id)
                lib.callback('territories:exitZone', false, function(success)
                end, id)
            end,
            inside = function()
                if currentZone == id then
                    showTerritoryUI(territory)
                end
            end
        })
    end
end

local function createBlip(id, data)
    if not Config.Blips.enabled then return end

    if blips[id] then
        RemoveBlip(blips[id])
        blips[id] = nil
    end

    local blip = AddBlipForCoord(data.blip.coords.x, data.blip.coords.y, data.blip.coords.z)

    SetBlipSprite(blip, data.blip.sprite or Config.Blips.sprite)
    SetBlipScale(blip, data.blip.scale or Config.Blips.scale)
    SetBlipColour(blip, Utils.getBlipColor(data.control))
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label)
    EndTextCommandSetBlipName(blip)
    
    blips[id] = blip
end

local function updateBlipColor(id, gang)
    if blips[id] then
        SetBlipColour(blips[id], Utils.getBlipColor(gang))
    end
end

CreateThread(function()
    for id, territory in pairs(Territories) do
        createZone(id, territory)
        createBlip(id, territory)
    end
    sync.setBlips(blips)
    sync.requestTerritoriesState()
end)

RegisterNetEvent('territories:client:addTerritory', function(territoryId, territoryData)
    Territories[territoryId] = territoryData
    createZone(territoryId, territoryData)
    createBlip(territoryId, territoryData)
    sync.setBlips(blips)
    sync.requestTerritoriesState()
end)

-- State updates are now handled by GlobalState in sync module

-- Global functions for internal use
function GetCurrentZone()
    return currentZone
end

function GetZoneData(id)
    return Territories[id]
end

function IsInZone(id)
    return currentZone == id
end

exports('getCurrentZone', function()
    return currentZone
end)
