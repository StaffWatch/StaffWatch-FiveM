Config = {

    -- Do not change these values
    DEBUG = true,
    API_URL = "http://localhost:3001",

    -- Found on the manage servers page
    SECRET = "ubxPHQwNJPlPiZkXhPou",

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