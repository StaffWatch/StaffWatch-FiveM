RegisterCommand("portal", function(source, _, _)
    -- Disallow console execution
    if (source == 0) then
        print("Only players can execute this command!")
        return
    end

    -- Get player primary identifier
    local primaryId = GetPlayerPrimaryIdentifier(source)
    if (primaryId == nil) then
        SendChatMessage(source, "No primary ID found for player!")
        return
    end

    -- Send API request to generate portal link
    local success, response = SendAPIRequest("/api/portal", {
        secret = Config.SECRET,
        primaryIdentifier = primaryId
    })

    -- Handle failure
    if (not success) then
        SendChatMessage(source, "Portal link generation failed! Error: " .. response)
        return
    end

    -- Send message to player
    SendChatMessage(source, response)
end, false)