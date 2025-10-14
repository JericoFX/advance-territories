local QBCore = exports['qb-core']:GetCoreObject()

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
    Territories = Territories or {}

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
            end
        elseif Territories[data.zone_id] then
            -- Legacy support for hardcoded territories
            Territories[data.zone_id].control = data.control
            Territories[data.zone_id].influence = data.influence
            Territories[data.zone_id].treasury = data.treasury or 0
        end
    end
    
    -- Insert missing territories
    for zoneId, territory in pairs(Territories) do
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

RegisterNetEvent('territories:server:playerDeath', function(zoneId, killerServerId)
    local src = source
    local victimPlayer = QBCore.Functions.GetPlayer(src)
    local killerPlayer = QBCore.Functions.GetPlayer(killerServerId)
    
    if victimPlayer and killerPlayer then
        local victimGang = victimPlayer.PlayerData.gang.name
        local killerGang = killerPlayer.PlayerData.gang.name
        
        if Utils.isValidGang(victimGang) and Utils.isValidGang(killerGang) and victimGang ~= killerGang then
            TriggerEvent('territories:server:onPlayerDeath', zoneId, killerGang)
        end
    end
end)

RegisterNetEvent('territories:server:syncTerritories', function()
    local src = source
    for zoneId, territory in pairs(Territories) do
        TriggerClientEvent('territories:client:updateControl', src, zoneId, territory.control)
        TriggerClientEvent('territories:client:updateInfluence', src, zoneId, territory.influence)
    end
end)

-- Save territories periodically
CreateThread(function()
    while true do
        Wait(Config.Territory.saveInterval * 60000)
        
        for zoneId, territory in pairs(Territories) do
            MySQL.update('UPDATE territories SET control = ?, influence = ? WHERE zone_id = ?', {
                territory.control, territory.influence, zoneId
            })
        end
    end
end)
