local noclipEnabled = false
local noclipEntity = nil
local spectating = false
local spectateTarget = nil
local spectateReturnState = nil
local frozenPlayers = {}
local staffStatusCache = nil
local staffStatusCheckedAt = 0
local STAFF_STATUS_CACHE_MS = 5 * 60 * 1000
local SPECTATE_TEXT_UI = "Spectating player - use StaffWatch menu to stop"
local NOCLIP_TEXT_UI = "Noclip: WASD move | E up | Q down | Shift faster"

local ICON_COLORS = {
    brand = "#3b82f6",
    sky = "#38bdf8",
    cyan = "#22d3ee",
    green = "#22c55e",
    amber = "#f59e0b",
    red = "#ef4444",
    purple = "#a78bfa",
    slate = "#94a3b8"
}

local function notify(title, message, type)
    lib.notify({
        title = title or "StaffWatch",
        description = message,
        type = type or "inform"
    })
end

RegisterNetEvent("sw:menu:notify")
AddEventHandler("sw:menu:notify", function(title, message, type)
    notify(title, message, type)
end)

RegisterNetEvent("sw:menu:setCoords")
AddEventHandler("sw:menu:setCoords", function(x, y, z)
    SetPedCoordsKeepVehicle(PlayerPedId(), x + 0.0, y + 0.0, z + 1.0)
    notify("StaffWatch", "Teleported.", "success")
end)

local function trim(value)
    if (value == nil) then return nil end
    return value:match("^%s*(.-)%s*$")
end

local function showResult(success, response, successTitle)
    if (success) then
        notify(successTitle or "StaffWatch", response, "success")
    else
        notify("StaffWatch", response or "Request failed.", "error")
    end
end

local function sendChatMessage(message)
    TriggerEvent("chat:addMessage", {
        color = {59, 130, 246},
        multiline = true,
        args = {"StaffWatch", message}
    })
end

local function showSpectateTextUI()
    lib.showTextUI(SPECTATE_TEXT_UI, {
        position = "top-center",
        icon = "eye",
        iconColor = ICON_COLORS.purple,
        style = {
            borderRadius = 4,
            backgroundColor = "#111827",
            color = "#f8fafc"
        }
    })
end

local function hideSpectateTextUI()
    local isOpen, text = lib.isTextUIOpen()
    if (isOpen and text == SPECTATE_TEXT_UI) then
        lib.hideTextUI()
    end
end

local function showNoclipTextUI()
    lib.showTextUI(NOCLIP_TEXT_UI, {
        position = "top-center",
        icon = "up-down-left-right",
        iconColor = ICON_COLORS.brand,
        style = {
            borderRadius = 4,
            backgroundColor = "#111827",
            color = "#f8fafc"
        }
    })
end

local function hideNoclipTextUI()
    local isOpen, text = lib.isTextUIOpen()
    if (isOpen and text == NOCLIP_TEXT_UI) then
        lib.hideTextUI()
    end
end

local function fetchPlayers()
    return lib.callback.await("sw:menu:getPlayers", false) or {}
end

local function getStaffStatus(forceRefresh)
    local now = GetGameTimer()
    local cacheExpired = staffStatusCache == nil or (now - staffStatusCheckedAt) > STAFF_STATUS_CACHE_MS

    if (forceRefresh or cacheExpired) then
        staffStatusCache = lib.callback.await("sw:menu:getStaffStatus", false) or {}
        staffStatusCheckedAt = now
    end

    return staffStatusCache
end

local function canUseLocalTools()
    local result = lib.callback.await("sw:menu:canUseLocalTools", false) or {}
    if (result.allowed ~= true) then
        notify("StaffWatch", result.error or "You do not have permission to use StaffWatch local tools.", "error")
        return false
    end
    return true
end

