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
       '@oxmysql/lib/MySQL.lua',
    'server/**.lua',
 
}
shared_script {
    'config.lua',
}
