AddEventHandler('playerDropped', function (_, _, _)
    local playerDto = CreatePlayerDTO(nil, source)
    SendAPIRequest("/api/player-leave", {
        secret = Config.SECRET,
        player = playerDto
    })
end)