Citizen.CreateThread(function()
  while true do
    pcall(DoRecurringUpdate)
    Citizen.Wait(15000)
  end
end)

function DoRecurringUpdate()
  -- Initialize players and dto
  local players = GetPlayers()
  local playersDto = {}

  -- Add each player to dto
  for _, playerId in ipairs(players) do
      local playerDto = CreatePlayerDTO(nil, playerId)
      table.insert(playersDto, playerDto)
  end

  -- Send API request with players
  SendAPIRequest("/api/check-in", {
      secret = Config.SECRET,
      players = playersDto
  })
end