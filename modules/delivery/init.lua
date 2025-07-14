local QBCore = exports['qb-core']:GetCoreObject()
local hierarchy = require 'modules.hierarchy'
local DeliveryConfig = {
    buyers = {
        {coords = vec3(100.0, -1000.0, 29.0), risk = 1, reward = {min = 500, max = 1000}},
        {coords = vec3(200.0, -1500.0, 29.0), risk = 2, reward = {min = 1000, max = 2000}},
        {coords = vec3(-500.0, 500.0, 29.0), risk = 3, reward = {min = 2000, max = 3000}}
    },
    vehicleModels = {'burrito', 'speedo', 'rumpo'}
}

local function startDrugDelivery(source, territoryId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local territory = Territories[territoryId]
    if not territory then return end

    if not hierarchy.hasPermission(Player, 'start_delivery') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You do not have permission to start a delivery.',
            type = 'error'
        })
        return
    end

    local buyer = DeliveryConfig.buyers[math.random(#DeliveryConfig.buyers)]
    local vehicleModel = DeliveryConfig.vehicleModels[math.random(#DeliveryConfig.vehicleModels)]

    TriggerClientEvent('territories:client:startDelivery', source, territoryId, buyer, vehicleModel)
end

lib.addCommand('startdelivery', {
    help = 'Start a drug delivery mission',
    restricted = 'group.gang'
}, function(source, args)
    local territoryId = args[1]
    if not territoryId then return end
    startDrugDelivery(source, territoryId)
end)

RegisterNetEvent('territories:server:completeDelivery', function(territoryId, success)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local buyer = DeliveryConfig.buyers[math.random(#DeliveryConfig.buyers)]
    local reward = math.random(buyer.reward.min, buyer.reward.max)

    if success then
        Player.Functions.AddMoney('cash', reward)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Delivery Completed',
            description = 'You have received $' .. reward .. ' for the delivery.',
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Delivery Failed',
            description = 'The delivery was not successful.',
            type = 'error'
        })
    end
end)


