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

-- Notify command
RegisterCommand("sw_notify", function(source, args, rawCommand)
    if source == 0 then
        local fullArgs = table.concat(args, " ")
        local playerId, title, message = string.match(fullArgs, '^(%d+) TITLE: (.+) MSG: (.+)$')
        print(playerId, title, message)
        SendChatMessage(playerId, "~b~" .. title .. ": ~w~" .. message)
        TriggerClientEvent('sw:notify', playerId, title, message)
    end
end, false)

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
    
    -- Get player id
    local playerId = GetPlayerIdByLicense(license)
    if (playerId == nil) then
        print("No player found with license: " .. license)
        return
    end

    -- Get reason
    local reason = string.sub(rawCommand, #command + #license + 3)

    -- Kick and Ban
    if (command == "sw_kick") then
        DropPlayer(playerId, "You have been kicked for: " .. reason)
        if (Config.BROADCAST_ACTIONS_TO_SERVER) then
            SendChatMessage(-1, GetPlayerName(playerId) .. " has been kicked for: " .. reason)
        end
    elseif (command == "sw_ban") then
        DropPlayer(playerId, "You have been banned for: " .. reason .. '\nReconnect for details and appeal instructions')
        if (Config.BROADCAST_ACTIONS_TO_SERVER) then
            SendChatMessage(-1, GetPlayerName(playerId) .. " has been banned for: " .. reason)
        end
    elseif (command == "sw_commend") then
        TriggerClientEvent("sw:createAnnouncement", playerId, "~g~StaffWatch Commendation", "You've been commended for: " .. reason, 5000)
        if (Config.BROADCAST_ACTIONS_TO_SERVER) then
            SendChatMessage(-1, GetPlayerName(playerId) .. " has been commended for: " .. reason)
        else
            SendChatMessage(playerId, "You have been commended for: " .. reason)
        end
    elseif (command == "sw_warn") then
        TriggerClientEvent("sw:createAnnouncement", playerId, "~y~StaffWatch Warning", "You've been warned for: " .. reason, 8000)
        if (Config.BROADCAST_ACTIONS_TO_SERVER) then
            SendChatMessage(-1, GetPlayerName(playerId) .. " has been warned for: " .. reason)
        else
            SendChatMessage(playerId, "You have been warned for: " .. reason)
        end
    end
end