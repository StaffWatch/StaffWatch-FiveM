RegisterCommand("portal", function(source, _, _)
    
    -- Disallow console execution
    if (source == 0) then
        print("Only players can execute this command!")
        return
    end

    -- Get player primary identifier
    local primaryId = GetPlayerPrimaryIdentifier(source)
    DebugLog("Primary ID" .. primaryId)
    if (primaryId == nil) then
        SendChatMessage(source, "No primary ID found for player!")
        return
    end

    -- Create OTP request
    local portalReqBody = json.encode({
        secret = Config.SECRET,
        primaryIdentifier = primaryId
    })

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/portal", "POST", portalReqBody, {["Content-Type"] = 'application/json'}
    )

    -- Handle failure
    if (status ~= 200) then
        SendChatMessage(source, "Portal link generation failed! Error: " .. errorData)
        print("Warning: Portal link generation failed with status code: " .. status)
        print("Failure reason: " .. errorData)
        return
    end

    -- Get result from API call
    DebugLog(resultData)
    
    -- Send message to player
    SendChatMessage(source, resultData)

end, false)