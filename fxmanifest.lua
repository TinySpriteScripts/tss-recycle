fx_version 'cerulean'
game 'gta5'
author 'oosayeroo'
description 'tss-recycle'
version '1.0.2'
lua54 'yes'

client_scripts{
    'client/main.lua'
}

shared_scripts{
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts{
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}