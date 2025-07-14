local QBCore = exports['qb-core']:GetCoreObject()

local ProcessRecipes = {
    weed = {
        {
            label = 'Process Weed',
            input = {['weed_leaf'] = 5},
            output = {['weed_skunk'] = 1},
            time = 30000
        }
    },
    cocaine = {
        {
            label = 'Process Cocaine',
            input = {['coca_leaf'] = 10},
            output = {['coke_brick'] = 1},
            time = 60000
        }
    },
    meth = {
        {
            label = 'Cook Meth',
            input = {['chemicals'] = 3, ['empty_bag'] = 1},
            output = {['meth'] = 1},
            time = 75000
        }
    },
    crack = {
        {
            label = 'Cook Crack',
            input = {['coke_brick'] = 1, ['bakingsoda'] = 2},
            output = {['crack'] = 3},
            time = 45000
        }
    }
}

RegisterNetEvent('territories:server:startProcess', function(territoryId, recipeIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory or not territory.features.process then return end
    
    local playerGang = Player.PlayerData.gang.name
    if not Utils.hasAccess(territory, playerGang) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_access'),
            type = 'error'
        })
        return
    end
    
    local processType = territory.features.process.type
    local recipe = ProcessRecipes[processType] and ProcessRecipes[processType][recipeIndex]
    if not recipe then return end
    
    -- Check items
    for item, amount in pairs(recipe.input) do
        local itemCount = exports.ox_inventory:GetItem(src, item, nil, true)
        if itemCount < amount then
            TriggerClientEvent('ox_lib:notify', src, {
                title = locale('error'),
                description = locale('missing_items'),
                type = 'error'
            })
            return
        end
    end
    
    -- Remove items
    for item, amount in pairs(recipe.input) do
        exports.ox_inventory:RemoveItem(src, item, amount)
    end
    
    -- Start processing
    TriggerClientEvent('territories:client:startProcess', src, territoryId, recipeIndex)
end)

RegisterNetEvent('territories:server:completeProcess', function(territoryId, recipeIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local territory = Territories[territoryId]
    if not territory or not territory.features.process then return end
    
    local processType = territory.features.process.type
    local recipe = ProcessRecipes[processType] and ProcessRecipes[processType][recipeIndex]
    if not recipe then return end
    
    -- Give output items
    for item, amount in pairs(recipe.output) do
        exports.ox_inventory:AddItem(src, item, amount)
    end
    
    -- Apply territory bonus if applicable
    local bonus = 1.0
    if territory.control == Player.PlayerData.gang.name then
        bonus = Config.Gangs.territoryBonus.processSpeed
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('process_complete'),
        type = 'success'
    })
    
    -- Economy tax
    if Config.Economy.enabled and Config.Economy.tax.processing > 0 then
        local taxAmount = math.floor(100 * Config.Economy.tax.processing)
        TriggerEvent('territories:server:addTerritoryMoney', territoryId, taxAmount)
    end
end)
