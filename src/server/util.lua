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
        local playerLicense = GetPlayerIdentifierByType(playerId, "license")
        if (string.sub(playerLicense, 9) == license) then
            return playerId
        end
    end
    return nil
end

GetPlayerPrimaryIdentifier = function (playerId)
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

SendGlobalMessage = function (message)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        SendChatMessage(playerId, message)
    end
end

DebugLog = function(msg)
    if (Config.DEBUG) then
        print(msg)
    end
end

InputReplace = function(message, hint, content)
    return message:gsub("{" .. hint .. "}", content)
end