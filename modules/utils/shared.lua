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

exports('Utils', function()
    return Utils
end)
