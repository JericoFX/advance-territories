local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:server:createTerritory', function(data)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end
    
    local territoryId = ('%s_%s'):format(data.name:lower():gsub(' ', '_'), os.time())

    -- Create territory in database
    local id = MySQL.insert.await('INSERT INTO territories (zone_id, control, influence) VALUES (?, ?, ?)', {
        territoryId, 'neutral', 0
    })

    if id then
        local tempTerritory = {
            zone = {
                type = data.type,
                points = data.points,
                coords = data.coords
            }
        }

        local defaultCenter = Utils.getTerritoryCenter(tempTerritory) or data.coords

        -- Create territory data
        local territoryData = {
            label = data.name,
            control = 'neutral',
            influence = 0,
            drugs = data.drugs or {},
            zone = {
                type = data.type,
                points = data.points,
                thickness = data.thickness,
                coords = data.coords,
                size = data.size,
                rotation = data.rotation
            },
            capture = {
                point = data.capture and data.capture.point or defaultCenter,
                radius = data.capture and data.capture.radius or 20.0
            },
            features = data.features or {},
            businesses = data.businesses or {}
        }

        territoryData.zone.center = Utils.getTerritoryCenter(territoryData) or territoryData.capture.point or data.coords

        -- Save to database
        MySQL.update('UPDATE territories SET data = ? WHERE zone_id = ?', {
            json.encode(territoryData), territoryId
        })
        
        Territories[territoryId] = territoryData

        -- Update GlobalState
        local territories = GlobalState.territories or {}
        territories[territoryId] = territoryData
        GlobalState.territories = territories
        
        -- Update all clients
        TriggerClientEvent('territories:client:addTerritory', -1, territoryId, territoryData)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('success'),
            description = locale('territory_created', data.name),
            type = 'success'
        })
    end
end)
