SW_SERVER_DATA = {}

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(1500)
    pcall(RetrieveAndSendLiveData)
  end
end)

RegisterServerEvent('sw:updateLivePlayer')
AddEventHandler('sw:updateLivePlayer',function(player_data)
  local primaryIdentifier = GetPlayerPrimaryIdentifier(source)
  SW_SERVER_DATA[primaryIdentifier] = player_data
end)

function RetrieveAndSendLiveData()
  SW_SERVER_DATA = {}
  TriggerClientEvent('sw:requestLivePlayer', -1)
  Citizen.Wait(1500)
  if next(SW_SERVER_DATA) ~= nil then
      SendAPIRequest("/live/update", {
        secret = Config.SECRET,
        players = SW_SERVER_DATA
    })
  end
end