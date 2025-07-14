local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:client:openGarage', function(territoryId)
    local territory = Territories[territoryId]
    if not territory or not territory.features.garage then return end
    
    local playerData = QBCore.Functions.GetPlayerData()
    if not Utils.hasAccess(territory, playerData.gang.name) then
        lib.notify({
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('territories:server:getGarageVehicles', territoryId)
end)

RegisterNetEvent('territories:client:showGarageMenu', function(vehicles, territoryId)
    local territory = Territories[territoryId]
    if not territory then return end
    
    local options = {}
    
    -- Store current vehicle option
    local vehicle = lib.getVehicleProperties(GetVehiclePedIsIn(PlayerPedId(), false))
    if vehicle then
        table.insert(options, {
            title = locale('store_vehicle'),
            description = vehicle.plate,
            icon = 'warehouse',
            onSelect = function()
                TriggerServerEvent('territories:server:storeVehicle', territoryId)
            end
        })
    end
    
    -- List stored vehicles
    for _, veh in ipairs(vehicles) do
        local vehicleData = json.decode(veh.vehicle)
        table.insert(options, {
            title = vehicleData.plate,
            description = locale('spawn_vehicle'),
            icon = 'car',
            disabled = not veh.stored,
            onSelect = function()
                TriggerServerEvent('territories:server:spawnVehicle', territoryId, veh.id)
            end
        })
    end
    
    if #options == 0 then
        table.insert(options, {
            title = locale('no_vehicles'),
            icon = 'circle-xmark',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'territory_garage',
        title = locale('territory_garage', territory.label),
        options = options
    })
    
    lib.showContext('territory_garage')
end)

RegisterNetEvent('territories:client:spawnVehicle', function(vehicleData, spawn)
    local vehicleProps = json.decode(vehicleData)
    
    lib.requestModel(vehicleProps.model)
    
    local vehicle = CreateVehicle(vehicleProps.model, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    
    lib.setVehicleProperties(vehicle, vehicleProps)
    
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    lib.notify({
        title = locale('success'),
        description = locale('vehicle_spawned'),
        type = 'success'
    })
end)
