local UPDATE_INTERVAL = 5000

Citizen.CreateThread(function()
  while true do
    
    local playersDto = {}

    -- Add each player to dto
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerDto = CreatePlayerDTO(nil, playerId)
        table.insert(playersDto, playerDto)
    end

    -- Convert request to JSON
    local jsonData = json.encode({
        secret = Config.SECRET,
        players = playersDto
    })

    DebugLog('Scheduled update JSON:')
    DebugLog(jsonData)

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/update", "POST", jsonData, {["Content-Type"] = 'application/json'}
    )
    
    -- Handle failure
    if (status ~= 200) then
        print("Warning: Scheduled update failed with status code: " .. status)
        print("Failure reason: " .. errorData)
    end

    -- Get result from API call
    DebugLog(resultData)
    local result = json.decode(resultData)
    
    -- Handle null result
    if (result == nil) then
      print("Warning: Response was null")
      return
    end

    -- Execute commands from command queue
    local commands = result.commands
    for i in pairs(commands) do
      DebugLog("Execute command: ".. commands[i])
      ExecuteCommand(commands[i])
    end

    -- Wait before next update
    Citizen.Wait(UPDATE_INTERVAL)
  end
end)