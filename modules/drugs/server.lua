local QBCore = exports['qb-core']:GetCoreObject()
local lastDrugReport = {}
local lastNpcSale = {}
local lastStreetSale = {}
local DrugReportConfig = {
    cooldownSeconds = 30 -- TODO: move to Config if needed
}
local DrugSaleConfig = {
    npcCooldownSeconds = 5, -- TODO: move to Config if needed
    streetCooldownSeconds = 5 -- TODO: move to Config if needed
}

RegisterNetEvent('territories:server:startSelling', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = GlobalState.territories[territoryId]
    if not territory or not territory.drugs then return end

    if GetPlayerZone(src) ~= territoryId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('must_be_in_territory'),
            type = 'error'
        })
        return
    end
    
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

    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    if IsPedInAnyVehicle(ped, false) then return end

    local now = os.time()
    if lastStreetSale[src] and now - lastStreetSale[src] < DrugSaleConfig.streetCooldownSeconds then
        return
    end
    lastStreetSale[src] = now
    
    local territoryId = GetPlayerZone(src)
    if not territoryId then return end
    
    local territory = GlobalState.territories[territoryId]
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

lib.callback.register('territories:sellDrugsToNPC', function(source, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, locale('error') end

    local territoryId = data
    local pedNetId = nil
    if type(data) == 'table' then
        territoryId = data.territoryId
        pedNetId = data.pedNetId
    end

    if not pedNetId then
        return false, locale('drug_sale_rejected')
    end

    local entity = NetworkGetEntityFromNetworkId(pedNetId)
    if entity == 0 or not DoesEntityExist(entity) or not IsEntityAPed(entity) or IsPedAPlayer(entity) then
        return false, locale('drug_sale_rejected')
    end

    if IsPedDeadOrDying(entity, true) or IsPedInAnyVehicle(entity, false) then
        return false, locale('drug_sale_rejected')
    end
    
    local territory = GlobalState.territories[territoryId]
    if not territory or not territory.drugs then
        return false, locale('no_drugs_allowed')
    end
    
    local gang = Player.PlayerData.gang.name
    if gang == 'none' then
        return false, locale('no_gang')
    end

    if GetPlayerZone(src) ~= territoryId then
        return false, locale('not_in_territory')
    end

    local now = os.time()
    if lastNpcSale[src] and now - lastNpcSale[src] < DrugSaleConfig.npcCooldownSeconds then
        return false, locale('already_selling')
    end

    if pedNetId then
        local entity = NetworkGetEntityFromNetworkId(pedNetId)
        if entity and DoesEntityExist(entity) then
            local ped = GetPlayerPed(src)
            if ped == 0 then return false, locale('error') end

            local playerCoords = GetEntityCoords(ped)
            local pedCoords = GetEntityCoords(entity)
            if #(playerCoords - pedCoords) > Config.DrugSales.distance then
                return false, locale('drug_sale_rejected')
            end
        else
            return false, locale('drug_sale_rejected')
        end
    end

    lastNpcSale[src] = now
    
    local priceMultiplier = 1.0
    if territory.control == gang then
        priceMultiplier = Config.Gangs.territoryBonus.drugPrice
    elseif territory.control ~= 'neutral' then
        priceMultiplier = 0.7
    end
    
    for _, drug in ipairs(territory.drugs) do
        local amount = math.random(Config.DrugSales.amount.min, Config.DrugSales.amount.max)
        local playerAmount = exports.ox_inventory:GetItem(src, drug, nil, true)
        
        if playerAmount >= amount then
            local priceData = Config.DrugSales.prices[drug]
            if priceData then
                local policeCount = Utils.getPoliceCount()
                local heatMultiplier = 1.0
                
                if policeCount >= Config.Police.minOnDuty then
                    heatMultiplier = 0.8
                end
                
                local basePrice = math.random(priceData.min, priceData.max)
                local finalPrice = math.floor(basePrice * amount * priceMultiplier * heatMultiplier)
                
                if exports.ox_inventory:RemoveItem(src, drug, amount) then
                    Player.Functions.AddMoney('cash', finalPrice)
                    
                    if Config.Economy.enabled and Config.Economy.tax.drugSale > 0 then
                        local tax = math.floor(finalPrice * Config.Economy.tax.drugSale)
                        TriggerEvent('territories:server:addTerritoryMoney', territoryId, tax)
                    end
                    
                    return true, locale('drug_sale_success', amount, drug, finalPrice)
                end
            end
        end
    end
    
    return false, locale('no_drugs')
end)

RegisterNetEvent('territories:server:reportDrugSale', function(coords)
    local src = source
    local now = os.time()
    local lastReport = lastDrugReport[src]
    if lastReport and now - lastReport < DrugReportConfig.cooldownSeconds then
        return
    end
    lastDrugReport[src] = now

    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    coords = GetEntityCoords(ped)

    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and player.PlayerData and player.PlayerData.job then
            local job = player.PlayerData.job
            if Utils.isPoliceJob(job.name) and (job.onduty == nil or job.onduty) then
                TriggerClientEvent('ox_lib:notify', playerId, {
                    title = locale('police_alert'),
                    description = locale('drug_sale_reported'),
                    type = 'error'
                })
                
                TriggerClientEvent('territories:client:policeBlip', playerId, coords)
            end
        end
    end
end)
