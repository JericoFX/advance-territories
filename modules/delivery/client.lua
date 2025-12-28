local QBCore = exports['qb-core']:GetCoreObject()
local deliveryActive = false
local deliveryVehicle = nil
local deliveryBlip = nil
local deliveryLocation = nil

RegisterNetEvent('territories:client:startDelivery', function(vehicleModel, spawnCoords, destination, drugType, amount, plate)
    if deliveryActive then return end
    
    deliveryActive = true
    deliveryLocation = destination
    
    -- Spawn vehicle
    lib.requestModel(vehicleModel)
    deliveryVehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)
    
    -- Set vehicle properties
    if plate then
        SetVehicleNumberPlateText(deliveryVehicle, plate)
    else
        SetVehicleNumberPlateText(deliveryVehicle, 'DRUG' .. math.random(1000, 9999))
    end
    SetEntityAsMissionEntity(deliveryVehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), deliveryVehicle, -1)
    
    -- Create delivery blip
    deliveryBlip = AddBlipForCoord(destination.x, destination.y, destination.z)
    SetBlipSprite(deliveryBlip, 514)
    SetBlipScale(deliveryBlip, 1.0)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(locale('delivery_location'))
    EndTextCommandSetBlipName(deliveryBlip)
    
    lib.notify({
        title = locale('delivery_started'),
        description = locale('deliver_drugs_to_buyer'),
        type = 'info'
    })
    
    -- Start delivery checks
    CreateThread(function()
        while deliveryActive do
            Wait(1000)
            
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - destination)
            
            if distance < 10.0 then
                lib.showTextUI(locale('press_to_deliver'), {
                    position = 'left-center',
                    icon = 'truck'
                })
                
                if IsControlJustPressed(0, 38) then -- E
                    if IsPedInVehicle(ped, deliveryVehicle, false) then
                        completeDelivery(drugType, amount)
                    else
                        lib.notify({
                            title = locale('error'),
                            description = locale('must_be_in_vehicle'),
                            type = 'error'
                        })
                    end
                end
            else
                lib.hideTextUI()
            end
            
            -- Check if vehicle is destroyed
            if not DoesEntityExist(deliveryVehicle) or GetEntityHealth(deliveryVehicle) <= 0 then
                failDelivery('vehicle_destroyed')
                break
            end
        end
    end)
    
    -- Random police checks
    CreateThread(function()
        while deliveryActive do
            Wait(30000) -- Check every 30 seconds
            
            local chance = math.random(1, 100)
            if chance <= 15 then -- 15% chance
                triggerPoliceRaid()
                break
            end
        end
    end)
end)

function completeDelivery(drugType, amount)
    deliveryActive = false
    lib.hideTextUI()
    
    if lib.progressCircle({
        duration = 10000,
        label = locale('delivering_drugs'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    }) then
        TriggerServerEvent('territories:server:completeDelivery', drugType, amount)
        
        -- Clean up
        DeleteEntity(deliveryVehicle)
        RemoveBlip(deliveryBlip)
        deliveryVehicle = nil
        deliveryBlip = nil
    end
end

function failDelivery(reason)
    deliveryActive = false
    lib.hideTextUI()
    
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
    
    TriggerServerEvent('territories:server:failDelivery', reason)
    
    lib.notify({
        title = locale('delivery_failed'),
        description = locale('delivery_failed_' .. reason),
        type = 'error'
    })
end

function triggerPoliceRaid()
    -- Alert police
    local coords = GetEntityCoords(deliveryVehicle)
    TriggerServerEvent('territories:server:alertPoliceRaid', coords)
    
    lib.notify({
        title = locale('police_raid'),
        description = locale('police_on_the_way'),
        type = 'error',
        duration = 10000
    })
    
    -- Give player time to escape
    SetTimeout(30000, function()
        if deliveryActive then
            failDelivery('police_raid')
        end
    end)
end
