local noclipEnabled = false
local spectating = false
local spectateTarget = nil

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

local function openPlayerActions(target, targetLabel)
    lib.registerContext({
        id = "sw_player_actions_" .. target,
        title = targetLabel,
        menu = "sw_staff_players",
        options = {
            {
                title = "Note",
                icon = "note-sticky",
                onSelect = function()
                    runRemoteAction(target, targetLabel, "NOTE")
                end
            },
            {
                title = "Commend",
                icon = "thumbs-up",
                onSelect = function()
                    runRemoteAction(target, targetLabel, "COMMEND")
                end
            },
            {
                title = "Warn",
                icon = "triangle-exclamation",
                onSelect = function()
                    runRemoteAction(target, targetLabel, "WARN")
                end
            },
            {
                title = "Kick",
                icon = "right-from-bracket",
                onSelect = function()
                    runRemoteAction(target, targetLabel, "KICK")
                end
            },
            {
                title = "Ban",
                icon = "ban",
                onSelect = function()
                    runRemoteAction(target, targetLabel, "BAN")
                end
            },
            {
                title = "Teleport To Player",
                icon = "location-dot",
                onSelect = function()
                    TriggerServerEvent("sw:menu:teleportToPlayer", target)
                end
            },
            {
                title = "Summon Player",
                icon = "user-plus",
                onSelect = function()
                    TriggerServerEvent("sw:menu:summonPlayer", target)
                end
            },
            {
                title = "Spectate Player",
                icon = "eye",
                onSelect = function()
                    setSpectate(target)
                end
            },
            {
                title = "Freeze Player",
                icon = "snowflake",
                onSelect = function()
                    TriggerServerEvent("sw:menu:setFreeze", target, true)
                end
            },
            {
                title = "Unfreeze Player",
                icon = "sun",
                onSelect = function()
                    TriggerServerEvent("sw:menu:setFreeze", target, false)
                end
            }
        }
    })

    lib.showContext("sw_player_actions_" .. target)
end

local function openStaffPlayers()
    local players = fetchPlayers()
    local options = {}

    for _, player in ipairs(players) do
        local targetId = player.id
        local title = ("[%s] %s"):format(player.id, player.name)
        table.insert(options, {
            title = title,
            icon = "user",
            arrow = true,
            onSelect = function()
                openPlayerActions(targetId, title)
            end
        })
    end

    if (#options == 0) then
        table.insert(options, {
            title = "No online players",
            disabled = true
        })
    end

    lib.registerContext({
        id = "sw_staff_players",
        title = "Online Players",
        menu = "sw_staff_menu",
        options = options
    })

    lib.showContext("sw_staff_players")
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
    SetEntityCollision(ped, not noclipEnabled, not noclipEnabled)
    FreezeEntityPosition(ped, noclipEnabled)
    SetEntityInvincible(ped, noclipEnabled)

    notify("StaffWatch", noclipEnabled and "Noclip enabled." or "Noclip disabled.", "success")
end

Citizen.CreateThread(function()
    while true do
        if (noclipEnabled) then
            Wait(0)

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
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

            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, true, true, true)
        else
            Wait(500)
        end
    end
end)

local function openServerTools()
    if (not canUseLocalTools()) then return end

    lib.registerContext({
        id = "sw_server_tools",
        title = "Server Tools",
        menu = "sw_staff_menu",
        options = {
            {
                title = "Announcement",
                icon = "megaphone",
                onSelect = function()
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
                end
            },
            {
                title = "Teleport To Waypoint",
                icon = "map",
                onSelect = teleportToWaypoint
            },
            {
                title = "Copy Current Coordinates",
                icon = "copy",
                onSelect = copyCurrentCoords
            },
            {
                title = noclipEnabled and "Disable Noclip" or "Enable Noclip",
                icon = "up-down-left-right",
                onSelect = toggleNoclip
            }
        }
    })

    lib.showContext("sw_server_tools")
end

local function openStaffMenu()
    lib.registerContext({
        id = "sw_staff_menu",
        title = "StaffWatch Staff",
        menu = "sw_main_menu",
        options = {
            {
                title = "Online Players",
                icon = "users",
                arrow = true,
                onSelect = openStaffPlayers
            },
            {
                title = "Server Tools",
                icon = "wrench",
                arrow = true,
                onSelect = openServerTools
            }
        }
    })

    lib.showContext("sw_staff_menu")
end

local function openPlayerMenu()
    lib.registerContext({
        id = "sw_player_menu",
        title = "StaffWatch",
        menu = "sw_main_menu",
        options = {
            {
                title = "Request Staff",
                icon = "hand",
                onSelect = runPlayerRequest
            },
            {
                title = "Report Player",
                icon = "flag",
                onSelect = runPlayerReport
            },
            {
                title = "Link StaffWatch Profile",
                icon = "link",
                onSelect = createLinkCode
            },
            {
                title = "Access Player Portal",
                icon = "arrow-up-right-from-square",
                onSelect = createPortalCode
            }
        }
    })

    lib.showContext("sw_player_menu")
end

local function openMainMenu()
    local status = lib.callback.await("sw:menu:getStaffStatus", false) or {}
    local options = {
        {
            title = "Player Menu",
            icon = "user",
            arrow = true,
            onSelect = openPlayerMenu
        }
    }

    table.insert(options, {
        title = "Staff Menu",
        description = status.isStaff and "Moderation and local staff tools" or "Link your StaffWatch staff account to unlock this menu",
        icon = "shield-halved",
        arrow = status.isStaff == true,
        disabled = status.isStaff ~= true,
        onSelect = openStaffMenu
    })

    lib.registerContext({
        id = "sw_main_menu",
        title = "StaffWatch",
        options = options
    })

    lib.showContext("sw_main_menu")
end

RegisterCommand("staffwatch", openMainMenu, false)
RegisterCommand("swmenu", openMainMenu, false)

lib.addKeybind({
    name = "staffwatch_menu",
    description = "Open StaffWatch menu",
    defaultKey = "F7",
    onPressed = openMainMenu
})
