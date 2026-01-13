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

    local success, response = SendAPIRequest("/api/report", {
        type = "HELP",
        secret = Config.SECRET,
        reporterPrimaryIdentifier = primaryId,
        reason = reason
    })

    -- Handle failure
    if (not success) then
        SendChatMessage(source, "Request failed! Error: " .. response)
        return
    end

    -- Send message to player
    SendChatMessage(source, response)
end)