local labCoordinates = {
    weed = vec3(1066.0, -3183.0, -39.0),
    cocaine = vec3(1093.0, -3195.0, -39.0),
    meth = vec3(997.0, -3200.0, -36.0)
}

local function loadLabInteriors()
    -- Meth Lab
    local methCoords = {1009.5, -3196.6, -38.99682}
    local methInteriorID = GetInteriorAtCoords(methCoords[1], methCoords[2], methCoords[3])
    
    if IsValidInterior(methInteriorID) then
        LoadInterior(methInteriorID)
        EnableInteriorProp(methInteriorID, "meth_lab_security_high")
        EnableInteriorProp(methInteriorID, "meth_lab_upgrade")
        RefreshInterior(methInteriorID)
    end
    
    -- Weed Lab
    local weedCoords = {1051.491, -3196.536, -39.14842}
    local weedInteriorID = GetInteriorAtCoords(weedCoords[1], weedCoords[2], weedCoords[3])
    
    if IsValidInterior(weedInteriorID) then
        LoadInterior(weedInteriorID)
        -- Enable weed production props
        EnableInteriorProp(weedInteriorID, "weed_drying")
        EnableInteriorProp(weedInteriorID, "weed_production")
        EnableInteriorProp(weedInteriorID, "weed_upgrade_equip")
        EnableInteriorProp(weedInteriorID, "weed_growtha_stage3")
        EnableInteriorProp(weedInteriorID, "weed_growthb_stage2")
        EnableInteriorProp(weedInteriorID, "weed_growthc_stage1")
        EnableInteriorProp(weedInteriorID, "weed_growthd_stage1")
        EnableInteriorProp(weedInteriorID, "weed_growthe_stage2")
        EnableInteriorProp(weedInteriorID, "weed_growthf_stage2")
        EnableInteriorProp(weedInteriorID, "weed_growthg_stage1")
        EnableInteriorProp(weedInteriorID, "weed_growthh_stage3")
        EnableInteriorProp(weedInteriorID, "weed_growthi_stage2")
        EnableInteriorProp(weedInteriorID, "weed_security_upgrade")
        EnableInteriorProp(weedInteriorID, "weed_chairs")
        -- Lighting
        EnableInteriorProp(weedInteriorID, "light_growtha_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthb_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthc_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthd_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthe_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthf_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthg_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthh_stage23_upgrade")
        EnableInteriorProp(weedInteriorID, "light_growthi_stage23_upgrade")
        RefreshInterior(weedInteriorID)
    end
    
    -- Cocaine Lab
    local cokeCoords = {1093.6, -3196.6, -38.99841}
    local cokeInteriorID = GetInteriorAtCoords(cokeCoords[1], cokeCoords[2], cokeCoords[3])
    
    if IsValidInterior(cokeInteriorID) then
        LoadInterior(cokeInteriorID)
        EnableInteriorProp(cokeInteriorID, "security_high")
        EnableInteriorProp(cokeInteriorID, "equipment_upgrade")
        EnableInteriorProp(cokeInteriorID, "production_upgrade")
        EnableInteriorProp(cokeInteriorID, "table_equipment_upgrade")
        EnableInteriorProp(cokeInteriorID, "coke_press_upgrade")
        EnableInteriorProp(cokeInteriorID, "coke_cut_01")
        EnableInteriorProp(cokeInteriorID, "coke_cut_02")
        EnableInteriorProp(cokeInteriorID, "coke_cut_03")
        RefreshInterior(cokeInteriorID)
    end
end

local function loadDrugLabIPLs()
    -- Biker DLC Interior IPLs
    RequestIpl("bkr_biker_interior_placement_interior_0_biker_dlc_int_01_milo")
    RequestIpl("bkr_biker_interior_placement_interior_1_biker_dlc_int_02_milo")
    RequestIpl("bkr_biker_interior_placement_interior_2_biker_dlc_int_ware01_milo")
    RequestIpl("bkr_biker_interior_placement_interior_3_biker_dlc_int_ware02_milo")
    RequestIpl("bkr_biker_interior_placement_interior_4_biker_dlc_int_ware03_milo")
    RequestIpl("bkr_biker_interior_placement_interior_5_biker_dlc_int_ware04_milo")
    RequestIpl("bkr_biker_interior_placement_interior_6_biker_dlc_int_ware05_milo")
    
    loadLabInteriors()
end

CreateThread(function()
    Wait(1000)
    loadDrugLabIPLs()
end)

exports('LoadTerritoryIPL', function(iplName)
    if iplName then
        RequestIpl(iplName)
        loadLabInteriors()
    end
end)

exports('GetLabCoords', function(labType)
    return labCoordinates[labType]
end)
