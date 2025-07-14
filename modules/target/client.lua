local target = {}

---@param data table Zone data with coords, radius, debug, options
---@return number Zone ID
function target.addSphereZone(data)
    return exports.ox_target:addSphereZone(data)
end

---@param zoneId number Zone ID to remove
function target.removeZone(zoneId)
    return exports.ox_target:removeZone(zoneId)
end

return target
