AddEventHandler("playerJoining", function(source, _)
    local playerDto = CreatePlayerDTO(GetPlayerName(source), source)
    SendAPIRequest("/api/request-join", {
        secret = Config.SECRET,
        player = playerDto
    })
end)