fx_version 'cerulean'
game 'gta5'

name 'md_carryprops'
author 'md_carryprops'
description 'Modernes Prop- und Carry-System für Roleplay-Server'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/framework.lua',
    'client/notify.lua',
    'client/push.lua',
    'client/carry.lua',
    'client/placement.lua',
    'client/menu.lua',
    'client/main.lua',
}

server_scripts {
    'server/framework.lua',
    'server/main.lua',
}

dependencies {
    -- Keine harten Abhängigkeiten – Script ist standalone-fähig
}
