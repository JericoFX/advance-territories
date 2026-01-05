local Zones = {}
local currentZone = nil
local blips = {}
local sync = require 'modules.sync.client'
local function getControlColor(control)
    if control == 'ballas' then
        return 160, 90, 220
    elseif control == 'vagos' then
        return 241, 196, 15
    elseif control == 'families' then
        return 46, 204, 113
    elseif control == 'lostmc' then
        return 230, 126, 34
    elseif control == 'police' then
        return 52, 152, 219
    end
    return 200, 200, 200
end

local function drawTerritoryUI(territory)
    if not territory then return end

    local label = territory.label or locale('territory')
    local info = locale('zone_info', territory.control, territory.influence)
    local r, g, b = getControlColor(territory.control)

    SetTextFont(4)
    SetTextScale(0.45, 0.45)
    SetTextOutline()
    SetTextRightJustify(true)
    SetTextWrap(0.0, 0.98)
    SetTextColour(255, 255, 255, 220)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandDisplayText(0.98, 0.93)

    SetTextFont(4)
    SetTextScale(0.42, 0.42)
    SetTextOutline()
    SetTextRightJustify(true)
    SetTextWrap(0.0, 0.98)
    SetTextColour(r, g, b, 220)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(info)
    EndTextCommandDisplayText(0.98, 0.955)
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
                lib.callback('territories:enterZone', false, function(success)
                    if not success then
                        currentZone = nil
                        return
                    end
                    currentZone = id
                    drawTerritoryUI(territory)
                    TriggerEvent('territories:client:enteredZone', id)
                end, id)
            end,
            onExit = function()
                if currentZone == id then
                    TriggerEvent('territories:client:exitedZone', id)
                    lib.callback('territories:exitZone', false, function(success)
                    end, id)
                    currentZone = nil
                end
            end,
            inside = function()
                if currentZone == id then
                    drawTerritoryUI(territory)
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
                lib.callback('territories:enterZone', false, function(success)
                    if not success then
                        currentZone = nil
                        return
                    end
                    currentZone = id
                    drawTerritoryUI(territory)
                    TriggerEvent('territories:client:enteredZone', id)
                end, id)
            end,
            onExit = function()
                if currentZone == id then
                    TriggerEvent('territories:client:exitedZone', id)
                    lib.callback('territories:exitZone', false, function(success)
                    end, id)
                    currentZone = nil
                end
            end,
            inside = function()
                if currentZone == id then
                    drawTerritoryUI(territory)
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

CreateThread(function()
    while true do
        if currentZone and Territories[currentZone] then
            drawTerritoryUI(Territories[currentZone])
            Wait(0)
        else
            Wait(500)
        end
    end
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
