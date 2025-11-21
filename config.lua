Config = {

    -- Do not change these values
    DEBUG = true,
    API_URL = "http://localhost",

    -- Found on the manage servers page
    SECRET = "MdDayzFrrXmOJyqWWegA",

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