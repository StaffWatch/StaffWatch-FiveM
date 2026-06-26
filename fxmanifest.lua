fx_version 'cerulean'
game 'gta5'

author 'StaffWatch'
description 'FiveM integration for the StaffWatch web panel'
version '1.2.0'

dependency 'ox_lib'

shared_script '@ox_lib/init.lua'

server_scripts {
    "version.lua",
    "config.lua",
    "/src/server/commands/link.lua",
    "/src/server/commands/portal.lua",
    "/src/server/commands/report_player.lua",
    "/src/server/commands/staff_request.lua",
    "/src/server/commands/staff_actions.lua",
    "/src/server/commands/system_commands.lua",
    "/src/server/events/logging_events.lua",
    "/src/server/events/player_connecting.lua",
    "/src/server/events/player_join.lua",
    "/src/server/events/player_leave.lua",
    "/src/server/miscellaneous/registration.lua",
    "/src/server/miscellaneous/util.lua",
    "/src/server/scheduled/command_queue.lua",
    "/src/server/scheduled/recurring_update.lua",
    "/src/server/scheduled/upload_logs.lua",
    "/src/server/scheduled/live_server.lua",
    "/src/server/events/remote_action.lua",
    "/src/server/events/menu.lua",
}

client_scripts {
    "client_config.lua",
    "/src/client/announcement.lua",
    "/src/client/command_suggestions.lua",
    "/src/client/death_tracker.lua",
    "/src/client/freeze.lua",
    "/src/client/notify.lua",
    "/src/client/live_client.lua",
    "/src/client/menu.lua",
}

files {
    '/src/resources/announce_logo.png'
}
