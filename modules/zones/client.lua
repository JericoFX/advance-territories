local Zones = {}
local currentZone = nil
local blips = {}

local function createZone(id, data)
    local territory = data
    
    if territory.zone.type == 'poly' then
        Zones[id] = lib.zones.poly({
            points = territory.zone.points,
            thickness = territory.zone.thickness,
            debug = Config.Debug,
            onEnter = function()
                currentZone = id
                TriggerEvent('territories:client:enteredZone', id)
                TriggerServerEvent('territories:server:enteredZone', id)
            end,
            onExit = function()
                currentZone = nil
                TriggerEvent('territories:client:exitedZone', id)
                TriggerServerEvent('territories:server:exitedZone', id)
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
                TriggerEvent('territories:client:enteredZone', id)
                TriggerServerEvent('territories:server:enteredZone', id)
            end,
            onExit = function()
                currentZone = nil
                TriggerEvent('territories:client:exitedZone', id)
                TriggerServerEvent('territories:server:exitedZone', id)
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
end)

RegisterNetEvent('territories:client:updateControl', function(territoryId, gang)
    local territory = Territories[territoryId]
    if territory then
        territory.control = gang
        updateBlipColor(territoryId, gang)
    end
end)

RegisterNetEvent('territories:client:updateInfluence', function(territoryId, influence)
    local territory = Territories[territoryId]
    if territory then
        territory.influence = influence
    end
end)

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
