SW_LIVE_SCREEN_TARGETS = {}

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(OrDefault('liveScreenPollInterval', 1000))
    pcall(HandleLiveScreenQueue)
  end
end)

RegisterNetEvent('sw:liveScreenStatus')
AddEventHandler('sw:liveScreenStatus', function(sessionId, status, message)
  local target = SW_LIVE_SCREEN_TARGETS[sessionId]
  if target == nil or tostring(target) ~= tostring(source) then
    return
  end

  ReportLiveScreenStatus(sessionId, status, message)

  if status == "STOPPED" or status == "FAILED" or status == "ERROR" or status == "TIMEOUT" then
    SW_LIVE_SCREEN_TARGETS[sessionId] = nil
  end
end)

AddEventHandler('playerDropped', function()
  local droppedPlayer = source
  for sessionId, target in pairs(SW_LIVE_SCREEN_TARGETS) do
    if tostring(target) == tostring(droppedPlayer) then
      SW_LIVE_SCREEN_TARGETS[sessionId] = nil
      ReportLiveScreenStatus(sessionId, "FAILED", "Player disconnected")
    end
  end
end)

function HandleLiveScreenQueue()
  local success, rawResponse = SendAPIRequest("/api/live-screen/pending", {
    secret = Config.SECRET
  })

  if not success then
    return
  end

  local commands = json.decode(rawResponse)
  if commands == nil then
    return
  end

  for _, command in ipairs(commands) do
    if command.action == "START" then
      StartLiveScreen(command)
    elseif command.action == "STOP" then
      StopLiveScreen(command.sessionId)
    end
  end
end

function StartLiveScreen(command)
  local target = FindPlayerByPrimaryIdentifier(command.targetPrimaryIdentifier)
  if target == nil then
    ReportLiveScreenStatus(command.sessionId, "FAILED", "Player is no longer online")
    return
  end

  SW_LIVE_SCREEN_TARGETS[command.sessionId] = target
  TriggerClientEvent('sw:liveScreenStart', target, command)
  ReportLiveScreenStatus(command.sessionId, "PLAYER_READY", "Live screen request sent to player")
end

function StopLiveScreen(sessionId)
  local target = SW_LIVE_SCREEN_TARGETS[sessionId]
  if target ~= nil then
    TriggerClientEvent('sw:liveScreenStop', target, sessionId)
  else
    TriggerClientEvent('sw:liveScreenStop', -1, sessionId)
    ReportLiveScreenStatus(sessionId, "STOPPED", "Live screen stopped")
    SW_LIVE_SCREEN_TARGETS[sessionId] = nil
  end
end

function ReportLiveScreenStatus(sessionId, status, message)
  if sessionId == nil or status == nil then
    return
  end

  SendAPIRequest("/api/live-screen/status", {
    secret = Config.SECRET,
    sessionId = sessionId,
    status = status,
    message = message
  })
end

function FindPlayerByPrimaryIdentifier(primaryIdentifier)
  if primaryIdentifier == nil then
    return nil
  end

  local players = GetPlayers()
  for _, playerId in ipairs(players) do
    local license = GetPlayerIdentifierByType(playerId, "license")
    if license ~= nil and string.sub(license, 1, 8) == "license:" then
      if string.sub(license, 9) == primaryIdentifier then
        return playerId
      end
    end
  end
  return nil
end
