local QBCore = exports['qb-core']:GetCoreObject()

local function isValidVector(data)
    return type(data) == 'table' and type(data.x) == 'number' and type(data.y) == 'number' and type(data.z) == 'number'
end

local function isValidSize(data)
    return type(data) == 'table' and type(data.x) == 'number' and type(data.y) == 'number'
end

local function validateTerritoryData(data)
    if type(data) ~= 'table' then return false, 'invalid_data' end
    if type(data.name) ~= 'string' or data.name == '' then return false, 'invalid_name' end
    if data.type ~= 'poly' and data.type ~= 'box' then return false, 'invalid_zone_type' end

    if data.type == 'poly' then
        if type(data.points) ~= 'table' or #data.points < 3 then return false, 'invalid_zone_points' end
        for _, point in ipairs(data.points) do
            if not isValidVector(point) then return false, 'invalid_zone_points' end
        end
    end

    if data.type == 'box' then
        if not isValidVector(data.coords) or not isValidSize(data.size) then
            return false, 'invalid_zone_box'
        end
    end

    if data.capture and data.capture.point and not isValidVector(data.capture.point) then
        return false, 'invalid_capture_point'
    end

    if data.rotation and type(data.rotation) ~= 'number' then
        return false, 'invalid_rotation'
    end

    return true
end

RegisterNetEvent('territories:server:createTerritory', function(data)
    local src = source
    if not QBCore.Functions.HasPermission(src, 'admin') then return end

    local valid, errorKey = validateTerritoryData(data)
    if not valid then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale(errorKey),
            type = 'error'
        })
        return
    end
    
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