local function buildPlayerOptions(players, excludeSelf)
    local options = {}
    local selfServerId = GetPlayerServerId(PlayerId())

    for _, player in ipairs(players) do
        if (not excludeSelf or player.id ~= selfServerId) then
            table.insert(options, {
                value = player.id,
                label = ("[%s] %s"):format(player.id, player.name)
            })
        end
    end

    if (#options == 1) then return nil end
    return options
end

local function selectPlayer(title, excludeSelf)
    local players = fetchPlayers()
    local options = buildPlayerOptions(players, excludeSelf)

    if (#options == 0) then
        notify("StaffWatch", "No online players found.", "error")
        return nil
    end

    local input = lib.inputDialog(title, {
        {
            type = "select",
            label = "Player",
            options = options,
            required = true
        }
    })

    if (input == nil) then return nil end
    return tonumber(input[1])
end

local function promptReason(title, includeDetails)
    local fields = {
        {
            type = "input",
            label = "Reason",
            required = true,
            max = 255
        }
    }

    if (includeDetails) then
        table.insert(fields, {
            type = "textarea",
            label = "Details",
            required = false,
            max = 2500
        })
    end

    local input = lib.inputDialog(title, fields)
    if (input == nil) then return nil end

    return {
        reason = trim(input[1]),
        details = trim(input[2])
    }
end

local function runPlayerRequest()
    local input = promptReason("Request Help", false)
    if (input == nil or input.reason == nil or input.reason == "") then return end

    local success, response = lib.callback.await("sw:menu:requestStaff", false, input.reason)
    showResult(success, response, "Help Requested")
end

local function runPlayerReport()
    local target = selectPlayer("Report Player", true)
    if (target == nil) then return end

    local input = promptReason("Report Player", false)
    if (input == nil or input.reason == nil or input.reason == "") then return end

    local success, response = lib.callback.await("sw:menu:reportPlayer", false, target, input.reason)
    showResult(success, response, "Report Submitted")
end

local function createLinkCode()
    local success, response = lib.callback.await("sw:menu:createLinkCode", false)
    showResult(success, response, "Profile Link")
    if (success and response ~= nil) then
        sendChatMessage(response)
    end
end

local function createPortalCode()
    local success, response = lib.callback.await("sw:menu:createPortalCode", false)
    showResult(success, response, "Player Portal")
    if (success and response ~= nil) then
        sendChatMessage(response)
    end
end

local function confirmDangerousAction(title, message)
    local result = lib.alertDialog({
        header = title,
        content = message,
        centered = true,
        cancel = true
    })
    return result == "confirm"
end

local function shouldShowRuleSelector(actionType)
    return actionType == "WARN" or actionType == "KICK" or actionType == "BAN"
end

local function getRuleOptions()
    local result = lib.callback.await("sw:menu:getRules", false) or {}
    local rules = result.rules or {}
    if (#rules == 0) then return nil end

    local options = {
        {
            value = "",
            label = "No associated rule"
        }
    }

    for _, rule in ipairs(rules) do
        if (rule.id ~= nil) then
            local label = rule.name
            if (rule.ruleNumber ~= nil) then
                label = ("%s - %s"):format(rule.ruleNumber, rule.name)
            end

            table.insert(options, {
                value = rule.id,
                label = label
            })
        end
    end

    return options
end

local function addRuleSelectField(fields, actionType)
    if (not shouldShowRuleSelector(actionType)) then return false end

    local ruleOptions = getRuleOptions()
    if (ruleOptions == nil) then return false end

    table.insert(fields, {
        type = "select",
        label = "Associated Rule",
        description = "Optionally attach a StaffWatch rule to this action.",
        options = ruleOptions,
        default = "",
        required = false
    })
    return true
end

local function runRemoteAction(target, targetLabel, actionType)
    local title = ("%s %s"):format(actionType:sub(1, 1) .. actionType:sub(2):lower(), targetLabel)
    local input = nil
    local duration = nil
    local ruleId = nil

    if (actionType == "BAN") then
        local fields = {
            {
                type = "input",
                label = "Duration",
                description = "Use perm, permanent, or StaffWatch format like 5d4h30m.",
                required = true,
                max = 40
            },
            {
                type = "input",
                label = "Reason",
                required = true,
                max = 255
            },
            {
                type = "textarea",
                label = "Details",
                required = false,
                max = 2500
            }
        }

        local hasRuleSelector = addRuleSelectField(fields, actionType)
        input = lib.inputDialog(title, fields)

        if (input == nil) then return end
        duration = trim(input[1])
        if (duration == "perm" or duration == "permanent") then
            duration = nil
        end
        input = {
            reason = trim(input[2]),
            details = trim(input[3])
        }
        if (hasRuleSelector) then
            ruleId = trim(input[4])
        end
    else
        local includeDetails = actionType ~= "KICK"
        local fields = {
            {
                type = "input",
                label = "Reason",
                required = true,
                max = 255
            }
        }

        if (includeDetails) then
            table.insert(fields, {
                type = "textarea",
                label = "Details",
                required = false,
                max = 2500
            })
        end

        local hasRuleSelector = addRuleSelectField(fields, actionType)
        input = lib.inputDialog(title, fields)
        if (input == nil) then return end

        input = {
            reason = trim(input[1]),
            details = includeDetails and trim(input[2]) or nil
        }

        if (hasRuleSelector) then
            ruleId = trim(input[includeDetails and 3 or 2])
        end
    end

    if (ruleId == "") then ruleId = nil end
    if (input.reason == nil or input.reason == "") then return end

    if (actionType == "KICK" or actionType == "BAN") then
        local confirmed = confirmDangerousAction(title, ("Confirm %s for %s?"):format(actionType:lower(), targetLabel))
        if (not confirmed) then return end
    end

    local success, response = lib.callback.await(
        "sw:menu:remoteAction",
        false,
        target,
        actionType,
        input.reason,
        input.details,
        duration,
        ruleId
    )
    showResult(success, response, "Action Executed")
end

local function getSpectateEntity()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if (vehicle ~= 0) then return vehicle end
    return ped
end

local function storeSpectateReturnState()
    if (spectateReturnState ~= nil) then return end

    local entity = getSpectateEntity()
    local coords = GetEntityCoords(entity)
    spectateReturnState = {
        entity = entity,
        coords = coords,
        heading = GetEntityHeading(entity)
    }
end

local function setSpectateEntityHidden(hidden)
    local ped = PlayerPedId()
    local entity = getSpectateEntity()

    SetEntityVisible(entity, not hidden, false)
    SetEntityCollision(entity, not hidden, not hidden)
    FreezeEntityPosition(entity, hidden)
    SetEntityInvincible(entity, hidden)

    if (entity ~= ped) then
        SetEntityVisible(ped, not hidden, false)
        SetEntityCollision(ped, not hidden, not hidden)
        FreezeEntityPosition(ped, hidden)
        SetEntityInvincible(ped, hidden)
    end
end

local function restoreSpectateReturnState()
    local ped = PlayerPedId()
    local entity = spectateReturnState ~= nil and spectateReturnState.entity or getSpectateEntity()
    if (not DoesEntityExist(entity)) then
        entity = ped
    end

    SetEntityVisible(entity, true, false)
    SetEntityCollision(entity, true, true)
    FreezeEntityPosition(entity, false)
    SetEntityInvincible(entity, false)
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)

    if (entity ~= ped) then
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end

    if (spectateReturnState ~= nil) then
        SetEntityCoordsNoOffset(
            entity,
            spectateReturnState.coords.x,
            spectateReturnState.coords.y,
            spectateReturnState.coords.z,
            false,
            false,
            false
        )
        SetEntityHeading(entity, spectateReturnState.heading)
    end

    spectateReturnState = nil
end

local function getStreamedTargetPed(target)
    local targetPlayer = GetPlayerFromServerId(target)
    if (targetPlayer == -1) then return nil end

    local targetPed = GetPlayerPed(targetPlayer)
    if (not DoesEntityExist(targetPed)) then return nil end

    return targetPed
end

local function streamInSpectateTarget(target)
    local targetPed = getStreamedTargetPed(target)
    if (targetPed ~= nil) then return targetPed end

    local result = lib.callback.await("sw:menu:getPlayerCoords", false, target) or {}
    if (result.coords == nil) then
        notify("StaffWatch", result.error or "Unable to locate target player.", "error")
        return nil
    end

    storeSpectateReturnState()
    setSpectateEntityHidden(true)
    SetEntityCoordsNoOffset(
        getSpectateEntity(),
        result.coords.x + 0.0,
        result.coords.y + 0.0,
        result.coords.z + 8.0,
        false,
        false,
        false
    )

    local timeoutAt = GetGameTimer() + 5000
    while (GetGameTimer() < timeoutAt) do
        Wait(100)
        targetPed = getStreamedTargetPed(target)
        if (targetPed ~= nil) then return targetPed end
    end

    restoreSpectateReturnState()
    notify("StaffWatch", "Target player could not be streamed in.", "error")
    return nil
end

local function setSpectate(target)
    if (not canUseLocalTools()) then return end

    if (spectating and spectateTarget == target) then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        spectating = false
        spectateTarget = nil
        hideSpectateTextUI()
        restoreSpectateReturnState()
        notify("StaffWatch", "Spectate disabled.", "success")
        return
    end

    local targetPed = streamInSpectateTarget(target)
    if (targetPed == nil) then return end

    NetworkSetInSpectatorMode(true, targetPed)
    spectating = true
    spectateTarget = target
    showSpectateTextUI()
    notify("StaffWatch", "Spectating player. Select them again to stop.", "success")
end

Citizen.CreateThread(function()
    while true do
        if (spectating) then
            Wait(0)

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
        else
            Wait(500)
        end
    end
end)

AddEventHandler("onClientResourceStop", function(resourceName)
    if (resourceName ~= GetCurrentResourceName()) then return end

    if (spectating) then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        hideSpectateTextUI()
        restoreSpectateReturnState()
    end
end)

local function getNoclipEntity()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if (vehicle ~= 0) then return vehicle end
    return ped
end

local function showKeyboardMenu(id, title, parentId, options, onSelect, onCheck)
    lib.registerMenu({
        id = id,
        title = title,
        position = "top-right",
        canClose = true,
        onClose = function(keyPressed)
            if (keyPressed == "Backspace" and parentId ~= nil) then
                lib.showMenu(parentId)
            end
        end,
        onCheck = onCheck,
        options = options
    }, function(selected, scrollIndex, args)
        if (onSelect ~= nil) then
            onSelect(args, selected, scrollIndex)
        end
    end)

    lib.showMenu(id)
end

local function formatTrustScore(trustScore)
    if (trustScore == nil) then return "Unknown" end
    return ("%s%%"):format(trustScore)
end

local function formatPlaytime(playtime)
    if (playtime == nil) then return "Unknown" end

    local hours = math.floor(playtime / 60)
    local minutes = playtime % 60
    if (hours == 0) then
        return ("%sm"):format(minutes)
    end
    return ("%sh %sm"):format(hours, minutes)
end

local function formatFirstPlayed(firstPlayed)
    if (firstPlayed == nil) then return "Unknown" end
    return tostring(firstPlayed):sub(1, 10)
end

local function getPlayerDetailsMenuOption(player)
    return {
        label = "Player Profile",
        description = "Side-scroll profile details from StaffWatch",
        icon = "id-card",
        iconColor = ICON_COLORS.purple,
        values = {
            "Trust Score: " .. formatTrustScore(player.trustScore),
            "Playtime: " .. formatPlaytime(player.playtime),
            "First Played: " .. formatFirstPlayed(player.firstPlayed)
        },
        close = false,
        args = {action = "details"}
    }
end

local function getSpectateMenuOption(target)
    local isSpectatingTarget = spectating and spectateTarget == target
    return {
        label = "Spectate Player",
        description = "Watch this player from their point of view",
        icon = "eye",
        iconColor = ICON_COLORS.purple,
        checked = isSpectatingTarget,
        close = false,
        args = {action = "spectate"}
    }
end

local function getFreezeMenuOption(target)
    local isFrozen = frozenPlayers[target] == true
    return {
        label = "Freeze Player",
        description = isFrozen and "Uncheck to restore movement for this player" or "Check to stop this player from moving",
        icon = "snowflake",
        iconColor = isFrozen and ICON_COLORS.sky or ICON_COLORS.slate,
        checked = isFrozen,
        close = false,
        args = {action = "freeze"}
    }
end

local function copyProfileLink(target)
    local result = lib.callback.await("sw:menu:getProfileLink", false, target) or {}
    if (result.link == nil or result.link == "") then
        notify("StaffWatch", result.error or "Unable to load profile link.", "error")
        return
    end

    lib.setClipboard(result.link)
    notify("StaffWatch", "Profile link copied.", "success")
end

local function openPlayerActions(player)
    local target = player.id
    local targetLabel = player.label
    local result = lib.callback.await("sw:menu:getPlayerDetails", false, target) or {}
    local details = result.details
    if (details == nil) then
        notify("StaffWatch", result.error or "Unable to load player profile details.", "error")
        details = {}
    end

    showKeyboardMenu("sw_player_actions_" .. target, targetLabel, "sw_staff_menu", {
        getPlayerDetailsMenuOption(details),
        {label = "Add Note", description = "Add private staff context to this player's record", icon = "note-sticky", iconColor = ICON_COLORS.sky, args = {action = "note"}},
        {label = "Commend Player", description = "Record positive behavior for this player", icon = "thumbs-up", iconColor = ICON_COLORS.green, args = {action = "commend"}},
        {label = "Issue Warning", description = "Issue a formal warning and save it to StaffWatch", icon = "triangle-exclamation", iconColor = ICON_COLORS.amber, args = {action = "warn"}},
        {label = "Kick Player", description = "Remove this player from the server with a recorded reason", icon = "right-from-bracket", iconColor = ICON_COLORS.amber, args = {action = "kick"}},
        {label = "Ban Player", description = "Create a temporary or permanent StaffWatch ban", icon = "ban", iconColor = ICON_COLORS.red, args = {action = "ban"}},
        {label = "Teleport To Player", description = "Move yourself to this player's current location", icon = "location-dot", iconColor = ICON_COLORS.cyan, args = {action = "teleport"}},
        {label = "Summon Player", description = "Bring this player to your current location", icon = "user-plus", iconColor = ICON_COLORS.cyan, args = {action = "summon"}},
        getSpectateMenuOption(target),
        getFreezeMenuOption(target),
        {label = "Copy Profile Link", description = "Copy this player's StaffWatch dashboard profile link", icon = "copy", iconColor = ICON_COLORS.brand, args = {action = "copyProfile"}}
    }, function(args)
        if (args.action == "details") then
            return
        elseif (args.action == "note") then
            runRemoteAction(target, targetLabel, "NOTE")
        elseif (args.action == "commend") then
            runRemoteAction(target, targetLabel, "COMMEND")
        elseif (args.action == "warn") then
            runRemoteAction(target, targetLabel, "WARN")
        elseif (args.action == "kick") then
            runRemoteAction(target, targetLabel, "KICK")
        elseif (args.action == "ban") then
            runRemoteAction(target, targetLabel, "BAN")
        elseif (args.action == "teleport") then
            TriggerServerEvent("sw:menu:teleportToPlayer", target)
        elseif (args.action == "summon") then
            TriggerServerEvent("sw:menu:summonPlayer", target)
        elseif (args.action == "copyProfile") then
            copyProfileLink(target)
        end
    end, function(selected, checked, args)
        if (args.action == "spectate") then
            setSpectate(target)
            lib.setMenuOptions("sw_player_actions_" .. target, getSpectateMenuOption(target), selected)
        elseif (args.action == "freeze") then
            frozenPlayers[target] = checked == true
            TriggerServerEvent("sw:menu:setFreeze", target, frozenPlayers[target])
            lib.setMenuOptions("sw_player_actions_" .. target, getFreezeMenuOption(target), selected)
        end
    end)
end

local function teleportToWaypoint()
    if (not canUseLocalTools()) then return end

    local waypoint = GetFirstBlipInfoId(8)
    if (not DoesBlipExist(waypoint)) then
        notify("StaffWatch", "No waypoint is set.", "error")
        return
    end

    local ped = PlayerPedId()
    local coords = GetBlipInfoIdCoord(waypoint)

    for height = 0, 1000, 50 do
        SetPedCoordsKeepVehicle(ped, coords.x, coords.y, height + 0.0)
        Wait(0)
        local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, height + 0.0, false)
        if (foundGround) then
            SetPedCoordsKeepVehicle(ped, coords.x, coords.y, groundZ + 1.0)
            notify("StaffWatch", "Teleported to waypoint.", "success")
            return
        end
    end

    SetPedCoordsKeepVehicle(ped, coords.x, coords.y, coords.z + 1.0)
    notify("StaffWatch", "Teleported to waypoint.", "success")
end

local function copyCurrentCoords()
    if (not canUseLocalTools()) then return end

    local coords = GetEntityCoords(PlayerPedId())
    local text = ("%.3f, %.3f, %.3f"):format(coords.x, coords.y, coords.z)
    lib.setClipboard(text)
    notify("StaffWatch", "Coordinates copied: " .. text, "success")
end

local function getForwardAndRightVectors()
    local heading = math.rad(GetGameplayCamRot(0).z)
    local forward = vector3(-math.sin(heading), math.cos(heading), 0.0)
    local right = vector3(forward.y, -forward.x, 0.0)
    return forward, right
end

local function setNoclipEnabled(enabled, silent)
    if (enabled == true and not canUseLocalTools()) then return end

    noclipEnabled = enabled == true

    local ped = PlayerPedId()
    if (noclipEnabled) then
        noclipEntity = getNoclipEntity()
        showNoclipTextUI()
    end

    local entity = noclipEntity or getNoclipEntity()

    SetEntityCollision(entity, not noclipEnabled, not noclipEnabled)
    FreezeEntityPosition(entity, noclipEnabled)
    SetEntityInvincible(entity, noclipEnabled)

    if (not noclipEnabled) then
        SetEntityVelocity(entity, 0.0, 0.0, 0.0)
        SetEntityCollision(entity, true, true)
        FreezeEntityPosition(entity, false)
        SetEntityInvincible(entity, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetPlayerControl(PlayerId(), true, 0)
        noclipEntity = nil
        hideNoclipTextUI()
    end

    if (not silent) then
        notify("StaffWatch", noclipEnabled and "Noclip enabled." or "Noclip disabled.", "success")
    end
end

AddEventHandler("onClientResourceStop", function(resourceName)
    if (resourceName ~= GetCurrentResourceName()) then return end

    if (noclipEnabled) then
        setNoclipEnabled(false, true)
    end
end)

Citizen.CreateThread(function()
    while true do
        if (noclipEnabled) then
            Wait(0)

            local entity = noclipEntity or getNoclipEntity()
            local coords = GetEntityCoords(entity)
            local forward, right = getForwardAndRightVectors()
            local speed = IsControlPressed(0, 21) and 4.0 or 1.0

            DisableControlAction(0, 30, true)
            DisableControlAction(0, 31, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 38, true)

            if (IsDisabledControlPressed(0, 32)) then coords = coords + forward * speed end
            if (IsDisabledControlPressed(0, 33)) then coords = coords - forward * speed end
            if (IsDisabledControlPressed(0, 34)) then coords = coords - right * speed end
            if (IsDisabledControlPressed(0, 35)) then coords = coords + right * speed end
            if (IsDisabledControlPressed(0, 38)) then coords = coords + vector3(0.0, 0.0, speed) end
            if (IsDisabledControlPressed(0, 44)) then coords = coords - vector3(0.0, 0.0, speed) end

            SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, true)
        else
            Wait(500)
        end
    end
end)

local function getNoclipMenuOption()
    return {
        label = "Noclip",
        description = noclipEnabled and "Uncheck to disable free movement" or "Check to enable free movement for staff positioning",
        icon = "up-down-left-right",
        iconColor = noclipEnabled and ICON_COLORS.amber or ICON_COLORS.brand,
        checked = noclipEnabled,
        close = false,
        args = {action = "noclip"}
    }
end

local function openServerTools()
    showKeyboardMenu("sw_server_tools", "Server Tools", "sw_staff_menu", {
        {label = "Send Announcement", description = "Broadcast a StaffWatch announcement to the server", icon = "bullhorn", iconColor = ICON_COLORS.brand, args = {action = "announcement"}},
        {label = "Teleport To Waypoint", description = "Move yourself to your active map waypoint", icon = "map", iconColor = ICON_COLORS.cyan, args = {action = "waypoint"}},
        {label = "Copy Current Coordinates", description = "Copy your current position to the clipboard", icon = "copy", iconColor = ICON_COLORS.sky, args = {action = "coords"}},
        getNoclipMenuOption()
    }, function(args)
        if (args.action == "announcement") then
            local input = lib.inputDialog("Announcement", {
                {
                    type = "textarea",
                    label = "Message",
                    required = true,
                    max = 500
                }
            })
            if (input == nil or trim(input[1]) == nil or trim(input[1]) == "") then return end
            TriggerServerEvent("sw:menu:announce", trim(input[1]))
        elseif (args.action == "waypoint") then
            teleportToWaypoint()
        elseif (args.action == "coords") then
            copyCurrentCoords()
        end
    end, function(selected, checked, args)
        if (args.action == "noclip") then
            setNoclipEnabled(checked)
            lib.setMenuOptions("sw_server_tools", getNoclipMenuOption(), selected)
        end
    end)
end

local openPlayerMenu

local function openPlayerById()
    local input = lib.inputDialog("Find Player By ID", {
        {
            type = "number",
            label = "Server ID",
            required = true,
            min = 1
        }
    })

    if (input == nil) then return end

    local target = tonumber(input[1])
    local players = fetchPlayers()
    for _, player in ipairs(players) do
        if (player.id == target) then
            player.label = ("[%s] %s"):format(player.id, player.name)
            openPlayerActions(player)
            return
        end
    end

    notify("StaffWatch", "No online player found with that ID.", "error")
end

local function openStaffMenu()
    local options = {
        {label = "Player Menu", description = "Open player-facing StaffWatch tools and portal access", icon = "id-card", iconColor = ICON_COLORS.sky, args = {action = "playerMenu"}},
        {label = "Server Tools", description = "Announcements, noclip, waypoint teleport, and coordinates", icon = "wrench", iconColor = ICON_COLORS.brand, args = {action = "server"}},
        {label = "Find Player By ID", description = "Open a player action menu by server ID", icon = "magnifying-glass", iconColor = ICON_COLORS.cyan, args = {action = "findPlayer"}}
    }

    local players = fetchPlayers()
    for _, player in ipairs(players) do
        local title = ("[%s] %s"):format(player.id, player.name)
        player.label = title
        table.insert(options, {
            label = title,
            description = "Open moderation and staff utility actions",
            icon = "user",
            iconColor = ICON_COLORS.sky,
            args = {
                action = "player",
                target = player.id,
                player = player
            }
        })
    end

    if (#players == 0) then
        table.insert(options, {
            label = "No online players",
            description = "No players are currently available to manage",
            icon = "user-slash",
            iconColor = ICON_COLORS.slate,
            args = {
                action = "empty"
            }
        })
    end

    showKeyboardMenu("sw_staff_menu", "StaffWatch Menu", nil, options, function(args)
        if (args.action == "playerMenu") then
            openPlayerMenu("sw_staff_menu")
        elseif (args.action == "server") then
            openServerTools()
        elseif (args.action == "findPlayer") then
            openPlayerById()
        elseif (args.action == "player") then
            openPlayerActions(args.player)
        end
    end)
end

openPlayerMenu = function(parentId)
    showKeyboardMenu("sw_player_menu", "Player Options", parentId, {
        {label = "Request Staff", description = "Request assistance from an online staff member", icon = "hand", iconColor = ICON_COLORS.sky, args = {action = "request"}},
        {label = "Report Player", description = "Report another player for breaking rules in-game", icon = "flag", iconColor = ICON_COLORS.amber, args = {action = "report"}},
        {
            label = "Access Player Portal",
            description = "View action history, applications, appeals, and more",
            icon = "arrow-up-right-from-square",
            iconColor = ICON_COLORS.brand,
            args = {action = "portal"}
        },
        {label = "Link Staff Account", description = "For Staff Members: Generate a code to link your in-game account to StaffWatch", icon = "link", iconColor = ICON_COLORS.cyan, args = {action = "link"}},
        {label = "Refresh Permissions", description = "For Staff Members: Re-check your linked StaffWatch staff access", icon = "rotate", iconColor = ICON_COLORS.brand, args = {action = "refresh"}}
    }, function(args)
        if (args.action == "refresh") then
            local status = getStaffStatus(true)
            if (status.isStaff == true) then
                notify("StaffWatch", "Staff permissions refreshed.", "success")
                openStaffMenu()
            else
                notify("StaffWatch", "No staff permissions found yet.", "inform")
            end
        elseif (args.action == "request") then
            runPlayerRequest()
        elseif (args.action == "report") then
            runPlayerReport()
        elseif (args.action == "link") then
            createLinkCode()
        elseif (args.action == "portal") then
            createPortalCode()
        end
    end)
end

local function openMainMenu()
    local status = getStaffStatus(false)
    if (status.isStaff == true) then
        openStaffMenu()
    else
        openPlayerMenu(nil)
    end
end

RegisterCommand("staffwatch", openMainMenu, false)
RegisterCommand("swmenu", openMainMenu, false)

lib.addKeybind({
    name = "staffwatch_menu",
    description = "Open StaffWatch menu",
    defaultKey = Config.MENU_KEYBIND or "F7",
    onPressed = openMainMenu
})
