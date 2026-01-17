Citizen.CreateThread(function()
    Citizen.Wait(5000)
    SendAPIRequest("/api/register", {
        secret = Config.SECRET,
        templatedActions = Config.TEMPLATED_ACTIONS
    })
end)