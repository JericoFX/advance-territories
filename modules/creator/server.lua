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
        -- Create territory data
        local territoryData = {
            label = data.name,
            control = 'neutral',
            influence = 0,
            zone = {
                type = data.type,
                points = data.points,
                thickness = data.thickness,
                coords = data.coords,
                size = data.size,
                rotation = data.rotation
            },
            capture = {
                point = data.type == 'poly' and getPolygonCenter(data.points) or data.coords,
                radius = 20.0
            },
            features = {},
            businesses = {}
        }
        
        -- Save to database
        MySQL.update('UPDATE territories SET data = ? WHERE zone_id = ?', {
            json.encode(territoryData), territoryId
        })
        
        -- Update all clients
        TriggerClientEvent('territories:client:addTerritory', -1, territoryId, territoryData)
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('success'),
            description = locale('territory_created', data.name),
            type = 'success'
        })
    end
end)

function getPolygonCenter(points)
    local x, y, z = 0, 0, 0
    for _, point in ipairs(points) do
        x = x + point.x
        y = y + point.y
        z = z + point.z
    end
    return vec3(x / #points, y / #points, z / #points)
end
