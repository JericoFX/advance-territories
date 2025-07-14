local sceneObjects = {}
local activeScene = nil

local function loadModel(model)
    local hash = GetHashKey(model)
    if not IsModelValid(hash) then return nil end
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end
    return hash
end

local function loadAnimDict(dict)
    if not DoesAnimDictExist(dict) then return false end
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    return true
end

local function createSceneObjects(sceneType, sceneNum, location)
    local objects = {}
    local items = SceneItems[sceneType]
    
    if not items or not items[sceneNum] then return objects end
    
    for key, model in pairs(items[sceneNum]) do
        local hash = loadModel(model)
        if hash then
            local obj = CreateObject(hash, location.x, location.y, location.z, true, true, false)
            SetEntityCollision(obj, false, false)
            FreezeEntityPosition(obj, true)
            objects[key] = obj
        end
    end
    
    return objects
end

local function startProcessingScene(processData)
    if activeScene then return false end
    
    local ped = PlayerPedId()
    local sceneType = processData.scene.type
    local sceneNum = processData.scene.num
    local location = vector3(
        processData.coords.x - processData.scene.offset.x,
        processData.coords.y - processData.scene.offset.y,
        processData.coords.z - processData.scene.offset.z
    )
    local rotation = processData.scene.rotation
    
    -- Start particle effects for drug labs
    if sceneType == 'Meth' then
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Wait(10)
        end
        UseParticleFxAssetNextCall("core")
        local particle = StartParticleFxLoopedAtCoord("ent_amb_smoke_factory_white", location.x, location.y, location.z + 1.0, 0.0, 0.0, 0.0, 0.5, false, false, false, false)
        SetParticleFxLoopedAlpha(particle, 0.8)
        sceneObjects.particle = particle
    elseif sceneType == 'Cocaine' then
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Wait(10)
        end
        UseParticleFxAssetNextCall("core")
        local particle = StartParticleFxLoopedAtCoord("ent_amb_smoke_general", location.x, location.y, location.z + 0.5, 0.0, 0.0, 0.0, 0.3, false, false, false, false)
        sceneObjects.particle = particle
    end
    
    local animDict = SceneDicts[sceneType] and SceneDicts[sceneType][sceneNum]
    local playerAnim = PlayerAnims[sceneType] and PlayerAnims[sceneType][sceneNum]
    local sceneAnims = SceneAnims[sceneType] and SceneAnims[sceneType][sceneNum]
    
    if not animDict or not playerAnim then return false end
    
    if not loadAnimDict(animDict) then return false end
    
    sceneObjects = createSceneObjects(sceneType, sceneNum, location)
    
    local scene = NetworkCreateSynchronisedScene(
        location.x, location.y, location.z,
        rotation.x, rotation.y, rotation.z,
        2, false, false, 1.0, 0, 1.0
    )
    
    NetworkAddPedToSynchronisedScene(ped, scene, animDict, playerAnim, 1.5, -4.0, 1, 16, 1148846080, 0)
    
    if sceneAnims then
        for key, obj in pairs(sceneObjects) do
            if sceneAnims[key] then
                NetworkAddEntityToSynchronisedScene(obj, scene, animDict, sceneAnims[key], 4.0, -8.0, 1)
            end
        end
    end
    
    NetworkStartSynchronisedScene(scene)
    activeScene = scene
    
    return true
end

local function stopProcessingScene()
    if activeScene then
        NetworkStopSynchronisedScene(activeScene)
        activeScene = nil
    end
    
    -- Stop particle effects
    if sceneObjects.particle then
        StopParticleFxLooped(sceneObjects.particle, false)
        RemoveParticleFx(sceneObjects.particle, false)
    end
    
    for key, obj in pairs(sceneObjects) do
        if key ~= 'particle' and DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    
    sceneObjects = {}
    ClearPedTasks(PlayerPedId())
end

RegisterNetEvent('territories:client:startProcessingScene', function(processData, duration)
    if Config.Processing.scenes and processData.scene then
        startProcessingScene(processData)
    end
    
    SetTimeout(duration, function()
        stopProcessingScene()
    end)
end)

RegisterNetEvent('territories:client:stopProcessingScene', function()
    stopProcessingScene()
end)

exports('isProcessing', function()
    return activeScene ~= nil
end)
