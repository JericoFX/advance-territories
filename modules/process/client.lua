local QBCore = exports['qb-core']:GetCoreObject()
local isProcessing = false

local ProcessRecipes = {
    weed = {
        {
            label = locale('process_weed'),
            input = {['weed_leaf'] = 5},
            output = {['weed_skunk'] = 1},
            time = 30000
        }
    },
    cocaine = {
        {
            label = locale('process_cocaine'),
            input = {['coca_leaf'] = 10},
            output = {['coke_brick'] = 1},
            time = 60000
        }
    },
    meth = {
        {
            label = locale('cook_meth'),
            input = {['chemicals'] = 3, ['empty_bag'] = 1},
            output = {['meth'] = 1},
            time = 75000
        }
    },
    crack = {
        {
            label = locale('cook_crack'),
            input = {['coke_brick'] = 1, ['bakingsoda'] = 2},
            output = {['crack'] = 3},
            time = 45000
        }
    }
}

local function hasRequiredItems(items)
    for item, amount in pairs(items) do
        if exports.ox_inventory:GetItemCount(item) < amount then
            return false
        end
    end
    return true
end

RegisterNetEvent('territories:client:openProcess', function(territoryId)
    local territory = Territories[territoryId]
    if not territory or not territory.features.process then return end
    
    local processType = territory.features.process.type
    local recipes = ProcessRecipes[processType]
    
    if not recipes then
        lib.notify({
            title = locale('error'),
            description = locale('no_recipes'),
            type = 'error'
        })
        return
    end
    
    if isProcessing then
        lib.notify({
            title = locale('error'),
            description = locale('already_processing'),
            type = 'error'
        })
        return
    end
    
    local options = {}
    for i, recipe in ipairs(recipes) do
        local hasItems = hasRequiredItems(recipe.input)
        local metadata = {}
        
        for item, amount in pairs(recipe.input) do
            table.insert(metadata, ('%s x%d'):format(item, amount))
        end
        
        table.insert(options, {
            title = recipe.label,
            description = table.concat(metadata, ', '),
            icon = hasItems and 'circle-check' or 'circle-xmark',
            disabled = not hasItems or isProcessing,
            onSelect = function()
                TriggerServerEvent('territories:server:startProcess', territoryId, i)
            end
        })
    end
    
    lib.registerContext({
        id = 'process_menu',
        title = locale('process_menu'),
        options = options
    })
    
    lib.showContext('process_menu')
end)

RegisterNetEvent('territories:client:startProcess', function(territoryId, recipeIndex)
    local territory = Territories[territoryId]
    if not territory or not territory.features.process then return end
    
    local processType = territory.features.process.type
    local recipe = ProcessRecipes[processType][recipeIndex]
    if not recipe then return end
    
    isProcessing = true
    
    -- Teleport to lab if needed
    if processType ~= 'crack' then
        local labCoords = exports[GetCurrentResourceName()]:GetLabCoords(processType)
        if labCoords then
            DoScreenFadeOut(500)
            Wait(500)
            
            -- Request bucket assignment
            TriggerServerEvent('territories:server:requestLabBucket', processType)
            Wait(100)
            
            SetEntityCoords(PlayerPedId(), labCoords.x, labCoords.y, labCoords.z, false, false, false, false)
            Wait(500)
            DoScreenFadeIn(500)
        end
    end
    
    -- Start processing scene if enabled
    if Config.Processing.scenes and territory.features.process.scene then
        TriggerEvent('territories:client:startProcessingScene', territory.features.process, recipe.time)
    end
    
    -- Progress bar
    local progress = lib.progressCircle({
        duration = recipe.time,
        position = 'bottom',
        label = recipe.label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
    
    isProcessing = false
    
    if progress then
        TriggerServerEvent('territories:server:completeProcess', territoryId, recipeIndex)
    else
        TriggerEvent('territories:client:stopProcessingScene')
        lib.notify({
            title = locale('cancelled'),
            description = locale('process_cancelled'),
            type = 'error'
        })
    end
    
    -- Teleport back if in lab
    if processType ~= 'crack' then
        DoScreenFadeOut(500)
        Wait(500)
        
        -- Exit bucket
        TriggerServerEvent('territories:server:exitLabBucket')
        Wait(100)
        
        SetEntityCoords(PlayerPedId(), territory.features.process.coords.x, territory.features.process.coords.y, territory.features.process.coords.z, false, false, false, false)
        Wait(500)
        DoScreenFadeIn(500)
    end
end)
