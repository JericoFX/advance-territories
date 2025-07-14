local QBCore = exports['qb-core']:GetCoreObject()
local playerBuckets = {}
local gangLabBuckets = {}
local nextBucketId = 1000

-- Assign unique buckets per gang for labs
RegisterNetEvent('territories:server:requestLabBucket', function(labType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.isValidGang(gang) then return end
    
    local bucketKey = ('%s_%s'):format(gang, labType)
    
    -- Create bucket if doesn't exist
    if not gangLabBuckets[bucketKey] then
        gangLabBuckets[bucketKey] = nextBucketId
        nextBucketId = nextBucketId + 1
    end
    
    local bucketId = gangLabBuckets[bucketKey]
    
    -- Move player to bucket
    SetPlayerRoutingBucket(src, bucketId)
    playerBuckets[src] = bucketId
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('bucket_assigned'),
        description = locale('moved_to_private_instance'),
        type = 'inform'
    })
end)

-- Return player to main bucket
RegisterNetEvent('territories:server:exitLabBucket', function()
    local src = source
    
    if playerBuckets[src] then
        SetPlayerRoutingBucket(src, 0)
        playerBuckets[src] = nil
    end
end)

-- Clean up on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if playerBuckets[src] then
        playerBuckets[src] = nil
    end
end)

-- Get players in same bucket
function GetPlayersInBucket(bucketId)
    local players = {}
    for playerId, bucket in pairs(playerBuckets) do
        if bucket == bucketId then
            table.insert(players, playerId)
        end
    end
    return players
end

exports('GetPlayersInBucket', GetPlayersInBucket)
