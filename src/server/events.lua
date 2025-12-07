RegisterNetEvent('chatMessage')
AddEventHandler('chatMessage', function(source, author, text)
    LogEvent("%ARBITRATOR% sent a chat message: " .. text, source)
end)