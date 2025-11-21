fx_version 'cerulean'
game 'gta5'

author 'StaffWatch'
description 'FiveM integration for the StaffWatch web panel'
version '1.0.0'
server_scripts {
    "config.lua",
    "/src/server/register.lua",
    "/src/server/util.lua",
    "/src/server/playerJoin.lua",
    "/src/server/recurringUpdate.lua",
    "/src/server/commands.lua",
    "/src/server/link.lua",
    "/src/server/staffrequests.lua",
    "/src/server/reportplayer.lua",
}
client_scripts {
    "/src/client/announcement.lua"
}