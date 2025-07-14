local QBCore = exports['qb-core']:GetCoreObject()
local hierarchy = require 'modules.hierarchy'
local currentMissions = {}
local missionNPCs = {}
local missionVehicles = {}
local missionBlips = {}

local MissionConfig = {
    vipEscort = {
        reward = 5000,
        timeLimit = 900,
        vipModels = {'a_m_m_business_01', 'a_f_m_business_02', 'a_m_m_eastsa_01'}
    },
    intercept = {
        reward = 7500,
        timeLimit = 1200,
        vehicleModels = {'pounder', 'mule', 'boxville'}
    },
    defense = {
        reward = 10000,
        timeLimit = 600,
        enemyCount = {min = 3, max = 6},
        enemyModels = {'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_lost_03'}
    }
}

local function generateVIPMission(territoryId)
    local territory = Territories[territoryId]
    if not territory then return nil end
    
    local pickupPoints = {
        vec4(territory.zone.center.x + math.random(-50, 50), territory.zone.center.y + math.random(-50, 50), territory.zone.center.z, 0.0),
        vec4(territory.zone.center.x + math.random(-75, 75), territory.zone.center.y + math.random(-75, 75), territory.zone.center.z, 0.0)
    }
    
    local dropoffPoints = {
        vec4(territory.zone.center.x + math.random(-100, 100), territory.zone.center.y + math.random(-100, 100), territory.zone.center.z, 0.0),
        vec4(territory.zone.center.x + math.random(-125, 125), territory.zone.center.y + math.random(-125, 125), territory.zone.center.z, 0.0)
    }
    
    return {
        type = 'vip_escort',
        territoryId = territoryId,
        pickup = pickupPoints[math.random(#pickupPoints)],
        dropoff = dropoffPoints[math.random(#dropoffPoints)],
        vipModel = MissionConfig.vipEscort.vipModels[math.random(#MissionConfig.vipEscort.vipModels)],
        reward = MissionConfig.vipEscort.reward,
        timeLimit = MissionConfig.vipEscort.timeLimit
    }
end

local function generateInterceptMission(territoryId)
    local territory = Territories[territoryId]
    if not territory then return nil end
    
    local spawnPoints = {
        vec4(territory.zone.center.x + math.random(-200, 200), territory.zone.center.y + math.random(-200, 200), territory.zone.center.z, 0.0),
        vec4(territory.zone.center.x + math.random(-250, 250), territory.zone.center.y + math.random(-250, 250), territory.zone.center.z, 0.0)
    }
    
    return {
        type = 'intercept_delivery',
        territoryId = territoryId,
        spawn = spawnPoints[math.random(#spawnPoints)],
        destination = vec4(territory.zone.center.x + math.random(-300, 300), territory.zone.center.y + math.random(-300, 300), territory.zone.center.z, 0.0),
        return_point = vec4(territory.zone.center.x, territory.zone.center.y, territory.zone.center.z, 0.0),
        vehicleModel = MissionConfig.intercept.vehicleModels[math.random(#MissionConfig.intercept.vehicleModels)],
        reward = MissionConfig.intercept.reward,
        timeLimit = MissionConfig.intercept.timeLimit
    }
end

local function generateDefenseMission(territoryId)
    local territory = Territories[territoryId]
    if not territory then return nil end
    
    local enemyCount = math.random(MissionConfig.defense.enemyCount.min, MissionConfig.defense.enemyCount.max)
    
    return {
        type = 'npc_attack',
        territoryId = territoryId,
        location = vec3(territory.zone.center.x, territory.zone.center.y, territory.zone.center.z),
        enemyCount = enemyCount,
        enemyModels = MissionConfig.defense.enemyModels,
        reward = MissionConfig.defense.reward,
        timeLimit = MissionConfig.defense.timeLimit
    }
end

lib.callback.register('territories:getMissions', function(source, territoryId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.isValidGang(gang) then return {} end
    
    local territory = Territories[territoryId]
    if not territory or territory.control ~= gang then return {} end
    
    if not hierarchy.hasPermission(Player, 'start_missions') then return {} end
    
    local missions = {}
    
    missions[#missions + 1] = {
        id = 'vip_escort',
        label = locale('vip_escort_mission'),
        description = locale('vip_escort_description'),
        reward = MissionConfig.vipEscort.reward,
        icon = 'fas fa-user-tie'
    }
    
    missions[#missions + 1] = {
        id = 'intercept_delivery',
        label = locale('intercept_mission'),
        description = locale('intercept_description'),
        reward = MissionConfig.intercept.reward,
        icon = 'fas fa-truck'
    }
    
    missions[#missions + 1] = {
        id = 'npc_attack',
        label = locale('defense_mission'),
        description = locale('defense_description'),
        reward = MissionConfig.defense.reward,
        icon = 'fas fa-shield-alt'
    }
    
    return missions
end)

RegisterNetEvent('territories:server:startMission', function(territoryId, missionType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local gang = Player.PlayerData.gang.name
    if not Utils.isValidGang(gang) then return end
    
    local territory = Territories[territoryId]
    if not territory or territory.control ~= gang then return end
    
    if not hierarchy.hasPermission(Player, 'start_missions') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_permission'),
            type = 'error'
        })
        return
    end
    
    if currentMissions[src] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('already_on_mission'),
            type = 'error'
        })
        return
    end
    
    local missionData
    if missionType == 'vip_escort' then
        missionData = generateVIPMission(territoryId)
    elseif missionType == 'intercept_delivery' then
        missionData = generateInterceptMission(territoryId)
    elseif missionType == 'npc_attack' then
        missionData = generateDefenseMission(territoryId)
    end
    
    if not missionData then return end
    
    currentMissions[src] = missionData
    TriggerClientEvent('territories:client:startMission', src, missionType, missionData)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('mission_started'),
        description = locale('mission_started_description', locale(missionType .. '_mission')),
        type = 'success'
    })
end)

RegisterNetEvent('territories:server:completeMission', function(missionType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local mission = currentMissions[src]
    if not mission then return end
    
    currentMissions[src] = nil
    
    Player.Functions.AddMoney('cash', mission.reward)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('mission_completed'),
        description = locale('mission_reward', mission.reward),
        type = 'success'
    })
    
    local gangMembers = GetGangMembers(Player.PlayerData.gang.name)
    for _, member in pairs(gangMembers) do
        if member.source ~= src then
            TriggerClientEvent('ox_lib:notify', member.source, {
                title = locale('gang_mission_completed'),
                description = locale('member_completed_mission', Player.PlayerData.charinfo.firstname, locale(missionType .. '_mission')),
                type = 'info'
            })
        end
    end
end)

RegisterNetEvent('territories:server:failMission', function(missionType, reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local mission = currentMissions[src]
    if not mission then return end
    
    currentMissions[src] = nil
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('mission_failed'),
        description = locale('mission_failed_reason', locale(reason)),
        type = 'error'
    })
end)

AddEventHandler('playerDropped', function()
    local src = source
    if currentMissions[src] then
        currentMissions[src] = nil
    end
end)

return {
    generateVIPMission = generateVIPMission,
    generateInterceptMission = generateInterceptMission,
    generateDefenseMission = generateDefenseMission,
    currentMissions = currentMissions
}
