local QBCore = exports['qb-core']:GetCoreObject()
local lastCollection = {}

RegisterNetEvent('territories:server:collectIncome', function(territoryId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory then return end
    
    local gang = Player.PlayerData.gang.name
    if territory.control ~= gang then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end
    
    local playerId = Player.PlayerData.citizenid
    local cooldownKey = ('%s_%s'):format(territoryId, playerId)
    
    if lastCollection[cooldownKey] and os.time() - lastCollection[cooldownKey] < Config.Economy.collection.cooldown then
        local remaining = math.ceil((Config.Economy.collection.cooldown - (os.time() - lastCollection[cooldownKey])) / 60)
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('collection_cooldown', remaining),
            type = 'error'
        })
        return
    end
    
    local income = territory.treasury or 0
    if income <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_income'),
            type = 'error'
        })
        return
    end
    
    lastCollection[cooldownKey] = os.time()
    
    if Config.Economy.collection.distribution then
        local gangMembers = QBCore.Functions.GetGangMembers(gang)
        local onlineMembers = {}
        local totalShares = 0
        
        for citizenid, member in pairs(gangMembers) do
            if member.isOnline then
                local grade = member.grade.level
                local shares = Config.Economy.gradeShares[grade] or 0.1
                totalShares = totalShares + shares
                table.insert(onlineMembers, {
                    source = QBCore.Functions.GetPlayerByCitizenId(citizenid).PlayerData.source,
                    shares = shares
                })
            end
        end
        
        for _, member in ipairs(onlineMembers) do
            local memberShare = math.floor(income * (member.shares / totalShares))
            local memberPlayer = QBCore.Functions.GetPlayer(member.source)
            if memberPlayer then
                memberPlayer.Functions.AddMoney('cash', memberShare)
                TriggerClientEvent('ox_lib:notify', member.source, {
                    title = locale('territory_income'),
                    description = locale('collected_income', memberShare),
                    type = 'success'
                })
            end
        end
    else
        Player.Functions.AddMoney('cash', income)
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('territory_income'),
            description = locale('collected_income', income),
            type = 'success'
        })
    end
    
    territory.treasury = 0
    MySQL.update('UPDATE territories SET treasury = 0, last_collected = NOW() WHERE zone_id = ?', {territoryId})
end)

AddEventHandler('territories:server:addTerritoryMoney', function(territoryId, amount)
    local territory = Territories[territoryId]
    if not territory then return end
    
    territory.treasury = (territory.treasury or 0) + amount
    MySQL.update('UPDATE territories SET treasury = treasury + ? WHERE zone_id = ?', {amount, territoryId})
end)

-- Generate income from businesses
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        for zoneId, territory in pairs(Territories) do
            if territory.control ~= 'neutral' and territory.businesses then
                local totalIncome = 0
                for _, business in ipairs(territory.businesses) do
                    totalIncome = totalIncome + (business.income or 0)
                end
                
                if totalIncome > 0 then
                    local taxedIncome = math.floor(totalIncome * (1 - Config.Economy.tax.business))
                    TriggerEvent('territories:server:addTerritoryMoney', zoneId, taxedIncome)
                end
            end
        end
    end
end)
