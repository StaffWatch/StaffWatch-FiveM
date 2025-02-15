CreatePlayerDTO = function(name, playerId)

    -- Basic player data
    local playerDto = {}
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
            value = string.sub(ident, colonPosition + 1)
        })
    end

    -- Return player object
    return playerDto

end

DebugLog = function(msg)
    if (Config.DEBUG) then
        print(msg)
    end
end