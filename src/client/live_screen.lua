local activeLiveScreenSessionId = nil

RegisterNetEvent('sw:liveScreenStart')
AddEventHandler('sw:liveScreenStart', function(payload)
  activeLiveScreenSessionId = payload.sessionId
  SendNUIMessage({
    type = "startLiveScreen",
    payload = payload
  })
  TriggerServerEvent('sw:liveScreenStatus', payload.sessionId, "PLAYER_READY", nil)
end)

RegisterNetEvent('sw:liveScreenStop')
AddEventHandler('sw:liveScreenStop', function(sessionId)
  if activeLiveScreenSessionId == sessionId then
    activeLiveScreenSessionId = nil
  end
  SendNUIMessage({
    type = "stopLiveScreen",
    sessionId = sessionId
  })
end)

RegisterNUICallback('liveScreenStatus', function(data, cb)
  if data ~= nil and data.sessionId ~= nil and data.status ~= nil then
    TriggerServerEvent('sw:liveScreenStatus', data.sessionId, data.status, data.message)
    if data.status == "STOPPED" or data.status == "FAILED" or data.status == "ERROR" or data.status == "TIMEOUT" then
      activeLiveScreenSessionId = nil
    end
  end
  cb({ ok = true })
end)

AddEventHandler('onClientResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() and activeLiveScreenSessionId ~= nil then
    TriggerServerEvent('sw:liveScreenStatus', activeLiveScreenSessionId, "STOPPED", "Resource stopped")
  end
end)
