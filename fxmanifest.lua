fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Advanced Development'
description 'Advanced Territory Control System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'data/config.lua',
    'data/territories.lua',
    'modules/utils/shared.lua'
}

client_scripts {
    'modules/target/client.lua',
    'modules/zones/client.lua',
    'modules/territories/client.lua',
    'modules/capture/client.lua',
    'modules/economy/client.lua',
    'modules/drugs/client.lua',
    'modules/garage/client.lua',
    'modules/stash/client.lua',
    'modules/process/client.lua',
    'modules/ipl/client.lua',
    'modules/scenes/client.lua',
    'modules/spy/client.lua',
    'modules/delivery/client.lua',
    'modules/police/client.lua',
    'modules/arrest/client.lua',
    'modules/ui/client.lua',
    'modules/admin/client.lua',
    'modules/creator/client.lua',
    'client/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/sync/server.lua',
    'modules/zones/server.lua',
    'modules/territories/server.lua',
    'modules/capture/server.lua',
    'modules/economy/server.lua',
    'modules/drugs/server.lua',
    'modules/garage/server.lua',
    'modules/stash/server.lua',
    'modules/process/server.lua',
    'modules/spy/server.lua',
    'modules/delivery/server.lua',
    'modules/police/server.lua',
    'modules/buckets/server.lua',
    'modules/admin/server.lua',
    'modules/creator/server.lua',
    'server/init.lua'
}

files {
    'locales/*.json',
    'modules/scenes/data.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'qb-core',
    'ox_target'
}
