RegisterCommand("report", function(source, args, rawCommand)

    -- Disallow console execution
    if (source == 0) then
        print("Only players can execute this command!")
        return
    end

    -- Get reason
    local reportedPlayerId, reason = string.match(rawCommand, "^%w+%s+(%d+)%s+(.*)")
    if (reportedPlayerId == nil or reason == nil) then
        print("Invalid usage! Use /report [playerId] [reason]")
        return
    end

    -- Get player primary identifier
    local primaryId = GetPlayerPrimaryIdentifier(source)
    if (primaryId == nil) then
        print("No primary ID found for player!")
        return
    end

    -- Get reported player license
    local reportedId = GetPlayerPrimaryIdentifier(reportedPlayerId)
    if (reportedId == nil) then
        print("No primary ID found for reported player!")
        return
    end

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/report", "POST", json.encode({
            type = "REPORT",
            secret = Config.SECRET,
            reporterPrimaryIdentifier = primaryId,
            reportedPrimaryIdentifier = reportedId,
            reason = reason
        }), {["Content-Type"] = 'application/json'}
    )

    -- Handle failure
    if (status ~= 200) then
        print("Warning: Report failed with status code: " .. status)
        print("Failure reason: " .. errorData)
        return
    end

    -- Get result from API call
    DebugLog(resultData)
    
    -- Send message to player
    SendChatMessage(source, resultData)
end)