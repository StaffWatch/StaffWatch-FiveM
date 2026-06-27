local rulesCache = nil
local rulesCacheTime = 0
local RULES_CACHE_SECONDS = 5 * 60

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
    local isStaff = response ~= nil and (response.isStaff == true or response.staff == true)
    if (not isStaff) then
        return false, response, nil
    end

    return true, response, nil
end

local function getRules()
    if (rulesCache ~= nil and os.time() - rulesCacheTime < RULES_CACHE_SECONDS) then
        return rulesCache, nil
    end

    local success, rawResponse = SendAPIRequest("/api/rules", {
        secret = Config.SECRET
    })

    if (not success) then
        return {}, rawResponse
    end

    rulesCache = json.decode(rawResponse) or {}
    rulesCacheTime = os.time()
    return rulesCache, nil
end

local function canUseLocalTools(source)
    local isStaff, staff, err = getStaffStatus(source)
    if (not isStaff) then
        return false, "You must be linked StaffWatch staff to use this."
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

lib.callback.register("sw:menu:getPlayerDetails", function(source, targetSource)
    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        return {
            details = nil,
            error = targetErr
        }
    end

    local primaryIdentifier = GetPlayerPrimaryIdentifier(target)
    if (primaryIdentifier == nil) then
        return {
            details = nil,
            error = "No primary ID found for player."
        }
    end

    local success, rawResponse = SendAPIRequest("/api/player-details", {
        secret = Config.SECRET,
        primaryIdentifier = primaryIdentifier
    })

    if (not success) then
        return {
            details = nil,
            error = rawResponse
        }
    end

    return {
        details = json.decode(rawResponse),
        error = nil
    }
end)

lib.callback.register("sw:menu:getPlayerCoords", function(source, targetSource)
    local canUse, err = canUseLocalTools(source)
    if (not canUse) then
        return {
            coords = nil,
            error = err
        }
    end

    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        return {
            coords = nil,
            error = targetErr
        }
    end

    local targetPed = GetPlayerPed(target)
    if (targetPed == 0) then
        return {
            coords = nil,
            error = "Target player is not currently available."
        }
    end

    local coords = GetEntityCoords(targetPed)
    return {
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        error = nil
    }
end)

lib.callback.register("sw:menu:getRules", function(source)
    local canUse, accessErr = canUseLocalTools(source)
    if (not canUse) then
        return {
            rules = {},
            error = accessErr
        }
    end

    local rules, err = getRules()
    return {
        rules = rules,
        error = err
    }
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

lib.callback.register("sw:menu:getProfileLink", function(source, targetSource)
    local canUse, err = canUseLocalTools(source)
    if (not canUse) then
        return {
            link = nil,
            error = err
        }
    end

    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        return {
            link = nil,
            error = targetErr
        }
    end

    local primaryIdentifier = GetPlayerPrimaryIdentifier(target)
    if (primaryIdentifier == nil) then
        return {
            link = nil,
            error = "No primary ID found for player."
        }
    end

    local success, response = SendAPIRequest("/api/player-profile-link", {
        secret = Config.SECRET,
        primaryIdentifier = primaryIdentifier
    })

    return {
        link = success and response or nil,
        error = success and nil or response
    }
end)

lib.callback.register("sw:menu:remoteAction", function(source, targetSource, actionType, reason, details, duration, ruleId)
    local target, targetErr = requireOnlinePlayer(targetSource)
    if (target == nil) then
        return false, targetErr
    end

    local staffPrimary = GetPlayerPrimaryIdentifier(source)
    if (staffPrimary == nil) then
        return false, "Unable to resolve your StaffWatch link. Try relogging."
    end

    return ExecuteRemoteAction(target, actionType, reason, details, nil, staffPrimary, duration, ruleId)
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
