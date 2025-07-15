local QBCore = exports['qb-core']:GetCoreObject()
local sellingDrugs = false
local targetOptions = {}

local function canSellDrugs(entity)
    if IsPedAPlayer(entity) then return false end
    if IsPedInAnyVehicle(entity, false) then return false end
    if IsPedDeadOrDying(entity, true) then return false end
    if GetPedType(entity) == 28 then return false end
    
    local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
    if not currentZone then return false end
    
    local territory = GlobalState.territories[currentZone]
    if not territory or not territory.drugs then return false end
    
    local Player = QBCore.Functions.GetPlayerData()
    if not Player.gang or Player.gang.name == 'none' then return false end
    
    if territory.control ~= Player.gang.name and territory.control ~= 'neutral' then
        return false
    end
    
    return true
end

local function setupDrugSalesTarget()
    targetOptions.drugSale = exports.ox_target:addGlobalPed({
        {
            name = 'sell_drugs',
            event = 'territories:client:attemptDrugSale',
            icon = 'fas fa-cannabis',
            label = locale('sell_drugs'),
            canInteract = canSellDrugs,
            distance = 2.0
        }
    })
end

RegisterNetEvent('territories:client:attemptDrugSale', function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    
    if sellingDrugs then
        lib.notify({
            title = locale('error'),
            description = locale('already_selling'),
            type = 'error'
        })
        return
    end
    
    sellingDrugs = true
    local ped = PlayerPedId()
    
    FreezeEntityPosition(ped, true)
    TaskTurnPedToFaceEntity(ped, entity, 1000)
    TaskTurnPedToFaceEntity(entity, ped, 1000)
    Wait(1500)
    
    lib.progressBar({
        duration = math.random(5000, 8000),
        label = locale('negotiating'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    })
    
    FreezeEntityPosition(ped, false)
    
    local currentZone = exports[GetCurrentResourceName()]:getCurrentZone()
    if currentZone then
        lib.callback('territories:sellDrugsToNPC', false, function(success, message)
            if success then
                lib.notify({
                    title = locale('drug_sale'),
                    description = message,
                    type = 'success'
                })
                
                PlayAmbientSpeech1(entity, "GENERIC_THANKS", "SPEECH_PARAMS_FORCE_NORMAL")
                TaskWanderStandard(entity, 10.0, 10)
            else
                lib.notify({
                    title = locale('drug_sale'),
                    description = message,
                    type = 'error'
                })
                
                local chance = math.random(1, 100)
                if chance <= 30 then
                    PlayAmbientSpeech1(entity, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE_SHOUTED")
                    TaskSmartFleePed(entity, ped, 100.0, -1, false, false)
                    
                    local coords = GetEntityCoords(ped)
                    TriggerServerEvent('territories:server:reportDrugSale', coords)
                else
                    PlayAmbientSpeech1(entity, "GENERIC_NO", "SPEECH_PARAMS_FORCE_NORMAL")
                    TaskWanderStandard(entity, 10.0, 10)
                end
            end
            
            SetPedAsNoLongerNeeded(entity)
            sellingDrugs = false
        end, currentZone)
    else
        sellingDrugs = false
    end
end)

CreateThread(setupDrugSalesTarget)

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
    
    local territory = GlobalState.territories[currentZone]
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
