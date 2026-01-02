local sync = {}
local blips = {}

function sync.updateBlipColor(territoryId, gang)
    if blips[territoryId] then
        SetBlipColour(blips[territoryId], Utils.getBlipColor(gang))
    end
end

function sync.setBlips(territoryBlips)
    blips = territoryBlips
end

AddStateBagChangeHandler('territories', 'global', function(bagName, key, value)
    if not value then return end
    
    for territoryId, data in pairs(value) do
        if Territories[territoryId] then
            Territories[territoryId].control = data.control
            Territories[territoryId].influence = data.influence
            sync.updateBlipColor(territoryId, data.control)
        end
    end
end)

AddStateBagChangeHandler('captureProgress', 'global', function(bagName, key, value)
    if not value then return end
    
    for territoryId, data in pairs(value) do
        if Territories[territoryId] then
            local territory = Territories[territoryId]
            lib.notify({
                title = locale('capture_progress'),
                description = locale('capture_progress_update', data.gang, territory.label, data.progress),
                type = 'inform'
            })
            TriggerEvent('territories:client:captureProgressUpdated', territoryId, data)
        end
    end
end)

lib.onCache('vehicle', function(value)
    if value then
        local plate = GetVehicleNumberPlateText(value)
        Entity(value).state:set('plate', plate, true)
    end
end)

lib.onCache('ped', function(value)
    if value then
        LocalPlayer.state:set('ped', value, true)
    end
end)

function sync.requestTerritoriesState()
    lib.callback('territories:getTerritoriesState', false, function(territories)
        if territories then
            for territoryId, data in pairs(territories) do
                if Territories[territoryId] then
                    Territories[territoryId].control = data.control
                    Territories[territoryId].influence = data.influence
                    sync.updateBlipColor(territoryId, data.control)
                end
            end
        end
    end)
end

function sync.requestCaptureState()
    lib.callback('territories:getCaptureState', false, function(captureProgress)
        if captureProgress then
            for territoryId, data in pairs(captureProgress) do
                TriggerEvent('territories:client:captureProgressUpdated', territoryId, data)
            end
        end
    end)
end

return sync
