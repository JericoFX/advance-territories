local Zones = {}
local currentZone = nil
local blips = {}
local sync = require 'modules.sync.client'
local uiShown = false

local function showTerritoryUI(territory)
    if not uiShown then
        uiShown = true
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
end

local function hideTerritoryUI()
    if uiShown then
        uiShown = false
        lib.hideTextUI()
    end
end

local function createZone(id, data)
    local territory = data
    
    if territory.zone.type == 'poly' then
        Zones[id] = lib.zones.poly({
            points = territory.zone.points,
            thickness = territory.zone.thickness,
            debug = Config.Debug,
            onEnter = function()
                currentZone = id
                showTerritoryUI(territory)
                TriggerEvent('territories:client:enteredZone', id)
                lib.callback('territories:enterZone', false, function(success)
                    if not success then
                        currentZone = nil
                    end
                end, id)
            end,
            onExit = function()
                currentZone = nil
                hideTerritoryUI()
                TriggerEvent('territories:client:exitedZone', id)
                lib.callback('territories:exitZone', false, function(success)
                end, id)
            end,
            inside = function()
                if uiShown and territory then
                    lib.hideTextUI()
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
                TriggerEvent('territories:client:enteredZone', id)
                lib.callback('territories:enterZone', false, function(success)
                    if not success then
                        currentZone = nil
                    end
                end, id)
            end,
            onExit = function()
                currentZone = nil
                hideTerritoryUI()
                TriggerEvent('territories:client:exitedZone', id)
                lib.callback('territories:exitZone', false, function(success)
                end, id)
            end,
            inside = function()
                if uiShown and territory then
                    lib.hideTextUI()
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
            end
        })
    end
end

local function createBlip(id, data)
    if not Config.Blips.enabled then return end
    
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
