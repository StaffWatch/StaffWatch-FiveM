RegisterCommand("staffrequest", function(source, args, rawCommand)

    -- Disallow console execution
    if (source == 0) then
        print("Only players can execute this command!")
        return
    end

    -- Get reason
    local reason = string.match(rawCommand, "^%w+%s+(.*)")
    if (reason == nil) then
        SendChatMessage(source, "Invalid reason specified!")
        return
    end

    -- Get player primary identifier
    local primaryId = GetPlayerPrimaryIdentifier(source)
    if (primaryId == nil) then
        SendChatMessage(source, "No primary ID found for player!")
        return
    end

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/report", "POST", json.encode({
            type = "HELP",
            secret = Config.SECRET,
            reporterPrimaryIdentifier = primaryId,
            reason = reason
        }), {["Content-Type"] = 'application/json'}
    )

    -- Handle failure
    if (status ~= 200) then
        SendChatMessage(source, "Request failed! Error: " .. errorData)
        print("Warning: Request failed with status code: " .. status)
        print("Failure reason: " .. errorData)
        return
    end

    -- Get result from API call
    DebugLog(resultData)
    
    -- Send message to player
    SendChatMessage(source, resultData)
end)