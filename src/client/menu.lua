local noclipEnabled = false
local noclipEntity = nil
local spectating = false
local spectateTarget = nil

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

local function fetchPlayers()
    return lib.callback.await("sw:menu:getPlayers", false) or {}
end

local function reopenKeyboardMenu(id)
    Citizen.SetTimeout(100, function()
        lib.showMenu(id)
    end)
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
    local input = promptReason("Request Staff", false)
    if (input == nil or input.reason == nil or input.reason == "") then return end

    local success, response = lib.callback.await("sw:menu:requestStaff", false, input.reason)
    showResult(success, response, "Staff Requested")
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
end

local function createPortalCode()
    local success, response = lib.callback.await("sw:menu:createPortalCode", false)
    showResult(success, response, "Player Portal")
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

local function runRemoteAction(target, targetLabel, actionType)
    local title = ("%s %s"):format(actionType:sub(1, 1) .. actionType:sub(2):lower(), targetLabel)
    local input = nil
    local duration = nil

    if (actionType == "BAN") then
        input = lib.inputDialog(title, {
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
        })

        if (input == nil) then return end
        duration = trim(input[1])
        if (duration == "perm" or duration == "permanent") then
            duration = nil
        end
        input = {
            reason = trim(input[2]),
            details = trim(input[3])
        }
    else
        input = promptReason(title, actionType ~= "KICK")
        if (input == nil) then return end
    end

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
        duration
    )
    showResult(success, response, "Action Executed")
end

local function setSpectate(target)
    if (not canUseLocalTools()) then return end

    if (spectating and spectateTarget == target) then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        spectating = false
        spectateTarget = nil
        notify("StaffWatch", "Spectate disabled.", "success")
        return
    end

    local targetPlayer = GetPlayerFromServerId(target)
    if (targetPlayer == -1) then
        notify("StaffWatch", "Target player is not currently streamed in.", "error")
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if (not DoesEntityExist(targetPed)) then
        notify("StaffWatch", "Target player is not currently available.", "error")
        return
    end

    NetworkSetInSpectatorMode(true, targetPed)
    spectating = true
    spectateTarget = target
    notify("StaffWatch", "Spectating player. Select them again to stop.", "success")
end

local function getNoclipEntity()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if (vehicle ~= 0) then return vehicle end
    return ped
end

local function showKeyboardMenu(id, title, parentId, options, onSelect)
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
        options = options
    }, function(selected, scrollIndex, args)
        if (onSelect ~= nil) then
            onSelect(args, selected, scrollIndex)
        end
    end)

    lib.showMenu(id)
end

