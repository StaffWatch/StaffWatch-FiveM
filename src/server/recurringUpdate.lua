local UPDATE_INTERVAL = 15000

Citizen.CreateThread(function()
  while true do
    pcall(DoRecurringUpdate)

    -- Wait before next update
    Citizen.Wait(UPDATE_INTERVAL)
    
  end
end)

function DoRecurringUpdate()
  -- Initialize players and dto
    local players = GetPlayers()
    local playersDto = {}

    -- Skip if no online players
    if (#players > 0) then

      -- Add each player to dto
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
          Config.API_URL .. "/api/check-in", "POST", jsonData, {["Content-Type"] = 'application/json'}
      )
      
      -- Handle failure
      if (status ~= 200) then
          print("Warning: Scheduled update failed with status code: " .. status)
          print("Failure reason: " .. errorData)
          return
      end

      -- Get result from API call
      DebugLog(resultData)

    end
end