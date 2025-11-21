local sync = {}

GlobalState.territories = {}
GlobalState.captureProgress = {}
GlobalState.playersInZones = {}

local function buildTerritoryState(territory)
    if not territory then return nil end

    return {
        label = territory.label,
        control = territory.control,
        influence = territory.influence,
        drugs = territory.drugs,
        zone = territory.zone,
        capture = territory.capture,
        features = territory.features,
        businesses = territory.businesses,
        blip = territory.blip
    }
end

local function upsertTerritoryState(territoryId, territory)
    local territories = GlobalState.territories or {}
    local state = territories[territoryId] or buildTerritoryState(territory)

    if not state then return end

    state.control = territory.control
    state.influence = territory.influence
    state.label = territory.label
    state.drugs = territory.drugs
    state.zone = territory.zone
    state.capture = territory.capture
    state.features = territory.features
    state.businesses = territory.businesses
    state.blip = territory.blip

    territories[territoryId] = state
    GlobalState.territories = territories
end

function sync.initializeTerritories()
    local territories = {}
    for id, territory in pairs(Territories) do
        local state = buildTerritoryState(territory)
        if state then
            territories[id] = state
        end
    end
    GlobalState.territories = territories
end

function sync.updateTerritoryControl(territoryId, gang)
    local territory = Territories[territoryId]
    if not territory then return end

    territory.control = gang
    upsertTerritoryState(territoryId, territory)
end

function sync.updateTerritoryInfluence(territoryId, influence)
    local territory = Territories[territoryId]
    if not territory then return end

    territory.influence = influence
    upsertTerritoryState(territoryId, territory)
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
