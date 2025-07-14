local QBCore = exports['qb-core']:GetCoreObject()
local playersInZones = {}

RegisterNetEvent('territories:server:enteredZone', function(zoneId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    playersInZones[src] = zoneId
    
    TriggerEvent('territories:server:playerEnteredZone', src, zoneId)
end)

RegisterNetEvent('territories:server:exitedZone', function(zoneId)
    local src = source
    playersInZones[src] = nil
    
    TriggerEvent('territories:server:playerExitedZone', src, zoneId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    playersInZones[src] = nil
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

exports('GetPlayersInZone', GetPlayersInZone)
exports('GetGangMembersInZone', GetGangMembersInZone)
exports('GetPoliceInZone', GetPoliceInZone)
exports('GetPlayerZone', GetPlayerZone)
