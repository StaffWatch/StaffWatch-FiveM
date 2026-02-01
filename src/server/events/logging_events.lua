-- Chat Message Logs
RegisterNetEvent('chatMessage')
AddEventHandler('chatMessage', function(source, author, text)
    LogEvent("CHAT_MESSAGE", source, nil, {
        content = text
    })
end)

-- Player Join Logs
AddEventHandler('playerJoining', function()
    LogEvent("PLAYER_JOIN", source, nil, {})
end)

-- Player Leave Logs
AddEventHandler('playerDropped', function()
	LogEvent("PLAYER_LEAVE", source, nil, {})
end)

-- Player Death
RegisterServerEvent('playerDied')
AddEventHandler('playerDied',function(message, location, x, y, z, weapon)
    LogEvent("PLAYER_DIED", source, nil, {
        content = message,
        location = location,
        coordinatesX = x,
        coordinatesY = y,
        coordinatesZ = z,
        weapon = weapon
    })
end)

RegisterServerEvent('playerDiedFromPlayer')
AddEventHandler('playerDiedFromPlayer',function(message, killer_id, location, x, y, z, weapon)
    LogEvent("PLAYER_KILL", killer_id, source, {
        content = message,
        location = location,
        coordinatesX = x,
        coordinatesY = y,
        coordinatesZ = z,
        weapon = weapon
    })
end)

-- Player Revived
RegisterServerEvent('playerRespawned')
AddEventHandler('playerRespawned',function(location, x, y, z)
    LogEvent("PLAYER_RESPAWN", source, nil, {
        location = location,
        coordinatesX = x,
        coordinatesY = y,
        coordinatesZ = z
    })
end)