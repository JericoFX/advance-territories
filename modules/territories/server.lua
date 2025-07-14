local QBCore = exports['qb-core']:GetCoreObject()

local function updateTerritoryControl(zoneId, newGang)
    local territory = Territories[zoneId]
    if not territory then return end
    
    territory.control = newGang
    TriggerClientEvent('territories:client:updateControl', -1, zoneId, newGang)
    
    -- Database update
    MySQL.update('UPDATE territories SET control = ? WHERE zone_id = ?', {newGang, zoneId})
end

local function adjustTerritoryInfluence(zoneId, amount)
    local territory = Territories[zoneId]
    if not territory then return end
    
    territory.influence = math.max(territory.influence + amount, Config.Territory.control.minInfluence)
    TriggerClientEvent('territories:client:updateInfluence', -1, zoneId, territory.influence)
    
    -- Database update
    MySQL.update('UPDATE territories SET influence = ? WHERE zone_id = ?', {territory.influence, zoneId})
end

--- Check gang and police presence to update influence
local function checkGangPresence(zoneId)
    local territory = Territories[zoneId]
    if not territory then return end
    
    local controllingGang = territory.control
    
    if controllingGang == 'neutral' then return end
    
    local gangMembers = GetGangMembersInZone(zoneId, controllingGang)
    local policeMembers = GetPoliceInZone(zoneId)
    
    if gangMembers >= Config.Territory.control.minMembers then
        if policeMembers >= Config.Police.minOnDuty then
            adjustTerritoryInfluence(zoneId, -Config.Territory.control.pointsPerPolice * policeMembers)
        else
            adjustTerritoryInfluence(zoneId, Config.Territory.control.pointsPerTick)
        end
    else
        adjustTerritoryInfluence(zoneId, -Config.Territory.control.pointsPerTick)
    end
    
    local maxInfluence = Config.Territory.control.maxInfluence
    if territory.influence >= maxInfluence then
        updateTerritoryControl(zoneId, controllingGang)
    end
end

CreateThread(function()
    while true do
        Wait(Config.Territory.influenceTick)
        for zoneId, territory in pairs(Territories) do
            checkGangPresence(zoneId)
        end
    end
end)

--- On player death within a territory, update influence
RegisterNetEvent('territories:server:playerDeath', function(zoneId, killerGang)
    local territory = Territories[zoneId]
    if not territory then return end
    
    if territory.control ~= killerGang then
        adjustTerritoryInfluence(zoneId, Config.Territory.control.pointsPerKill)
    end
end)
