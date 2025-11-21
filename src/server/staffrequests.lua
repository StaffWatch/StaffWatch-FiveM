RegisterCommand("staffrequest", function(source, args, rawCommand)
   
    -- Get reason
    local reason = string.match(rawCommand, "^%w+%s+(.*)")
    if (reason == nil) then
        print("Invalid reason specified!")
        return
    end

    -- Send request
    
    
end)