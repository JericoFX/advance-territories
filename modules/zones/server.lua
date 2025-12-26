local QBCore = exports['qb-core']:GetCoreObject()
local sync = require 'modules.sync.server'
local playersInZones = {}
local validationInterval = 5000

local function rotatePoint(x, y, cx, cy, angle)
    local radians = math.rad(angle)
    local cosVal = math.cos(radians)
    local sinVal = math.sin(radians)
    local dx = x - cx
    local dy = y - cy
    local rx = dx * cosVal - dy * sinVal
    local ry = dx * sinVal + dy * cosVal
    return rx + cx, ry + cy
end

local function isPointInPoly(point, poly)
    local inside = false
    local j = #poly

    for i = 1, #poly do
        local xi = poly[i].x
        local yi = poly[i].y
        local xj = poly[j].x
        local yj = poly[j].y

        local intersect = false
        if (yi > point.y) ~= (yj > point.y) then
            local denom = (yj - yi)
            if denom ~= 0 then
                intersect = point.x < (xj - xi) * (point.y - yi) / denom + xi
            end
        end

        if intersect then
            inside = not inside
        end
        j = i
    end

    return inside
end

local function isPointInBox(point, center, size, rotation)
    local px = point.x
    local py = point.y
    local cx = center.x
    local cy = center.y
    local rot = rotation or 0.0

    if rot ~= 0.0 then
        px, py = rotatePoint(px, py, cx, cy, -rot)
    end

    local halfX = size.x / 2
    local halfY = size.y / 2

    return px >= (cx - halfX) and px <= (cx + halfX) and py >= (cy - halfY) and py <= (cy + halfY)
end

local function isPointInZone(point, zone)
    if not zone then return false end

    if zone.type == 'poly' and type(zone.points) == 'table' then
        return isPointInPoly(point, zone.points)
    end

    if zone.type == 'box' and zone.coords and zone.size then
        return isPointInBox(point, zone.coords, zone.size, zone.rotation or 0.0)
    end

    return false
end

local function validatePlayerInZone(playerId, zoneId)
    local territory = Territories[zoneId]
    if not territory or not territory.zone then return false end

    local ped = GetPlayerPed(playerId)
    if ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    local point = vec3(coords.x, coords.y, coords.z)

    if territory.zone.type == 'box' and territory.zone.size then
        return isPointInZone(point, territory.zone)
    end

    if territory.zone.type == 'poly' then
        return isPointInZone(point, territory.zone)
    end

    return false
end

lib.callback.register('territories:enterZone', function(source, zoneId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    if not validatePlayerInZone(source, zoneId) then
        return false
    end
    
    playersInZones[source] = zoneId
    sync.updatePlayerZone(source, zoneId)
    
    TriggerEvent('territories:server:playerEnteredZone', source, zoneId)
    return true
end)

lib.callback.register('territories:exitZone', function(source, zoneId)
    if playersInZones[source] ~= zoneId then
        return false
    end

    playersInZones[source] = nil
    sync.updatePlayerZone(source, nil)
    
    TriggerEvent('territories:server:playerExitedZone', source, zoneId)
    return true
end)

AddEventHandler('playerDropped', function()
    local src = source
    playersInZones[src] = nil
    sync.updatePlayerZone(src, nil)
end)

CreateThread(function()
    while true do
        Wait(validationInterval)

        for playerId, zoneId in pairs(playersInZones) do
            if not validatePlayerInZone(playerId, zoneId) then
                playersInZones[playerId] = nil
                sync.updatePlayerZone(playerId, nil)
                TriggerEvent('territories:server:playerExitedZone', playerId, zoneId)
            end
        end
    end
end)

---@param zoneId string
---@return table
function GetPlayersInZone(zoneId)
    local players = {}
    for playerId, zone in pairs(playersInZones) do
        if zone == zoneId then
            players[#players + 1] = playerId
        end
    end
    return players
end

---@param zoneId string
---@param gang string
---@return number
function GetGangMembersInZone(zoneId, gang)
    local count = 0
    local players = GetPlayersInZone(zoneId)
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.gang.name == gang then
            count = count + 1
        end
    end
    
    return count
end

---@param zoneId string
---@return number
function GetPoliceInZone(zoneId)
    local count = 0
    local players = GetPlayersInZone(zoneId)
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Utils.isPoliceJob(Player.PlayerData.job.name) then
            count = count + 1
        end
    end
    
    return count
end

---@param src number
---@return string|nil
function GetPlayerZone(src)
    return playersInZones[src]
end

---@param gang string
---@return table
function GetGangMembers(gang)
    local members = {}
    local players = QBCore.Functions.GetPlayers()

    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.gang.name == gang then
            local citizenid = Player.PlayerData.citizenid
            members[citizenid] = {
                source = playerId,
                citizenid = citizenid,
                grade = Player.PlayerData.gang.grade,
                isOnline = true,
                firstname = Player.PlayerData.charinfo.firstname,
                lastname = Player.PlayerData.charinfo.lastname
            }
        end
    end

    return members
end

exports('GetPlayersInZone', GetPlayersInZone)
exports('GetGangMembersInZone', GetGangMembersInZone)
exports('GetPoliceInZone', GetPoliceInZone)
exports('GetPlayerZone', GetPlayerZone)
exports('GetGangMembers', GetGangMembers)
