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

RegisterNetEvent('territories:client:startTerritoryCreator', function()
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
    
    startLaboratorySetup(name, {
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

local setupData = {}
local settingUpLab = false

function startLaboratorySetup(name, zoneData)
    settingUpLab = true
    setupData = {
        name = name,
        zone = zoneData,
        features = {},
        drugs = {}
    }
    
    lib.notify({
        title = locale('lab_setup_started'),
        description = locale('lab_setup_instructions'),
        type = 'info'
    })
    
    selectDrugType()
end

function selectDrugType()
    local input = lib.inputDialog(locale('select_drug_type'), {
        {type = 'select', label = locale('drug_type'), options = {
            {value = 'weed', label = locale('weed')},
            {value = 'cocaine', label = locale('cocaine')},
            {value = 'meth', label = locale('meth')},
            {value = 'crack', label = locale('crack')}
        }, required = true}
    })
    
    if not input then
        cancelLaboratorySetup()
        return
    end
    
    setupData.drugs = {input[1]}
    
    lib.notify({
        title = locale('drug_type_selected'),
        description = locale('drug_type_selected_desc', input[1]),
        type = 'success'
    })
    
    Wait(1000)
    setupLabEntryPoint()
end

function setupLabEntryPoint()
    lib.notify({
        title = locale('setup_lab_entry'),
        description = locale('setup_lab_entry_desc'),
        type = 'info'
    })
    
    lib.showTextUI(locale('set_entry_point'), {
        position = 'top-center',
        icon = 'door-open'
    })
    
    CreateThread(function()
        while settingUpLab do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                setupData.features.labEntry = {
                    coords = coords,
                    heading = heading,
                    drugType = setupData.drugs[1]
                }
                
                lib.hideTextUI()
                lib.notify({
                    title = locale('entry_point_set'),
                    description = locale('entry_point_set_desc'),
                    type = 'success'
                })
                
                Wait(1000)
                setupStashPoint()
                break
            elseif IsControlJustPressed(0, 73) then -- X
                cancelLaboratorySetup()
                break
            end
        end
    end)
end

function setupStashPoint()
    lib.notify({
        title = locale('setup_stash'),
        description = locale('setup_stash_desc'),
        type = 'info'
    })
    
    lib.showTextUI(locale('set_stash_point'), {
        position = 'top-center',
        icon = 'box'
    })
    
    CreateThread(function()
        while settingUpLab do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                setupData.features.stash = {
                    coords = coords,
                    heading = heading
                }
                
                lib.hideTextUI()
                lib.notify({
                    title = locale('stash_point_set'),
                    description = locale('stash_point_set_desc'),
                    type = 'success'
                })
                
                Wait(1000)
                setupGaragePoint()
                break
            elseif IsControlJustPressed(0, 73) then -- X
                cancelLaboratorySetup()
                break
            end
        end
    end)
end

function setupGaragePoint()
    lib.notify({
        title = locale('setup_garage'),
        description = locale('setup_garage_desc'),
        type = 'info'
    })
    
    lib.showTextUI(locale('set_garage_point'), {
        position = 'top-center',
        icon = 'warehouse'
    })
    
    CreateThread(function()
        while settingUpLab do
            Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                setupData.features.garage = {
                    coords = coords,
                    heading = heading,
                    spawn = vec4(coords.x + 5.0, coords.y + 5.0, coords.z, heading)
                }
                
                lib.hideTextUI()
                lib.notify({
                    title = locale('garage_point_set'),
                    description = locale('garage_point_set_desc'),
                    type = 'success'
                })
                
                Wait(1000)
                setupProcessPoint()
                break
            elseif IsControlJustPressed(0, 73) then -- X
                cancelLaboratorySetup()
                break
            end
        end
    end)
end

function setupProcessPoint()
    local processData = getPredefinedProcessData(setupData.drugs[1])
    
    setupData.features.process = processData
    
    lib.notify({
        title = locale('process_point_set'),
        description = locale('process_point_auto_configured'),
        type = 'success'
    })
    
    Wait(1000)
    finishLaboratorySetup()
end

function getPredefinedProcessData(drugType)
    local processData = {
        weed = {
            coords = vec3(1051.491, -3196.536, -39.14842),
            heading = 0.0,
            type = 'weed',
            scene = {
                type = 'Weed',
                num = 2,
                offset = vec3(0.0, 0.896, 0.0),
                rotation = vec3(0.0, 0.0, 90.0)
            }
        },
        cocaine = {
            coords = vec3(1093.6, -3196.6, -38.99841),
            heading = 180.0,
            type = 'cocaine',
            scene = {
                type = 'Cocaine',
                num = 2,
                offset = vec3(7.663, -2.222, 0.395),
                rotation = vec3(0.0, 0.0, 0.0)
            }
        },
        meth = {
            coords = vec3(1009.5, -3196.6, -38.99682),
            heading = 270.0,
            type = 'meth',
            scene = {
                type = 'Meth',
                num = 1,
                offset = vec3(-4.88, -1.95, 0.0),
                rotation = vec3(0.0, 0.0, 0.0)
            }
        },
        crack = {
            coords = vec3(1009.5, -3196.6, -38.99682),
            heading = 270.0,
            type = 'crack',
            scene = {
                type = 'Meth',
                num = 1,
                offset = vec3(0.0, 0.0, 0.0),
                rotation = vec3(0.0, 0.0, 45.0)
            }
        }
    }
    
    return processData[drugType] or processData.weed
end

function getSceneDataForDrug(drugType)
    local scenes = {
        weed = {
            type = 'Weed',
            num = 2,
            offset = vec3(0.0, 0.896, 0.0),
            rotation = vec3(0.0, 0.0, 90.0)
        },
        cocaine = {
            type = 'Cocaine',
            num = 2,
            offset = vec3(7.663, -2.222, 0.395),
            rotation = vec3(0.0, 0.0, 0.0)
        },
        meth = {
            type = 'Meth',
            num = 1,
            offset = vec3(-4.88, -1.95, 0.0),
            rotation = vec3(0.0, 0.0, 0.0)
        },
        crack = {
            type = 'Meth',
            num = 1,
            offset = vec3(0.0, 0.0, 0.0),
            rotation = vec3(0.0, 0.0, 45.0)
        }
    }
    
    return scenes[drugType] or scenes.weed
end

function finishLaboratorySetup()
    settingUpLab = false
    
    local center = setupData.zone.type == 'poly' and getPolygonCenter(setupData.zone.points) or setupData.zone.coords
    
    local territoryData = {
        name = setupData.name,
        type = setupData.zone.type,
        points = setupData.zone.points,
        thickness = setupData.zone.thickness,
        coords = setupData.zone.coords,
        size = setupData.zone.size,
        rotation = setupData.zone.rotation,
        features = setupData.features,
        drugs = setupData.drugs,
        capture = {
            point = center,
            radius = 20.0
        }
    }
    
    TriggerServerEvent('territories:server:createTerritory', territoryData)
    
    lib.notify({
        title = locale('lab_setup_complete'),
        description = locale('lab_setup_complete_desc', setupData.name),
        type = 'success'
    })
    
    setupData = {}
end

function cancelLaboratorySetup()
    settingUpLab = false
    setupData = {}
    lib.hideTextUI()
    
    lib.notify({
        title = locale('cancelled'),
        description = locale('lab_setup_cancelled'),
        type = 'error'
    })
end

function getPolygonCenter(points)
    local x, y, z = 0, 0, 0
    for _, point in ipairs(points) do
        x = x + point.x
        y = y + point.y
        z = z + point.z
    end
    return vec3(x / #points, y / #points, z / #points)
end
