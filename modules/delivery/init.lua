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
local MissionDeliveryConfig = {
    minDurationSeconds = 30, -- TODO: align with client flow
    completionRadius = 12.0, -- TODO: align with client interaction distance
    cooldownSeconds = 300 -- TODO: align with balance requirements
}
local activeMissionDeliveries = {}
local lastMissionDelivery = {}

local function startDrugDelivery(source, territoryId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end

    local territory = Territories[territoryId]
    if not territory then return end

    if GetPlayerZone(source) ~= territoryId then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You must be in the territory to start a delivery.',
            type = 'error'
        })
        return
    end

    local gang = Player.PlayerData.gang.name
    if not Utils.isValidGang(gang) or not Utils.hasAccess(territory, gang) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You do not have access to start a delivery here.',
            type = 'error'
        })
        return
    end

    if not hierarchy.hasPermission(Player, 'start_delivery') then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You do not have permission to start a delivery.',
            type = 'error'
        })
        return
    end

    local now = os.time()
    if lastMissionDelivery[source] and now - lastMissionDelivery[source] < MissionDeliveryConfig.cooldownSeconds then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'You need to wait before starting another delivery.',
            type = 'error'
        })
        return
    end

    local buyer = DeliveryConfig.buyers[math.random(#DeliveryConfig.buyers)]
    local vehicleModel = DeliveryConfig.vehicleModels[math.random(#DeliveryConfig.vehicleModels)]

    activeMissionDeliveries[source] = {
        territoryId = territoryId,
        buyer = buyer.coords,
        vehicleModel = vehicleModel,
        startTime = now
    }

    lastMissionDelivery[source] = now

    -- TODO: implement dedicated client handler for mission deliveries to avoid conflicting with bulk delivery flow.
    TriggerClientEvent('territories:client:startMissionDelivery', source, territoryId, buyer, vehicleModel)
end

lib.addCommand('startdelivery', {
    help = 'Start a drug delivery mission',
    restricted = 'group.gang',
    params = {
        {
            name = 'territory',
            type = 'string',
            help = 'Territory ID'
        }
    }
}, function(source, args)
    local territoryId = args.territory
    if not territoryId then return end
    startDrugDelivery(source, territoryId)
end)

RegisterNetEvent('territories:server:completeMissionDelivery', function(territoryId, success)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local active = activeMissionDeliveries[src]
    if not active then return end
    if active.territoryId ~= territoryId then return end

    if GetPlayerZone(src) ~= territoryId then
        activeMissionDeliveries[src] = nil
        return
    end

    local elapsed = os.time() - active.startTime
    if elapsed < MissionDeliveryConfig.minDurationSeconds then
        return
    end

    local ped = GetPlayerPed(src)
    if ped == 0 then return end

    if active.buyer then
        local coords = GetEntityCoords(ped)
        if #(coords - active.buyer) > MissionDeliveryConfig.completionRadius then
            return
        end
    end

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

    activeMissionDeliveries[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    activeMissionDeliveries[src] = nil
end)
