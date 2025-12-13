Config = {

    -- Do not change these values
    DEBUG = false,
    API_URL = "https://dev-api.staffwatch.app",

    -- Found on the manage servers page
    SECRET = "ENTER_SERVER_SECRET_HERE",

    -- Allow join when connection fails?
    BYPASS_ON_FAILURE = true,

    -- Configure templated actions
    TEMPLATED_ACTIONS = {
        {
            scope = "SERVER",
            name = "Set Time",
            command = "set time day"
        },
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
    }

}