AddEventHandler('sw:remoteAction',function(playerSource, actionType, reason, details, durationMs)
    SendAPIRequest("/api/remote-action", {
        secret = Config.SECRET,
        actionType = actionType,
        playerPrimary = GetPlayerPrimaryIdentifier(playerSource),
        reason = reason,
        details = details,
        durationMs = durationMs
    })
end)

RegisterServerEvent('sw:selfRemoteAction')
AddEventHandler('sw:selfRemoteAction',function(actionType, reason, details, durationMs)
    TriggerEvent('sw:remoteAction', source, actionType, reason, details, durationMs)
end)