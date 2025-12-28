-- Commend command
RegisterCommand("sw_commend", function(source, args, rawCommand)
    handleCommand("sw_commend", source, args, rawCommand)
end, false)

-- Warn command
RegisterCommand("sw_warn", function(source, args, rawCommand)
    handleCommand("sw_warn", source, args, rawCommand)
end, false)

-- Kick command
RegisterCommand("sw_kick", function(source, args, rawCommand)
    handleCommand("sw_kick", source, args, rawCommand)
end, false)

-- Ban command
RegisterCommand("sw_ban", function(source, args, rawCommand)
    handleCommand("sw_ban", source, args, rawCommand)
end, false)

-- Actual command handler
function handleCommand(command, source, args, rawCommand)

    DebugLog("Recieved raw command: " .. rawCommand)

    -- Disallow players from using command
    if (source ~= 0) then
        print("This command can only be executed by the server!")
        return
    end

    -- Ensure enough args provided
    if (#args < 2) then
        print("Not enough args provided!")
        return
    end

    -- Get player license
    local license = args[1]
    DebugLog("Player License: " .. license)
    
    -- Get player id
    local playerId = GetPlayerIdByLicense(license)
    if (playerId == nil) then
        print("No player found with license: " .. license)
        return
    end
    DebugLog("Player ID: "..playerId)

    -- Get reason
    local reason = string.sub(rawCommand, #command + #license + 3)
    DebugLog("Reason: " .. reason)

    -- Kick and Ban
    if (command == "sw_kick") then
        DropPlayer(playerId, "You have been kicked for: " .. reason)
    elseif (command == "sw_ban") then
        DropPlayer(playerId, "You have been banned for: " .. reason .. '\nReconnect for details and appeal instructions')
    end

    -- Commend
    if (command == "sw_commend") then
        SendChatMessage(playerId, "You have been commended for: " .. reason)
        TriggerClientEvent("sw:createAnnouncement", playerId, "~g~StaffWatch Commendation", "You've been commended for: " .. reason, 5000)
    end

    -- Warn
    if (command == "sw_warn") then
        SendChatMessage(playerId, "You have been warned for: " .. reason)
        TriggerClientEvent("sw:createAnnouncement", playerId, "~y~StaffWatch Warning", "You've been warned for: " .. reason, 8000)
    end

end

-- Freeze command
RegisterCommand('sw_freeze', function(source, args, rawCommand)
    if (source == 0) then
        SendChatMessage(args[1], "You have been frozen by staff.")
        TriggerClientEvent('sw:freeze', args[1])
        TriggerClientEvent('sw:createAnnouncement', args[1], "~b~Frozen by Staff", "You have been frozen by staff. Please standby for further instructions.", 5000)
    end
end, false)

-- Unfreeze command
RegisterCommand('sw_unfreeze', function(source, args, rawCommand)
    if (source == 0) then
        SendChatMessage(args[1], "You have been unfrozen by staff.")
        TriggerClientEvent('sw:unfreeze', args[1])
        TriggerClientEvent('sw:createAnnouncement', args[1], "~b~Unfrozen by Staff", "You have been unfrozen by staff. You may now move freely.", 5000)
    end
end, false)

-- Announce command
RegisterCommand("sw_announce", function(source, args, rawCommand)
    if source == 0 then
        local message = table.concat(args, " ")
        SendChatMessage(-1, "Server Announcement: " .. message)
        TriggerClientEvent('sw:createAnnouncement', -1, "~b~Server Announcement", message, 10000)
    end
end, false)