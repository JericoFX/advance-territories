local resourceName = GetCurrentResourceName()

Utils = {}

---@param job string
---@return boolean
function Utils.isPoliceJob(job)
    for _, policeJob in ipairs(Config.Police.jobs) do
        if job == policeJob then
            return true
        end
    end
    return false
end

---@param gang string
---@return boolean
function Utils.isValidGang(gang)
    return gang ~= nil and gang ~= 'none' and gang ~= ''
end

---@param territory table
---@param gang string
---@return boolean
function Utils.hasAccess(territory, gang)
    if territory.control == 'neutral' then
        return true
    end
    return territory.control == gang
end

---@param coords vector3
---@param point vector3
---@param radius number
---@return boolean
function Utils.isInRadius(coords, point, radius)
    return #(coords - point) <= radius
end

---@param territoryId string
---@return table|nil
function Utils.getTerritory(territoryId)
    return Territories[territoryId]
end

---@param gang string
---@return number
function Utils.getBlipColor(gang)
    return Config.Blips.colors[gang] or Config.Blips.colors.neutral
end

---@param territory table
---@return vector3|nil
function Utils.getTerritoryCenter(territory)
    if not territory or not territory.zone then
        return territory and territory.capture and territory.capture.point or nil
    end

    if territory.zone.center then
        return territory.zone.center
    end

    if territory.zone.type == 'box' and territory.zone.coords then
        return territory.zone.coords
    end

    if territory.zone.type == 'poly' and type(territory.zone.points) == 'table' then
        local totalX, totalY, totalZ = 0.0, 0.0, 0.0
        local count = 0

        for _, point in ipairs(territory.zone.points) do
            totalX = totalX + point.x
            totalY = totalY + point.y
            totalZ = totalZ + point.z
            count = count + 1
        end

        if count > 0 then
            return vec3(totalX / count, totalY / count, totalZ / count)
        end
    end

    if territory.capture and territory.capture.point then
        return territory.capture.point
    end

    return nil
end

exports('Utils', function()
    return Utils
end)
