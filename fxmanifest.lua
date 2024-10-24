fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'MaDHouSe'
description 'MH Brakes'
version '1.0'

shared_scripts {'@ox_lib/init.lua', '@qb-core/shared/locale.lua', 'locales/en.lua','config.lua'}
client_scripts {'client/main.lua'}
server_scripts {'@oxmysql/lib/MySQL.lua', 'server/sv_config.lua', 'server/main.lua', 'server/update.lua'}
