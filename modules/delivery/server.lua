local QBCore = exports['qb-core']:GetCoreObject()
local activeDeliveries = {}

local deliveryLocations = {
    vec4(1200.0, -1276.0, 35.0, 90.0),
    vec4(311.0, -1275.0, 31.0, 180.0),
    vec4(-138.0, -1671.0, 33.0, 140.0),
    vec4(475.0, -1798.0, 28.0, 270.0)
}

RegisterNetEvent('territories:server:startDelivery', function(territoryId, drugType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory then return end

    if not territory.features or not territory.features.garage or not territory.features.garage.spawn then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end

    local gang = Player.PlayerData.gang.name
    if not Utils.hasAccess(territory, gang) then return end

    if activeDeliveries[src] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('already_selling'),
            type = 'error'
        })
        return
    end
    
    -- Check if player has enough drugs
    local requiredAmount = 50
    local drugCount = exports.ox_inventory:GetItem(src, drugType, nil, true)
    
    if drugCount < requiredAmount then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('not_enough_drugs_delivery', requiredAmount),
            type = 'error'
        })
        return
    end
    
    -- Remove drugs
    exports.ox_inventory:RemoveItem(src, drugType, requiredAmount)
    
    -- Get random delivery location
    local destination = deliveryLocations[math.random(#deliveryLocations)]

    activeDeliveries[src] = {
        territoryId = territoryId,
        drugType = drugType,
        amount = requiredAmount,
        startTime = os.time(),
        destination = destination
    }
    
    -- Start delivery
    TriggerClientEvent('territories:client:startDelivery', src, 'burrito3', territory.features.garage.spawn, destination, drugType, requiredAmount)
end)

RegisterNetEvent('territories:server:completeDelivery', function(drugType, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local delivery = activeDeliveries[src]
    if not delivery then return end
    if delivery.drugType ~= drugType then return end
    if delivery.amount ~= amount then return end
    drugType = delivery.drugType
    amount = delivery.amount
    
    -- Calculate payment
    local priceData = Config.DrugSales.prices[drugType]
    local payment = 0
    
    if priceData then
        payment = math.random(priceData.min, priceData.max) * amount * 1.5 -- 50% bonus for bulk
    end
    
    Player.Functions.AddMoney('cash', payment)

    activeDeliveries[src] = nil
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('delivery_complete', payment),
        type = 'success'
    })
    
    -- Add territory income
    local territoryId = GetPlayerZone(src)
    if territoryId then
        local tax = math.floor(payment * Config.Economy.tax.drugSale)
        TriggerEvent('territories:server:addTerritoryMoney', territoryId, tax)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeDeliveries[src] then
        activeDeliveries[src] = nil
    end
end)

RegisterNetEvent('territories:server:failDelivery', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if activeDeliveries[src] then
        activeDeliveries[src] = nil
    end
    
    -- Penalties
    if reason == 'police_raid' then
        -- Might want to add wanted level or alert
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('delivery_failed'),
            description = locale('police_seized_drugs'),
            type = 'error'
        })
    end
end)

RegisterNetEvent('territories:server:alertPoliceRaid', function(coords)
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and Utils.isPoliceJob(player.PlayerData.job.name) then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = locale('police_alert'),
                description = locale('drug_transport_spotted'),
                type = 'error',
                duration = 15000
            })
            
            -- Create raid blip
            TriggerClientEvent('territories:client:createRaidBlip', playerId, coords)
        end
    end
end)
