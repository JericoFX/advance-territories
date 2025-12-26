local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:server:getGarageVehicles', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.hasAccess(territory, gang) then return end
    
    local vehicles = MySQL.query.await('SELECT * FROM territory_vehicles WHERE territory_id = ? AND gang = ?', {
        territoryId, gang
    })
    
    TriggerClientEvent('territories:client:showGarageMenu', src, vehicles or {}, territoryId)
end)

RegisterNetEvent('territories:server:storeVehicle', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.hasAccess(territory, gang) then return end
    
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(src), false)
    if vehicle == 0 then return end

    if GetPedInVehicleSeat(vehicle, -1) ~= GetPlayerPed(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('must_be_driver'),
            type = 'error'
        })
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local props = lib.getVehicleProperties(vehicle)
    
    -- Check garage limit
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM territory_vehicles WHERE territory_id = ? AND gang = ?', {
        territoryId, gang
    })
    
    if count >= Config.Garage.maxVehicles then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('garage_full'),
            type = 'error'
        })
        return
    end
    
    MySQL.insert('INSERT INTO territory_vehicles (territory_id, gang, vehicle, stored) VALUES (?, ?, ?, ?)', {
        territoryId, gang, json.encode(props), true
    })
    
    DeleteEntity(vehicle)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('vehicle_stored'),
        type = 'success'
    })
end)

RegisterNetEvent('territories:server:spawnVehicle', function(territoryId, vehicleId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory or not territory.features.garage then return end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.hasAccess(territory, gang) then return end
    
    local vehicle = MySQL.single.await('SELECT * FROM territory_vehicles WHERE id = ? AND territory_id = ? AND gang = ?', {
        vehicleId, territoryId, gang
    })
    
    if not vehicle or not vehicle.stored then return end
    
    MySQL.update('UPDATE territory_vehicles SET stored = 0 WHERE id = ?', {vehicleId})
    
    TriggerClientEvent('territories:client:spawnVehicle', src, vehicle.vehicle, territory.features.garage.spawn)
end)

AddEventHandler('territories:server:transferGarageVehicles', function(territoryId, oldGang, newGang)
    if not Config.Garage.transferOnCapture then return end
    
    MySQL.update('UPDATE territory_vehicles SET gang = ? WHERE territory_id = ? AND gang = ?', {
        newGang, territoryId, oldGang
    })
end)
