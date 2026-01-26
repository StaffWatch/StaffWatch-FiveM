SW_SERVER_DATA = {}

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(OrDefault('liveUpdateInterval', 2000))
    pcall(RetrieveAndSendLiveData)
  end
end)

RegisterServerEvent('sw:updateLivePlayer')
AddEventHandler('sw:updateLivePlayer',function(player_data)
  local primaryIdentifier = GetPlayerPrimaryIdentifier(source)
  SW_SERVER_DATA[primaryIdentifier] = player_data
end)

function RetrieveAndSendLiveData()
  if OrDefault('liveEnabled', false) then
    SW_SERVER_DATA = {}
    TriggerClientEvent('sw:requestLivePlayer', -1)
    Citizen.Wait(1000)
    if next(SW_SERVER_DATA) ~= nil then
        SendAPIRequest("/live/update", {
          secret = Config.SECRET,
          players = SW_SERVER_DATA
      })
    end
  end
end