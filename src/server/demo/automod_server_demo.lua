Citizen.CreateThread(function()
  while true do
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerName = GetPlayerName(playerId)
        if (playerName and playerName:lower():find("potato")) then
            TriggerEvent(
                "sw:remoteAction",
                playerId,
                "BAN",
                "Player name contains prohibited word",
                "Player name: " .. playerName,
                60 * 1000 -- 1 minute ban
            )
            Citizen.Wait(10000) -- Wait a few seconds to avoid multiple bans
        end
    end
    Citizen.Wait(2000)
  end
end)