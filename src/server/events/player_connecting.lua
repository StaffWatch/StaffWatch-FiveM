AddEventHandler("playerConnecting", function(name, _, deferrals)
    deferrals.defer()

    -- Log join request
    local origSrc = source

    -- Get player
    local playerDto = CreatePlayerDTO(name, source)

    -- Send connection request
    local success, rawResponse = SendAPIRequest("/api/request-join", {
        secret = Config.SECRET,
        player = playerDto
    })

    -- Handle request failure
    if (not success) then
        if (Config.BYPASS_ON_FAILURE) then
            deferrals.update("⚠️ StaffWatch failed to authenticate your connection! You will automatically join in 5 seconds, but server development should be contacted! ⚠️")
            Citizen.Wait(5000)
            deferrals.done()
        else
            deferrals.done("⚠️ Unable to connect to StaffWatch servers. Please try again in a few minutes. ⚠️")
        end
        return
    end

    -- Handle response from API
    local response = json.decode(rawResponse)
    if (response.allowJoin) then
        AllowJoin(deferrals)
    elseif (response.banInfo) then
        LogEvent("JOIN_ATTEMPT", origSrc, nil, {})
        HandleBan(deferrals, response.banInfo)
    else
        LogEvent("JOIN_ATTEMPT", origSrc, nil, {})
        BlockJoin(deferrals)
    end

end)

-- Lets player join server
function AllowJoin(def)
    def.update("Account verified! Joining server! ✅")
    Citizen.Wait(500)
    def.done()
end

-- Handle banned player
function HandleBan(def, banInfo)
    if banInfo.rule == nil then
        banInfo.rule = { name = "Not Specified" }
    end
    local message = '\n' .. [[
    ⚠️ You Are Banned From This Server ⚠️
    --------------------------------------
    🚫 Rule: {rule}
    📝 Reason: {reason}
    ⏰ Expires: {expiration}
    --------------------------------------
    ⚙️ Banned Using StaffWatch.app
    --------------------------------------
    📞 Want to appeal this ban?
    Visit: {appealUrl}
    ]]
    message = InputReplace(message, "rule", banInfo.rule.name)
    message = InputReplace(message, "reason", banInfo.reason)
    message = InputReplace(message, "expiration", banInfo.expiration)
    message = InputReplace(message, "appealUrl", banInfo.appealUrl)
    def.done(message)
end

-- Prevents player join
function BlockJoin(def)
    def.done("StaffWatch denied join request!")
end