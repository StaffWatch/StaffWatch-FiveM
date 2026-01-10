AddEventHandler("playerConnecting", function(name, setReason, deferrals)
    deferrals.defer()

    -- Get player
    local playerDto = CreatePlayerDTO(name, source)

    -- Convert DTO to json
    local jsonData = json.encode({
        secret = Config.SECRET,
        player = playerDto
    })

    DebugLog('Player join JSON:')
    DebugLog(jsonData)

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/player-join", "POST", jsonData, {["Content-Type"] = 'application/json'}
    )

    DebugLog(status)
    DebugLog(resultData)
    DebugLog(errorData)
    
    -- Handle failure
    if (status ~= 200) then
        print("Warning: Player join validation failed with status code: " .. status)
        print("Failure reason: " .. errorData)
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
    local response = json.decode(resultData)
    if (response.allowJoin) then
        AllowJoin(deferrals)
    elseif (response.banInfo) then
        HandleBan(deferrals, response.banInfo)
    else
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

    local lines = {
        "--------------------------------------",
        "⚠️ You Are Banned From This Server ⚠️",
        "--------------------------------------",
        "🚫 Rule: " .. banInfo.rule.name,
        "📝 Reason: " .. banInfo.reason,
        "⏰ Expires: " .. banInfo.expiration,
        "--------------------------------------",
        "⚙️ Banned Using StaffWatch.app",
        "--------------------------------------",
        "📞 Want to appeal this ban?",
        "Visit: " .. banInfo.appealUrl,
        "--------------------------------------"
    }

    if Config.SHOW_STAFF_ON_BANNED_PLAYER_JOIN then
        table.insert(lines, 4, "👤 Staff: {staff}")
    end

    local message = '\n' .. table.concat(lines, '\n')

    message = InputReplace(message, "rule", banInfo.rule.name)
    message = InputReplace(message, "reason", banInfo.reason)
    message = InputReplace(message, "expiration", banInfo.expiration)
    message = InputReplace(message, "appealUrl", banInfo.appealUrl)
        
    if Config.SHOW_STAFF_ON_BANNED_PLAYER_JOIN then
        message = InputReplace(message, "staff", banInfo.staffUsername)
    end
    
    def.done(message)
end

-- Prevents player join
function BlockJoin(def)
    def.done("StaffWatch denied join request!")
end