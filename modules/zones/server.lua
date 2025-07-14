local QBCore = exports['qb-core']:GetCoreObject()
local sync = require 'modules.sync.server'
local playersInZones = {}

lib.callback.register('territories:enterZone', function(source, zoneId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    playersInZones[source] = zoneId
    sync.updatePlayerZone(source, zoneId)
    
    TriggerEvent('territories:server:playerEnteredZone', source, zoneId)
    return true
end)

lib.callback.register('territories:exitZone', function(source, zoneId)
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
            members[#members + 1] = {
                source = playerId,
                citizenid = Player.PlayerData.citizenid,
                grade = Player.PlayerData.gang.grade.level,
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
