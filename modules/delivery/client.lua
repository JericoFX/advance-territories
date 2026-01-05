local QBCore = exports['qb-core']:GetCoreObject()
local deliveryActive = false
local deliveryVehicle = nil
local deliveryBlip = nil
local deliveryLocation = nil
local missionDeliveryActive = false
local missionDeliveryVehicle = nil
local missionDeliveryBlip = nil
local missionDeliveryBuyer = nil
local missionDeliveryTerritory = nil

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

RegisterNetEvent('territories:client:startMissionDelivery', function(territoryId, buyer, vehicleModel)
    if missionDeliveryActive or deliveryActive then return end

    missionDeliveryActive = true
    missionDeliveryTerritory = territoryId
    missionDeliveryBuyer = buyer and buyer.coords or buyer

    lib.requestModel(vehicleModel)
    local ped = PlayerPedId()
    local spawnCoords = GetEntityCoords(ped)
    missionDeliveryVehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
    SetEntityAsMissionEntity(missionDeliveryVehicle, true, true)
    TaskWarpPedIntoVehicle(PlayerPedId(), missionDeliveryVehicle, -1)

    missionDeliveryBlip = AddBlipForCoord(missionDeliveryBuyer.x, missionDeliveryBuyer.y, missionDeliveryBuyer.z)
    SetBlipSprite(missionDeliveryBlip, 514)
    SetBlipScale(missionDeliveryBlip, 1.0)
    SetBlipColour(missionDeliveryBlip, 5)
    SetBlipRoute(missionDeliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(locale('delivery_location'))
    EndTextCommandSetBlipName(missionDeliveryBlip)

    CreateThread(function()
        while missionDeliveryActive do
            Wait(1000)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local distance = #(coords - missionDeliveryBuyer)

            if distance < 12.0 then
                lib.showTextUI(locale('press_to_deliver'), {
                    position = 'left-center',
                    icon = 'truck'
                })

                if IsControlJustPressed(0, 38) then -- E
                    if IsPedInVehicle(ped, missionDeliveryVehicle, false) then
                        TriggerServerEvent('territories:server:completeMissionDelivery', missionDeliveryTerritory, true)
                        missionDeliveryActive = false
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

            if not DoesEntityExist(missionDeliveryVehicle) or GetEntityHealth(missionDeliveryVehicle) <= 0 then
                TriggerServerEvent('territories:server:completeMissionDelivery', missionDeliveryTerritory, false)
                missionDeliveryActive = false
            end
        end

        lib.hideTextUI()

        if missionDeliveryBlip then
            RemoveBlip(missionDeliveryBlip)
            missionDeliveryBlip = nil
        end

        if missionDeliveryVehicle and DoesEntityExist(missionDeliveryVehicle) then
            DeleteEntity(missionDeliveryVehicle)
        end

        missionDeliveryVehicle = nil
        missionDeliveryBuyer = nil
        missionDeliveryTerritory = nil
    end)
end)
