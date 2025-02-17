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
    DebugLog("Player License: " .. license)
    
    -- Get player id
    local playerId = GetPlayerIdByLicense(license)
    if (playerId == nil) then
        print("No player found with license: " .. license)
        return
    end

    -- Get reason
    local reason = string.sub(rawCommand, #command + #license + 3)
    DebugLog("Reason: " .. reason)

    -- Kick and Ban
    if (command == "sw_kick" or command == "sw_ban") then
        DropPlayer(playerId, "StaffWatch: " .. reason)
    end

end