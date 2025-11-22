AddEventHandler('playerDropped', function (reason, resourceName, clientDropReason)

    -- Get player
    local playerDto = CreatePlayerDTO(nil, source)

    -- Convert DTO to json
    local jsonData = json.encode({
        secret = Config.SECRET,
        player = playerDto
    })

    DebugLog('Player leave JSON:')
    DebugLog(jsonData)

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/player-leave", "POST", jsonData, {["Content-Type"] = 'application/json'}
    )

    DebugLog(status)
    DebugLog(resultData)
    DebugLog(errorData)
    
    -- Handle failure
    if (status ~= 200) then
        print("Warning: Player leave request failed with status code: " .. status)
        print("Failure reason: " .. errorData)
        return
    end

end)