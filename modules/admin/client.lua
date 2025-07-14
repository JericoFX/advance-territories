local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('territories:client:adminMenu', function(territories)
    local options = {}
    
    for zoneId, data in pairs(territories) do
        table.insert(options, {
            title = data.label,
            description = ('Control: %s | Influence: %d%%'):format(data.control, data.influence),
            metadata = {
                {label = 'Zone ID', value = zoneId},
                {label = 'Treasury', value = ('$%d'):format(data.treasury or 0)}
            },
            onSelect = function()
                lib.inputDialog(locale('admin_territory_edit'), {
                    {type = 'select', label = locale('control'), options = {
                        {value = 'neutral', label = 'Neutral'},
                        {value = 'ballas', label = 'Ballas'},
                        {value = 'vagos', label = 'Vagos'},
                        {value = 'families', label = 'Families'},
                        {value = 'lostmc', label = 'Lost MC'}
                    }, default = data.control},
                    {type = 'slider', label = locale('influence'), min = 0, max = 100, default = data.influence}
                }, function(input)
                    if input then
                        TriggerServerEvent('territories:server:adminUpdate', zoneId, input[1], input[2])
                    end
                end)
            end
        })
    end
    
    lib.registerContext({
        id = 'admin_territories',
        title = locale('admin_menu'),
        options = options
    })
    
    lib.showContext('admin_territories')
end)