local function openPlayerActions(target, targetLabel)
    showKeyboardMenu("sw_player_actions_" .. target, targetLabel, "sw_staff_menu", {
        {label = "Note", description = "Add private staff context to this player's record", icon = "note-sticky", iconColor = ICON_COLORS.sky, args = {action = "note"}},
        {label = "Commend", description = "Record positive behavior for this player", icon = "thumbs-up", iconColor = ICON_COLORS.green, args = {action = "commend"}},
        {label = "Warn", description = "Issue a formal warning and save it to StaffWatch", icon = "triangle-exclamation", iconColor = ICON_COLORS.amber, args = {action = "warn"}},
        {label = "Kick", description = "Remove this player from the server with a recorded reason", icon = "right-from-bracket", iconColor = ICON_COLORS.amber, args = {action = "kick"}},
        {label = "Ban", description = "Create a temporary or permanent StaffWatch ban", icon = "ban", iconColor = ICON_COLORS.red, args = {action = "ban"}},
        {label = "Teleport To Player", description = "Move yourself to this player's current location", icon = "location-dot", iconColor = ICON_COLORS.cyan, args = {action = "teleport"}},
        {label = "Summon Player", description = "Bring this player to your current location", icon = "user-plus", iconColor = ICON_COLORS.cyan, args = {action = "summon"}},
        {label = "Spectate Player", description = "Watch this player; select again to stop", icon = "eye", iconColor = ICON_COLORS.purple, args = {action = "spectate"}},
        {label = "Freeze Player", description = "Stop this player from moving", icon = "snowflake", iconColor = ICON_COLORS.sky, args = {action = "freeze"}},
        {label = "Unfreeze Player", description = "Restore movement for this player", icon = "sun", iconColor = ICON_COLORS.green, args = {action = "unfreeze"}}
    }, function(args)
        if (args.action == "note") then
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
        elseif (args.action == "spectate") then
            setSpectate(target)
            reopenKeyboardMenu("sw_player_actions_" .. target)
        elseif (args.action == "freeze") then
            TriggerServerEvent("sw:menu:setFreeze", target, true)
        elseif (args.action == "unfreeze") then
            TriggerServerEvent("sw:menu:setFreeze", target, false)
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

local function toggleNoclip()
    if (not canUseLocalTools()) then return end

    noclipEnabled = not noclipEnabled

    local ped = PlayerPedId()
    if (noclipEnabled) then
        noclipEntity = getNoclipEntity()
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
    end

    notify("StaffWatch", noclipEnabled and "Noclip enabled." or "Noclip disabled.", "success")
end

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

local function openServerTools()
    showKeyboardMenu("sw_server_tools", "Server Tools", "sw_staff_menu", {
        {label = "Announcement", description = "Broadcast a StaffWatch announcement to the server", icon = "bullhorn", iconColor = ICON_COLORS.brand, args = {action = "announcement"}},
        {label = "Teleport To Waypoint", description = "Move yourself to your active map waypoint", icon = "map", iconColor = ICON_COLORS.cyan, args = {action = "waypoint"}},
        {label = "Copy Current Coordinates", description = "Copy your current position to the clipboard", icon = "copy", iconColor = ICON_COLORS.sky, args = {action = "coords"}},
        {label = noclipEnabled and "Disable Noclip" or "Enable Noclip", description = "Toggle free movement for staff positioning", icon = "up-down-left-right", iconColor = noclipEnabled and ICON_COLORS.amber or ICON_COLORS.brand, args = {action = "noclip"}}
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
        elseif (args.action == "noclip") then
            toggleNoclip()
            Citizen.SetTimeout(100, openServerTools)
        end
    end)
end

local function openStaffMenu()
    local options = {
        {label = "Server Tools", description = "Announcements, noclip, waypoint teleport, and coordinates", icon = "wrench", iconColor = ICON_COLORS.brand, args = {action = "server"}}
    }

    local players = fetchPlayers()
    for _, player in ipairs(players) do
        local title = ("[%s] %s"):format(player.id, player.name)
        table.insert(options, {
            label = title,
            description = "Open moderation and staff utility actions",
            icon = "user",
            iconColor = ICON_COLORS.sky,
            args = {
                action = "player",
                target = player.id,
                label = title
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

    showKeyboardMenu("sw_staff_menu", "StaffWatch Staff", "sw_main_menu", options, function(args)
        if (args.action == "server") then
            openServerTools()
        elseif (args.action == "player") then
            openPlayerActions(args.target, args.label)
        end
    end)
end

local function openPlayerMenu()
    showKeyboardMenu("sw_player_menu", "StaffWatch", "sw_main_menu", {
        {label = "Request Staff", description = "Request assistance from an online staff member", icon = "hand", iconColor = ICON_COLORS.sky, args = {action = "request"}},
        {label = "Report Player", description = "Report another player for breaking rules in-game", icon = "flag", iconColor = ICON_COLORS.amber, args = {action = "report"}},
        {label = "Link StaffWatch Profile", description = "For Staff Members: Generate a code to link your in-game account to StaffWatch", icon = "link", iconColor = ICON_COLORS.cyan, args = {action = "link"}},
        {
            label = "Access Player Portal",
            description = "View action history, applications, appeals, and more",
            icon = "arrow-up-right-from-square",
            iconColor = ICON_COLORS.brand,
            args = {action = "portal"}
        }
    }, function(args)
        if (args.action == "request") then
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
    local status = lib.callback.await("sw:menu:getStaffStatus", false) or {}
    local options = {
        {
            label = "Player Menu",
            description = "Request assistance from staff or view your record",
            icon = "user",
            iconColor = ICON_COLORS.sky,
            args = {
                action = "player"
            }
        }
    }

    table.insert(options, {
        label = "Staff Menu",
        description = status.isStaff and "Moderation tools for staff members" or "Link your StaffWatch account to unlock this menu",
        icon = "shield-halved",
        iconColor = status.isStaff and ICON_COLORS.brand or ICON_COLORS.slate,
        args = {
            action = "staff",
            allowed = status.isStaff == true
        }
    })

    showKeyboardMenu("sw_main_menu", "StaffWatch", nil, options, function(args)
        if (args.action == "player") then
            openPlayerMenu()
        elseif (args.action == "staff") then
            if (args.allowed) then
                openStaffMenu()
            else
                notify("StaffWatch", "Link your StaffWatch staff account to unlock this menu.", "error")
            end
        end
    end)
end

RegisterCommand("staffwatch", openMainMenu, false)
RegisterCommand("swmenu", openMainMenu, false)

lib.addKeybind({
    name = "staffwatch_menu",
    description = "Open StaffWatch menu",
    defaultKey = "F7",
    onPressed = openMainMenu
})
