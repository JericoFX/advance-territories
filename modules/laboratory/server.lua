local QBCore = exports['qb-core']:GetCoreObject()
local playerBuckets = {}
local territoryBuckets = {}

local function getOrCreateTerritoryBucket(territoryId, gangName)
    local key = ('%s_%s'):format(territoryId, gangName)
    
    if not territoryBuckets[key] then
        territoryBuckets[key] = {
            bucket = GetHashKey(key),
            territoryId = territoryId,
            gangName = gangName,
            players = {}
        }
    end
    
    return territoryBuckets[key]
end

RegisterNetEvent('territories:server:enterLaboratory', function(territoryId, gangName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local territory = Territories[territoryId]
    if not territory then return end

    gangName = Player.PlayerData.gang.name
    if not Utils.isValidGang(gangName) then return end
    if not Utils.hasAccess(territory, gangName) then return end

    if GetPlayerZone(src) ~= territoryId then return end

    if not territory.features or not territory.features.labEntry or not territory.features.labEntry.coords then return end
    local entryCoords = territory.features.labEntry.coords
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local coords = GetEntityCoords(ped)
    if #(coords - entryCoords) > Config.Interact.distance then return end
    
    local bucketData = getOrCreateTerritoryBucket(territoryId, gangName)
    
    SetPlayerRoutingBucket(src, bucketData.bucket)
    
    playerBuckets[src] = {
        bucket = bucketData.bucket,
        territoryId = territoryId,
        gangName = gangName
    }
    
    bucketData.players[src] = true
    
    SetRoutingBucketPopulationEnabled(bucketData.bucket, false)
    SetRoutingBucketEntityLockdownMode(bucketData.bucket, 'strict')
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('laboratory_bucket'),
        description = locale('laboratory_bucket_desc', gangName),
        type = 'info'
    })
end)

RegisterNetEvent('territories:server:exitLaboratory', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local bucketInfo = playerBuckets[src]
    if not bucketInfo then return end
    
    SetPlayerRoutingBucket(src, 0)
    
    local bucketTerritoryId = bucketInfo.territoryId
    if territoryBuckets[('%s_%s'):format(bucketTerritoryId, bucketInfo.gangName)] then
        territoryBuckets[('%s_%s'):format(bucketTerritoryId, bucketInfo.gangName)].players[src] = nil
    end
    
    playerBuckets[src] = nil
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('laboratory_exit'),
        description = locale('laboratory_exit_desc'),
        type = 'info'
    })
end)

AddEventHandler('playerDropped', function()
    local src = source
    local bucketInfo = playerBuckets[src]
    
    if bucketInfo then
        local key = ('%s_%s'):format(bucketInfo.territoryId, bucketInfo.gangName)
        if territoryBuckets[key] then
            territoryBuckets[key].players[src] = nil
        end
        playerBuckets[src] = nil
    end
end)

lib.callback.register('territories:isPlayerInLaboratory', function(source)
    return playerBuckets[source] ~= nil
end)

lib.callback.register('territories:getPlayerLaboratoryInfo', function(source)
    return playerBuckets[source]
end)
