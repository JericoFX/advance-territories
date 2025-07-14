local sync = {}

GlobalState.territories = {}
GlobalState.captureProgress = {}
GlobalState.playersInZones = {}

function sync.initializeTerritories()
    local territories = {}
    for id, territory in pairs(Territories) do
        territories[id] = {
            control = territory.control,
            influence = territory.influence,
            label = territory.label
        }
    end
    GlobalState.territories = territories
end

function sync.updateTerritoryControl(territoryId, gang)
    local territories = GlobalState.territories
    if territories[territoryId] then
        territories[territoryId].control = gang
        GlobalState.territories = territories
    end
end

function sync.updateTerritoryInfluence(territoryId, influence)
    local territories = GlobalState.territories
    if territories[territoryId] then
        territories[territoryId].influence = influence
        GlobalState.territories = territories
    end
end

function sync.updateCaptureProgress(territoryId, gang, progress)
    local captureProgress = GlobalState.captureProgress
    captureProgress[territoryId] = {
        gang = gang,
        progress = progress,
        timestamp = os.time()
    }
    GlobalState.captureProgress = captureProgress
end

function sync.removeCaptureProgress(territoryId)
    local captureProgress = GlobalState.captureProgress
    captureProgress[territoryId] = nil
    GlobalState.captureProgress = captureProgress
end

function sync.updatePlayerZone(playerId, zoneId)
    local playersInZones = GlobalState.playersInZones
    if zoneId then
        playersInZones[tostring(playerId)] = zoneId
    else
        playersInZones[tostring(playerId)] = nil
    end
    GlobalState.playersInZones = playersInZones
end

lib.callback.register('territories:getTerritoriesState', function(source)
    return GlobalState.territories
end)

lib.callback.register('territories:getCaptureState', function(source)
    return GlobalState.captureProgress
end)

return sync
