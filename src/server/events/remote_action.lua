function ExecuteRemoteAction(playerSource, actionType, reason, details, durationMs, staffPrimary, duration)
    return SendAPIRequest("/api/remote-action", {
        secret = Config.SECRET,
        actionType = actionType,
        playerPrimary = GetPlayerPrimaryIdentifier(playerSource),
        staffPrimary = staffPrimary,
        reason = reason,
        details = details,
        duration = duration,
        durationMs = durationMs
    })
end

AddEventHandler('sw:remoteAction',function(playerSource, actionType, reason, details, durationMs, staffPrimary, duration)
    ExecuteRemoteAction(playerSource, actionType, reason, details, durationMs, staffPrimary, duration)
end)

RegisterServerEvent('sw:selfRemoteAction')
AddEventHandler('sw:selfRemoteAction',function(actionType, reason, details, durationMs, duration)
    TriggerEvent('sw:remoteAction', source, actionType, reason, details, durationMs, GetPlayerPrimaryIdentifier(source), duration)
end)
