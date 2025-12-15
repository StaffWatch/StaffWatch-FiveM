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
        TriggerClientEvent("sw:createAnnouncement", playerId, "~g~StaffWatch Commendation", "You've been commended for: " .. reason, 5000)
    end

    -- Warn
    if (command == "sw_warn") then
        TriggerClientEvent("sw:createAnnouncement", playerId, "~y~StaffWatch Warning", "You've been warned for: " .. reason, 8000)
    end

end

-- Freeze command
RegisterCommand('sw_freeze', function(source, args, rawCommand)
    if (source == 0) then
        TriggerClientEvent('sw:freeze', args[1])
    else
        print("This command can only be executed by the server!")
    end
end, false)

-- Unfreeze command
RegisterCommand('sw_unfreeze', function(source, args, rawCommand)
    if (source == 0) then
        TriggerClientEvent('sw:unfreeze', args[1])
    else
        print("This command can only be executed by the server!")
    end
end, false)