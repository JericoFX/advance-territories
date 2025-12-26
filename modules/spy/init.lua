local QBCore = exports['qb-core']:GetCoreObject()
local hierarchy = require 'modules.hierarchy'
local activeSpies = {}
local spyBlips = {}

local SpyConfig = {
    spawnChance = 5,
    checkInterval = 300000,
    maxDuration = 600000,
    successChance = 60,
    alertDuration = 120000,
    reward = {min = 1000, max = 2500},
    models = {'s_m_y_dealer_01', 's_m_m_fibsec_01', 's_m_y_robber_01', 's_f_y_shop_low'}
}

local function spawnSpy(territoryId)
    local territory = Territories[territoryId]
    if not territory then return end

    if territory.control == 'neutral' then return end

    local center = Utils.getTerritoryCenter(territory) or (territory.capture and territory.capture.point)
    if not center then return end

    local spawnPoint = vec3(
        center.x + math.random(-50, 50),
        center.y + math.random(-50, 50),
        center.z
    )
    
    local model = GetHashKey(SpyConfig.models[math.random(#SpyConfig.models)])
    
    local spyData = {
        territoryId = territoryId,
        coords = spawnPoint,
        model = model,
        spawnTime = GetGameTimer(),
        detected = false
    }
    
    activeSpies[territoryId] = spyData
    
    TriggerClientEvent('territories:client:spawnSpy', -1, territoryId, spyData)
    
    local gangMembers = GetGangMembers(territory.control)
    for _, member in pairs(gangMembers) do
        TriggerClientEvent('ox_lib:notify', member.source, {
            title = locale('spy_alert'),
            description = locale('spy_detected', territory.label),
            type = 'error',
            duration = 8000
        })
    end
    
    SetTimeout(SpyConfig.maxDuration, function()
        if activeSpies[territoryId] then
            activeSpies[territoryId] = nil
            TriggerClientEvent('territories:client:removeSpy', -1, territoryId)
            
            local currentMembers = GetGangMembers(territory.control)
            for _, member in pairs(currentMembers) do
                TriggerClientEvent('ox_lib:notify', member.source, {
                    title = locale('spy_escaped'),
                    description = locale('spy_escaped_desc'),
                    type = 'error'
                })
            end
        end
    end)
end

local function checkSpySpawn()
    for territoryId, territory in pairs(Territories) do
        if territory.control ~= 'neutral' and not activeSpies[territoryId] then
            if math.random(100) <= SpyConfig.spawnChance then
                local playersInTerritory = GetPlayersInZone(territoryId)
                if #playersInTerritory > 0 then
                    spawnSpy(territoryId)
                end
            end
        end
    end
end

-- NOTE: catchSpy handler is implemented in modules/spy/server.lua to avoid duplicate rewards.

lib.callback.register('territories:getSpyInfo', function(source, territoryId)
    local spy = activeSpies[territoryId]
    if spy then
        return {
            coords = spy.coords,
            model = spy.model,
            active = true
        }
    end
    return {active = false}
end)

CreateThread(function()
    while true do
        Wait(SpyConfig.checkInterval)
        checkSpySpawn()
    end
end)

return {
    spawnSpy = spawnSpy,
    checkSpySpawn = checkSpySpawn,
    activeSpies = activeSpies
}
