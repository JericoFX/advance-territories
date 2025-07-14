local QBCore = exports['qb-core']:GetCoreObject()
local sellingDrugs = false

RegisterCommand('selldrugs', function()
    if sellingDrugs then
        lib.notify({
            title = locale('error'),
            description = locale('already_selling'),
            type = 'error'
        })
        return
    end
    
    local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
    if not currentZone then
        lib.notify({
            title = locale('error'),
            description = locale('not_in_territory'),
            type = 'error'
        })
        return
    end
    
    local territory = Territories[currentZone]
    if not territory or not territory.drugs then
        lib.notify({
            title = locale('error'),
            description = locale('no_drugs_allowed'),
            type = 'error'
        })
        return
    end
    
    TriggerServerEvent('territories:server:startSelling', currentZone)
end, false)

RegisterNetEvent('territories:client:startSelling', function()
    sellingDrugs = true
    
    CreateThread(function()
        while sellingDrugs do
            Wait(5000)
            
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local closestPed, closestDistance = lib.getClosestPed(coords, Config.DrugSales.distance)
            
            if closestPed and closestDistance <= Config.DrugSales.distance and not IsPedAPlayer(closestPed) then
                if not IsPedInAnyVehicle(closestPed, false) and not IsPedDeadOrDying(closestPed, true) then
                    local pedCoords = GetEntityCoords(closestPed)
                    
                    TaskTurnPedToFaceEntity(closestPed, ped, 1000)
                    Wait(1000)
                    
                    -- Start drug dealing animation
                    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_DRUG_DEALER_HARD", 0, true)
                    
                    lib.showTextUI(locale('selling_drugs'), {
                        position = 'left-center',
                        icon = 'cannabis'
                    })
                    
                    local sellTime = math.random(Config.DrugSales.time.min, Config.DrugSales.time.max)
                    Wait(sellTime)
                    
                    lib.hideTextUI()
                    
                    -- Stop animation
                    ClearPedTasks(ped)
                    
                    local chance = math.random(1, 100)
                    if chance <= Config.DrugSales.chance.buy then
                        TriggerServerEvent('territories:server:sellDrugs')
                    elseif chance <= Config.DrugSales.chance.buy + Config.DrugSales.chance.report then
                        TriggerServerEvent('territories:server:reportDrugSale', coords)
                        TaskSmartFleePed(closestPed, ped, 100.0, -1, false, false)
                    else
                        lib.notify({
                            title = locale('drug_sale'),
                            description = locale('drug_sale_rejected'),
                            type = 'error'
                        })
                        TaskSmartFleePed(closestPed, ped, 20.0, 5000, false, false)
                    end
                    
                    SetPedAsNoLongerNeeded(closestPed)
                    Wait(10000)
                end
            end
        end
    end)
end)

RegisterCommand('stopselling', function()
    sellingDrugs = false
    lib.notify({
        title = locale('drug_sale'),
        description = locale('stopped_selling'),
        type = 'inform'
    })
end, false)
