Config = {

    -- Do not change these values
    DEBUG = false,
    API_URL = "https://api.staffwatch.app",

    -- Found on the manage servers page
    SECRET = "ENTER_SERVER_SECRET_HERE",

    -- Allow join when connection fails?
    BYPASS_ON_FAILURE = true,

    -- Broadcast moderation actions (warnings, kicks, bans, etc...) to the chat for other players to see?
    BROADCAST_ACTIONS_TO_SERVER = true,

    -- Show moderator that banned player when they join?
    SHOW_SOURCE_OF_ACTION = true,

    -- Configure templated actions
    TEMPLATED_ACTIONS = {
        {
            scope = "PLAYER",
            name = "Freeze",
            command = "sw_freeze"
        },
        {
            scope = "PLAYER",
            name = "Unfreeze",
            command = "sw_unfreeze"
        },
        -- Demo commands below to show how templated actions can be configured
        -- Note that player scoped commands can also have arguments (max of 3)
        -- {
        --     scope = "SERVER",
        --     name = "Toggle Priority Cooldown",
        --     command = "togglepriority",
        -- },
        -- {
        --     scope = "SERVER",
        --     name = "Set Weather",
        --     command = "weather",
        --     arg1Name = "Weather Type (ex: CLEAR, RAIN, FOGGY)",
        -- },
    }

}
