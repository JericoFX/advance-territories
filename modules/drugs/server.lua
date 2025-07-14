local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:server:startSelling', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory or not territory.drugs then return end
    
    local hasDrugs = false
    for _, drug in ipairs(territory.drugs) do
        if exports.ox_inventory:GetItem(src, drug, nil, true) > 0 then
            hasDrugs = true
            break
        end
    end
    
    if not hasDrugs then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_drugs'),
            type = 'error'
        })
        return
    end
    
    TriggerClientEvent('territories:client:startSelling', src)
end)

RegisterNetEvent('territories:server:sellDrugs', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territoryId = GetPlayerZone(src)
    if not territoryId then return end
    
    local territory = Territories[territoryId]
    if not territory or not territory.drugs then return end
    
    local gang = Player.PlayerData.gang.name
    local priceMultiplier = 1.0
    
    if territory.control == gang then
        priceMultiplier = Config.Gangs.territoryBonus.drugPrice
    end
    
    for _, drug in ipairs(territory.drugs) do
        local amount = math.random(Config.DrugSales.amount.min, Config.DrugSales.amount.max)
        local playerAmount = exports.ox_inventory:GetItem(src, drug, nil, true)
        
        if playerAmount >= amount then
            local priceData = Config.DrugSales.prices[drug]
            if priceData then
                local price = math.random(priceData.min, priceData.max) * amount * priceMultiplier
                
                if exports.ox_inventory:RemoveItem(src, drug, amount) then
                    Player.Functions.AddMoney('cash', math.floor(price))
                    
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = locale('success'),
                        description = locale('drug_sale_success'),
                        type = 'success'
                    })
                    
                    -- Add tax to territory
                    if Config.Economy.enabled and Config.Economy.tax.drugSale > 0 then
                        local tax = math.floor(price * Config.Economy.tax.drugSale)
                        TriggerEvent('territories:server:addTerritoryMoney', territoryId, tax)
                    end
                    
                    return
                end
            end
        end
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('error'),
        description = locale('no_drugs'),
        type = 'error'
    })
end)

RegisterNetEvent('territories:server:reportDrugSale', function(coords)
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and Utils.isPoliceJob(player.PlayerData.job.name) then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = locale('police_alert'),
                description = locale('drug_sale_reported'),
                type = 'error'
            })
            
            -- Create blip for police
            TriggerClientEvent('territories:client:policeBlip', playerId, coords)
        end
    end
end)
