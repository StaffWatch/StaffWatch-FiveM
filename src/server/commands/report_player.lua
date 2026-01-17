RegisterCommand("report", function(source, args, rawCommand)
    -- Disallow console execution
    if (source == 0) then
        print("Only players can execute this command!")
        return
    end

    -- Get reason
    local reportedPlayerId, reason = string.match(rawCommand, "^%w+%s+(%d+)%s+(.*)")
    if (reportedPlayerId == nil or reason == nil) then
        SendChatMessage(source, "Invalid usage! Use /report [playerId] [reason]")
        return
    end

    -- Get player primary identifier
    local primaryId = GetPlayerPrimaryIdentifier(source)
    if (primaryId == nil) then
        SendChatMessage(source, "No primary ID found for player!")
        return
    end

    -- Get reported player license
    local reportedId = GetPlayerPrimaryIdentifier(reportedPlayerId)
    if (reportedId == nil) then
        SendChatMessage(source, "No primary ID found for reported player!")
        return
    end

    local success, response = SendAPIRequest("/api/report", {
        type = "REPORT",
        secret = Config.SECRET,
        reporterPrimaryIdentifier = primaryId,
        reportedPrimaryIdentifier = reportedId,
        reason = reason
    })

    -- Handle failure
    if (not success) then
        SendChatMessage(source, "Report failed! Error: " .. response)
        return
    end

    -- Send message to player
    SendChatMessage(source, response)
end)