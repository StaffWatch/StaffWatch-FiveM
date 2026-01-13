-- Chat Message Logs
RegisterNetEvent('chatMessage')
AddEventHandler('chatMessage', function(source, author, text)
    LogEvent("%ARBITRATOR%: " .. text, source)
end)

-- Player Join Logs
AddEventHandler('playerConnecting', function()
    LogEvent("%ARBITRATOR% joined the server", source)
end)

-- Player Leave Logs
AddEventHandler('playerDropped', function()
	LogEvent("%ARBITRATOR% left the server", source)
end)

-- Player Death
RegisterServerEvent('playerDied')
AddEventHandler('playerDied',function(message)
    LogEvent("%ARBITRATOR%" .. message, source)
end)

RegisterServerEvent('playerDiedFromPlayer')
AddEventHandler('playerDiedFromPlayer',function(message, killer_id)
    LogEvent("%ARBITRATOR%" .. message .. "%TARGET%", killer_id, source)
end)