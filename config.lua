Config = {

    -- Do not change these values
    DEBUG = true,
    API_URL = "http://localhost",

    -- Found on the manage servers page
    SECRET = "GAcjvGQmmqCdRYjLgdGo",

    -- Allow join when connection fails?
    BYPASS_ON_FAILURE = true,

    -- Configure templated actions
    TEMPLATED_ACTIONS = {
        {
            playerLevel = true,
            name = "Freeze",
            command = "sw_freeze"
        },
        {
            playerLevel = true,
            name = "Unfreeze",
            command = "sw_unfreeze"
        },
    }

}