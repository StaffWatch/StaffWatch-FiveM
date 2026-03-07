local function parseTargetSource(raw)
    local targetSource = tonumber(raw)
    if (targetSource == nil) then
        return nil, "Invalid player ID. Use the in-game server ID."
    end
    if (GetPlayerName(targetSource) == nil) then
        return nil, "Player is not online."
    end
    return targetSource, nil
end

local function executeStaffAction(source, actionType, targetSource, reason, duration)
    local staffPrimary = GetPlayerPrimaryIdentifier(source)
    if (staffPrimary == nil) then
        SendChatMessage(source, "Unable to resolve your StaffWatch link. Try relogging.")
        return
    end

    local targetPrimary = GetPlayerPrimaryIdentifier(targetSource)
    if (targetPrimary == nil) then
        SendChatMessage(source, "Unable to resolve the target player's primary identifier.")
        return
    end

    local success, response = ExecuteRemoteAction(targetSource, actionType, reason, nil, nil, staffPrimary, duration)
    if (not success) then
        SendChatMessage(source, "Action failed: " .. response)
        return
    end

    SendChatMessage(source, response)
end

local function registerSimpleStaffAction(commandName, actionType)
    RegisterCommand(commandName, function(source, args, rawCommand)
        if (source == 0) then
            print("Only players can execute this command!")
            return
        end

        local targetId, reason = string.match(rawCommand, "^%w+%s+(%d+)%s+(.*)")
        if (targetId == nil or reason == nil) then
            SendChatMessage(source, "Usage: /" .. commandName .. " <id> <reason>")
            return
        end

        local targetSource, targetErr = parseTargetSource(targetId)
        if (targetSource == nil) then
            SendChatMessage(source, targetErr)
            return
        end

        executeStaffAction(source, actionType, targetSource, reason, nil)
    end, false)
end

registerSimpleStaffAction("note", "NOTE")
registerSimpleStaffAction("commend", "COMMEND")
registerSimpleStaffAction("warn", "WARN")
registerSimpleStaffAction("kick", "KICK")

RegisterCommand("ban", function(source, args, rawCommand)
    if (source == 0) then
        print("Only players can execute this command!")
        return
    end

    local targetId, duration, reason = string.match(rawCommand, "^%w+%s+(%d+)%s+(%S+)%s+(.*)")
    if (targetId == nil or duration == nil or reason == nil) then
        SendChatMessage(source, "Usage: /ban <id> <duration|perm> <reason>")
        return
    end

    local targetSource, targetErr = parseTargetSource(targetId)
    if (targetSource == nil) then
        SendChatMessage(source, targetErr)
        return
    end

    local normalizedDuration = string.lower(duration)
    if (normalizedDuration == "perm" or normalizedDuration == "permanent") then
        duration = nil
    end

    executeStaffAction(source, "BAN", targetSource, reason, duration)
end, false)
