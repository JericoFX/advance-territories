lib.locale()
local QBCore = exports['qb-core']:GetCoreObject()

local permissions = {
    manage_stash = 0,
    process_drugs = 0,
    sell_drugs = 0,
    collect_tax = 1,
    start_delivery = 1,
    manage_members = 2,
    declare_war = 3,
    manage_territory = 3,
    access_garage = 0,
    manage_vehicles = 2,
    start_missions = 1,
    capture_spy = 0
}

local function hasPermission(player, action)
    if not player then return false end
    
    local requiredGrade = permissions[action]
    if not requiredGrade then return true end
    
    return player.PlayerData.gang.grade.level >= requiredGrade
end

lib.addCommand('gang.promote', {
    help = locale('promote_help'),
    restricted = false,
    params = {
        {
            name = 'target',
            type = 'player',
            help = locale('target_player')
        }
    }
}, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(args.target)
    
    if not Player or not Target then return end
    
    if not hasPermission(Player, 'manage_members') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_permission'),
            type = 'error'
        })
        return
    end
    
    if Player.PlayerData.gang.name ~= Target.PlayerData.gang.name then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('different_gang'),
            type = 'error'
        })
        return
    end
    
    local currentGrade = Target.PlayerData.gang.grade.level
    local maxGrade = Player.PlayerData.gang.grade.level - 1
    
    if currentGrade >= maxGrade then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('cannot_promote_higher'),
            type = 'error'
        })
        return
    end
    
    local newGrade = currentGrade + 1
    Target.Functions.SetGang(Target.PlayerData.gang.name, newGrade)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('member_promoted'),
        type = 'success'
    })
    
    TriggerClientEvent('ox_lib:notify', args.target, {
        title = locale('promotion'),
        description = locale('you_were_promoted'),
        type = 'success'
    })
end)

lib.addCommand('gang.demote', {
    help = locale('demote_help'),
    restricted = false,
    params = {
        {
            name = 'target',
            type = 'player',
            help = locale('target_player')
        }
    }
}, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(args.target)
    
    if not Player or not Target then return end
    
    if not hasPermission(Player, 'manage_members') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_permission'),
            type = 'error'
        })
        return
    end
    
    if Player.PlayerData.gang.name ~= Target.PlayerData.gang.name then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('different_gang'),
            type = 'error'
        })
        return
    end
    
    local currentGrade = Target.PlayerData.gang.grade.level
    
    if currentGrade <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('cannot_demote_lower'),
            type = 'error'
        })
        return
    end
    
    if currentGrade >= Player.PlayerData.gang.grade.level then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('cannot_demote_equal_higher'),
            type = 'error'
        })
        return
    end
    
    local newGrade = currentGrade - 1
    Target.Functions.SetGang(Target.PlayerData.gang.name, newGrade)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('member_demoted'),
        type = 'success'
    })
    
    TriggerClientEvent('ox_lib:notify', args.target, {
        title = locale('demotion'),
        description = locale('you_were_demoted'),
        type = 'error'
    })
end)

lib.addCommand('gang.kick', {
    help = locale('kick_help'),
    restricted = false,
    params = {
        {
            name = 'target',
            type = 'player',
            help = locale('target_player')
        }
    }
}, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(args.target)
    
    if not Player or not Target then return end
    
    if not hasPermission(Player, 'manage_members') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('no_permission'),
            type = 'error'
        })
        return
    end
    
    if Player.PlayerData.gang.name ~= Target.PlayerData.gang.name then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('different_gang'),
            type = 'error'
        })
        return
    end
    
    if Target.PlayerData.gang.grade.level >= Player.PlayerData.gang.grade.level then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('cannot_kick_equal_higher'),
            type = 'error'
        })
        return
    end
    
    Target.Functions.SetGang('none', 0)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('success'),
        description = locale('member_kicked'),
        type = 'success'
    })
    
    TriggerClientEvent('ox_lib:notify', args.target, {
        title = locale('kicked'),
        description = locale('you_were_kicked'),
        type = 'error'
    })
end)

lib.callback.register('territories:checkPermission', function(source, action)
    local Player = QBCore.Functions.GetPlayer(source)
    return hasPermission(Player, action)
end)

return {
    hasPermission = hasPermission,
    permissions = permissions
}
