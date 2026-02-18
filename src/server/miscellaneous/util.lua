CreatePlayerDTO = function(name, playerId)

    -- Basic player data
    local playerDto = {}
    playerDto.inGameId = playerId
    playerDto.playerName = name or GetPlayerName(playerId)
    playerDto.identifiers = {}

    -- Player identifiers
    local identifers = GetPlayerIdentifiers(playerId)
    for i = 1, #identifers do
        local ident = identifers[i]
        local colonPosition = string.find(ident, ":") - 1
        local identifierType = string.sub(ident, 1, colonPosition)
        table.insert(playerDto.identifiers, {
            name = identifierType,
            value = string.sub(ident, colonPosition + 2)
        })
    end

    -- Return player object
    return playerDto

end

GetPlayerIdByLicense = function (license)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        if (playerId ~= nil) then
            local playerLicense = GetPlayerIdentifierByType(playerId, "license")
            if (string.sub(playerLicense, 9) == license) then
                return playerId
            end
        end
    end
    return nil
end

GetPlayerPrimaryIdentifier = function (playerId)
    if (playerId == nil) then return nil end
    local playerLicense = GetPlayerIdentifierByType(playerId, "license")
    return string.sub(playerLicense, 9)
end

SendChatMessage = function (playerId, message)
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {31, 214, 255},
        multiline = false,
        args = {"[StaffWatch] ", message}
    })
end

DebugLog = function(msg)
    if (Config.DEBUG) then
        print(msg)
    end
end

InputReplace = function(message, hint, content)
    return message:gsub("{" .. hint .. "}", content)
end

SendAPIRequest = function(endpoint, data)
    -- Create full URL and log the request
    local url = Config.API_URL .. endpoint
    DebugLog("API Request: " .. url)
    DebugLog("Request Data: " .. json.encode(data))
    
    -- Send the request to the server
    local status, resultData, _, errorData = PerformHttpRequestAwait(
        url, "POST", json.encode(data), {["Content-Type"] = 'application/json'}
    )

    if (status ~= 200) then
        -- Mask the secret in the request
        if (data.secret) then
            data.secret = "************"
        end

        -- Log the error and return failure
        print("-------------------------------------------------------------")
        print("API Request Failed | URL: " .. url .. " | Status: " .. status)
        print("Request Data: " .. json.encode(data))
        print("Error Response: " .. errorData)
        print("-------------------------------------------------------------")
        return false, errorData
    else
        -- Log the successful response and return success
        DebugLog("Response (" .. status .. "): " .. resultData)
        return true, resultData
    end
end