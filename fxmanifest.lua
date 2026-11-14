fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

name 'cobalt_hud'
author 'Citgo'
description 'Project Cobalt HUD: status circles, speedometer and a per-character layout editor'
version '1.0.0'

dependencies {
    'cobalt_mysql',
    'ox_lib',
    'cobalt_core',
}

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'

server_scripts {
    '@cobalt_mysql/lib/MySQL.lua',
    '@cobalt_core/server/migrationgate.lua',
    'server/main.lua',
}

ui_page '_nui/build/index.html'

files {
    'config.lua',
    'config/*.lua',
    'client/*.lua',
    '_nui/build/index.html',
    '_nui/build/**/*',
}
