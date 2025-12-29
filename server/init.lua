local QBCore = exports['qb-core']:GetCoreObject()

Territories = Territories or {}
local lastDeathReport = {}

local function ensureZoneCenter(territory)
    if not territory then return end

    territory.zone = territory.zone or {}

    local center = Utils.getTerritoryCenter(territory)
    if center then
        territory.zone.center = center
    end
end

-- Database initialization
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `territories` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `zone_id` varchar(50) NOT NULL,
            `control` varchar(50) DEFAULT 'neutral',
            `influence` int(11) DEFAULT 0,
            `treasury` int(11) DEFAULT 0,
            `data` longtext DEFAULT NULL,
            `last_collected` timestamp NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `zone_id` (`zone_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `territory_vehicles` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `territory_id` varchar(50) NOT NULL,
            `gang` varchar(50) NOT NULL,
            `vehicle` longtext NOT NULL,
            `stored` tinyint(1) DEFAULT 1,
            PRIMARY KEY (`id`),
            KEY `territory_id` (`territory_id`),
            KEY `gang` (`gang`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    
    loadTerritories()
end)

function loadTerritories()
    
    local territories = MySQL.query.await('SELECT * FROM territories')
    
    for _, data in ipairs(territories) do
        -- Load dynamic territories from database
        if data.data then
            local territoryData = json.decode(data.data)
            if territoryData then
                Territories[data.zone_id] = territoryData
                Territories[data.zone_id].control = data.control
                Territories[data.zone_id].influence = data.influence
                Territories[data.zone_id].treasury = data.treasury or 0
                ensureZoneCenter(Territories[data.zone_id])
            end
        elseif Territories[data.zone_id] then
            -- Legacy support for hardcoded territories
            Territories[data.zone_id].control = data.control
            Territories[data.zone_id].influence = data.influence
            Territories[data.zone_id].treasury = data.treasury or 0
            ensureZoneCenter(Territories[data.zone_id])
        end
    end

    -- Insert missing territories
    for zoneId, territory in pairs(Territories) do
        ensureZoneCenter(territory)
        local exists = false
        for _, data in ipairs(territories) do
            if data.zone_id == zoneId then
                exists = true
                break
            end
        end
        
        if not exists then
            MySQL.insert('INSERT INTO territories (zone_id, control, influence) VALUES (?, ?, ?)', {
                zoneId, territory.control, territory.influence
            })
        end
    end
end

RegisterNetEvent('territories:server:playerDeath', function(zoneId)
    local src = source
    local victimPlayer = QBCore.Functions.GetPlayer(src)
    if not victimPlayer then return end

    local playerState = Player(src) and Player(src).state
    if not playerState or not playerState.isDead then
        return
    end

    local now = os.time()
    if lastDeathReport[src] and now - lastDeathReport[src] < 5 then
        return
    end
    lastDeathReport[src] = now

    local victimZone = GetPlayerZone(src)
    if not victimZone then return end

    local victimPed = GetPlayerPed(src)
    if victimPed == 0 then return end

    local killerPed = GetPedSourceOfDeath(victimPed)
    if killerPed == 0 then return end

    local killerServerId = NetworkGetEntityOwner(killerPed)
    if not killerServerId or killerServerId == 0 or killerServerId == src then return end

    local killerPlayer = QBCore.Functions.GetPlayer(killerServerId)
    if not killerPlayer or killerServerId == src then return end

    if GetPlayerZone(killerServerId) ~= victimZone then
        return
    end

    local killerState = Player(killerServerId) and Player(killerServerId).state
    if killerState and killerState.isDead then
        return
    end

    local victimGang = victimPlayer.PlayerData.gang.name
    local killerGang = killerPlayer.PlayerData.gang.name

    if not Utils.isValidGang(victimGang) or not Utils.isValidGang(killerGang) or victimGang == killerGang then
        return
    end

    local victimCoords = GetEntityCoords(victimPed)
    local killerCoords = GetEntityCoords(killerPed)
    if #(victimCoords - killerCoords) > 200.0 then
        return
    end

    TriggerEvent('territories:server:onPlayerDeath', victimZone, killerGang)
end)

RegisterNetEvent('territories:server:syncTerritories', function()
    local src = source
    if not Territories or not next(Territories) then return end

    for zoneId, territory in pairs(Territories) do
        TriggerClientEvent('territories:client:updateControl', src, zoneId, territory.control)
        TriggerClientEvent('territories:client:updateInfluence', src, zoneId, territory.influence)
    end
end)

-- Save territories periodically
CreateThread(function()
    while true do
        Wait(Config.Territory.saveInterval * 60000)

        if Territories and next(Territories) then
            for zoneId, territory in pairs(Territories) do
                MySQL.update('UPDATE territories SET control = ?, influence = ? WHERE zone_id = ?', {
                    territory.control, territory.influence, zoneId
                })
            end
        end
    end
end)
