RegistrationResult = {}

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    local isRegistered = next(RegistrationResult) ~= nil
    while not isRegistered do
        pcall(TryRegister)
        Citizen.Wait(10000)
    end
end)

function TryRegister()
    local success, rawResponse = SendAPIRequest("/api/register", {
        secret = Config.SECRET,
        templatedActions = Config.TEMPLATED_ACTIONS
    })
    if (success) then
        local response = json.decode(rawResponse)
        RegistrationResult = response
    end
end

OrDefault = function(value, defaultValue)
    local result = RegistrationResult[value]
    if (result == nil) then
        DebugLog("Using default for " .. value .. ": " .. tostring(defaultValue))
        return defaultValue
    else
        return result
    end
end