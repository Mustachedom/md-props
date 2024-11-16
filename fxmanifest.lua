fx_version 'cerulean'
game 'gta5'

author 'md-props'
description 'prop spawn by vector'
version '1.0.2'
lua54 'yes'
client_script {
    'client/**.lua',
}

server_script {
    'server/**.lua',
    '@oxmysql/lib/MySQL.lua',
}
shared_script {
    'config.lua',
    '@ox_lib/init.lua'
}
