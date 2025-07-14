local QBCore = exports['qb-core']:GetCoreObject()
local creatingTerritory = false
local currentPoints = {}
local creatorBlips = {}

local function clearCreatorBlips()
    for _, blip in ipairs(creatorBlips) do
        RemoveBlip(blip)
    end
    creatorBlips = {}
end

local function createPointBlip(coords, index)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(("Point %d"):format(index))
    EndTextCommandSetBlipName(blip)
    return blip
end

lib.addCommand('createterritory', {
    help = locale('create_territory_help'),
    restricted = 'group.admin'
}, function()
    if creatingTerritory then
        lib.notify({
            title = locale('error'),
            description = locale('already_creating'),
            type = 'error'
        })
        return
    end
    
    local input = lib.inputDialog(locale('territory_creator'), {
        {type = 'input', label = locale('territory_name'), required = true},
        {type = 'select', label = locale('zone_type'), options = {
            {value = 'poly', label = locale('polygon')},
            {value = 'box', label = locale('box')}
        }, required = true}
    })
    
    if not input then return end
    
    local name = input[1]
    local zoneType = input[2]
    
    if zoneType == 'poly' then
        startPolyCreation(name)
    else
        startBoxCreation(name)
    end
end)

function startPolyCreation(name)
    creatingTerritory = true
    currentPoints = {}
    clearCreatorBlips()
    
    lib.showTextUI(locale('poly_instructions'), {
        position = 'top-center',
        icon = 'location-dot'
    })
    
    CreateThread(function()
        while creatingTerritory do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
                local point = vec3(coords.x, coords.y, groundZ)
                
                table.insert(currentPoints, point)
                table.insert(creatorBlips, createPointBlip(point, #currentPoints))
                
                lib.notify({
                    title = locale('point_added'),
                    description = locale('point_count', #currentPoints),
                    type = 'success'
                })
                
                if #currentPoints >= 3 then
                    lib.showTextUI(locale('poly_finish_instructions'), {
                        position = 'top-center',
                        icon = 'location-dot'
                    })
                end
            elseif IsControlJustPressed(0, 191) and #currentPoints >= 3 then -- Enter
                finishPolyCreation(name)
            elseif IsControlJustPressed(0, 73) then -- X
                cancelCreation()
            end
        end
    end)
end

function startBoxCreation(name)
    creatingTerritory = true
    clearCreatorBlips()
    
    lib.showTextUI(locale('box_instructions'), {
        position = 'top-center',
        icon = 'cube'
    })
    
    CreateThread(function()
        local startCoords = nil
        local endCoords = nil
        local preview = nil
        
        while creatingTerritory do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                
                if not startCoords then
                    startCoords = coords
                    table.insert(creatorBlips, createPointBlip(startCoords, 1))
                    
                    lib.showTextUI(locale('box_second_point'), {
                        position = 'top-center',
                        icon = 'cube'
                    })
                else
                    endCoords = coords
                    finishBoxCreation(name, startCoords, endCoords)
                end
            elseif IsControlJustPressed(0, 73) then -- X
                if preview then
                    DeleteEntity(preview)
                end
                cancelCreation()
            end
            
            -- Preview box
            if startCoords and not endCoords then
                local ped = PlayerPedId()
                local currentCoords = GetEntityCoords(ped)
                
                DrawBox(
                    startCoords.x, startCoords.y, startCoords.z,
                    currentCoords.x, currentCoords.y, currentCoords.z,
                    255, 255, 255, 100
                )
            end
        end
    end)
end

function finishPolyCreation(name)
    creatingTerritory = false
    lib.hideTextUI()
    clearCreatorBlips()
    
    local thickness = lib.inputDialog(locale('zone_thickness'), {
        {type = 'slider', label = locale('thickness'), min = 10, max = 100, default = 30}
    })
    
    if not thickness then
        cancelCreation()
        return
    end
    
    TriggerServerEvent('territories:server:createTerritory', {
        name = name,
        type = 'poly',
        points = currentPoints,
        thickness = thickness[1]
    })
    
    currentPoints = {}
end

function finishBoxCreation(name, startCoords, endCoords)
    creatingTerritory = false
    lib.hideTextUI()
    clearCreatorBlips()
    
    local center = vec3(
        (startCoords.x + endCoords.x) / 2,
        (startCoords.y + endCoords.y) / 2,
        (startCoords.z + endCoords.z) / 2
    )
    
    local size = vec3(
        math.abs(endCoords.x - startCoords.x),
        math.abs(endCoords.y - startCoords.y),
        math.abs(endCoords.z - startCoords.z) + 30
    )
    
    TriggerServerEvent('territories:server:createTerritory', {
        name = name,
        type = 'box',
        coords = center,
        size = size,
        rotation = 0
    })
end

function cancelCreation()
    creatingTerritory = false
    currentPoints = {}
    lib.hideTextUI()
    clearCreatorBlips()
    
    lib.notify({
        title = locale('cancelled'),
        description = locale('territory_creation_cancelled'),
        type = 'error'
    })
end
