local LOCAL_TOOLS_ACE = "staffwatch.localtools"

local function getStaffStatus(source)
    local primaryIdentifier = GetPlayerPrimaryIdentifier(source)
    if (primaryIdentifier == nil) then
        return false, nil, "No primary ID found for player."
    end

    local success, rawResponse = SendAPIRequest("/api/check-staff", {
        secret = Config.SECRET,
        primaryIdentifier = primaryIdentifier
    })

    if (not success) then
        return false, nil, rawResponse
    end

    local response = json.decode(rawResponse)
    if (response == nil or response.isStaff ~= true) then
        return false, response, nil
    end

    return true, response, nil
end

local function canUseLocalTools(source)
    local isStaff, staff, err = getStaffStatus(source)
    if (not isStaff) then
        return false, "You must be linked StaffWatch staff to use this."
    end

    if (not IsPlayerAceAllowed(source, LOCAL_TOOLS_ACE)) then
        return false, "You do not have permission to use StaffWatch local tools."
    end

    return true, staff, err
end

local function getPlayerList()
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, {
            id = tonumber(playerId),
            name = GetPlayerName(playerId) or ("Player " .. playerId)
        })
    end
    return players
end

local function requireOnlinePlayer(targetSource)
    local numericTarget = tonumber(targetSource)
    if (numericTarget == nil or GetPlayerName(numericTarget) == nil) then
        return nil, "Player is not online."
    end
    return numericTarget, nil
end

lib.callback.register("sw:menu:getStaffStatus", function(source)
    local isStaff, staff, err = getStaffStatus(source)
    return {
        isStaff = isStaff,
        staff = staff,
        error = err
    }
end)

lib.callback.register("sw:menu:getPlayers", function()
    return getPlayerList()
end)

lib.callback.register("sw:menu:canUseLocalTools", function(source)
    local canUse, result = canUseLocalTools(source)
    return {
        allowed = canUse,
        error = canUse and nil or result
    }
end)

lib.callback.register("sw:menu:requestStaff", function(source, reason)
    local primaryIdentifier = GetPlayerPrimaryIdentifier(source)
    if (primaryIdentifier == nil) then
        return false, "No primary ID found for player."
    end

    return SendAPIRequest("/api/report", {
        type = "HELP",
        secret = Config.SECRET,
        reporterPrimaryIdentifier = primaryIdentifier,
        reason = reason
    })
end)

lib.callback.register("sw:menu:reportPlayer", function(source, targetSource, reason)
    local reporterPrimaryIdentifier = GetPlayerPrimaryIdentifier(source)
    if (reporterPrimaryIdentifier == nil) then
        return false, "No primary ID found for player."
    end

    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        return false, targetErr
    end

    local reportedPrimaryIdentifier = GetPlayerPrimaryIdentifier(target)
    if (reportedPrimaryIdentifier == nil) then
        return false, "No primary ID found for reported player."
    end

    return SendAPIRequest("/api/report", {
        type = "REPORT",
        secret = Config.SECRET,
        reporterPrimaryIdentifier = reporterPrimaryIdentifier,
        reportedPrimaryIdentifier = reportedPrimaryIdentifier,
        reason = reason
    })
end)

lib.callback.register("sw:menu:createLinkCode", function(source)
    local primaryIdentifier = GetPlayerPrimaryIdentifier(source)
    if (primaryIdentifier == nil) then
        return false, "No primary ID found for player."
    end

    return SendAPIRequest("/api/link", {
        secret = Config.SECRET,
        primaryIdentifier = primaryIdentifier
    })
end)

lib.callback.register("sw:menu:createPortalCode", function(source)
    local primaryIdentifier = GetPlayerPrimaryIdentifier(source)
    if (primaryIdentifier == nil) then
        return false, "No primary ID found for player."
    end

    return SendAPIRequest("/api/portal", {
        secret = Config.SECRET,
        primaryIdentifier = primaryIdentifier
    })
end)

lib.callback.register("sw:menu:remoteAction", function(source, targetSource, actionType, reason, details, duration)
    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        return false, targetErr
    end

    local staffPrimary = GetPlayerPrimaryIdentifier(source)
    if (staffPrimary == nil) then
        return false, "Unable to resolve your StaffWatch link. Try relogging."
    end

    return ExecuteRemoteAction(target, actionType, reason, details, nil, staffPrimary, duration)
end)

RegisterNetEvent("sw:menu:teleportToPlayer")
AddEventHandler("sw:menu:teleportToPlayer", function(targetSource)
    local source = source
    local canUse, err = canUseLocalTools(source)
    if (not canUse) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", err, "error")
        return
    end

    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", targetErr, "error")
        return
    end

    local targetPed = GetPlayerPed(target)
    local coords = GetEntityCoords(targetPed)
    TriggerClientEvent("sw:menu:setCoords", source, coords.x, coords.y, coords.z)
end)

RegisterNetEvent("sw:menu:summonPlayer")
AddEventHandler("sw:menu:summonPlayer", function(targetSource)
    local source = source
    local canUse, err = canUseLocalTools(source)
    if (not canUse) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", err, "error")
        return
    end

    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", targetErr, "error")
        return
    end

    local staffPed = GetPlayerPed(source)
    local coords = GetEntityCoords(staffPed)
    TriggerClientEvent("sw:menu:setCoords", target, coords.x, coords.y, coords.z)
    TriggerClientEvent("sw:menu:notify", source, "StaffWatch", "Player summoned.", "success")
end)

RegisterNetEvent("sw:menu:setFreeze")
AddEventHandler("sw:menu:setFreeze", function(targetSource, frozen)
    local source = source
    local canUse, err = canUseLocalTools(source)
    if (not canUse) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", err, "error")
        return
    end

    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", targetErr, "error")
        return
    end

    if (frozen) then
        SendChatMessage(target, "You have been frozen by staff.")
        TriggerClientEvent("sw:freeze", target)
        TriggerClientEvent("sw:createAnnouncement", target, "~b~Frozen by Staff", "You have been frozen by staff. Please standby for further instructions.", 5000)
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", "Player frozen.", "success")
    else
        SendChatMessage(target, "You have been unfrozen by staff.")
        TriggerClientEvent("sw:unfreeze", target)
        TriggerClientEvent("sw:createAnnouncement", target, "~b~Unfrozen by Staff", "You have been unfrozen by staff. You may now move freely.", 5000)
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", "Player unfrozen.", "success")
    end
end)

RegisterNetEvent("sw:menu:announce")
AddEventHandler("sw:menu:announce", function(message)
    local source = source
    local canUse, err = canUseLocalTools(source)
    if (not canUse) then
        TriggerClientEvent("sw:menu:notify", source, "StaffWatch", err, "error")
        return
    end

    SendChatMessage(-1, "Server Announcement: " .. message)
    TriggerClientEvent("sw:createAnnouncement", -1, "~b~Server Announcement", message, 10000)
    TriggerClientEvent("sw:menu:notify", source, "StaffWatch", "Announcement sent.", "success")
end)
