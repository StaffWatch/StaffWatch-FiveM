function ExecuteRemoteAction(playerSource, actionType, reason, details, durationMs, staffPrimary, duration, ruleId)
    return SendAPIRequest("/api/remote-action", {
        secret = Config.SECRET,
        actionType = actionType,
        playerPrimary = GetPlayerPrimaryIdentifier(playerSource),
        staffPrimary = staffPrimary,
        reason = reason,
        details = details,
        duration = duration,
        durationMs = durationMs,
        ruleId = ruleId
    })
end

AddEventHandler('sw:remoteAction',function(playerSource, actionType, reason, details, durationMs, staffPrimary, duration, ruleId)
    ExecuteRemoteAction(playerSource, actionType, reason, details, durationMs, staffPrimary, duration, ruleId)
end)

RegisterServerEvent('sw:selfRemoteAction')
AddEventHandler('sw:selfRemoteAction',function(actionType, reason, details, durationMs, duration, ruleId)
    TriggerEvent('sw:remoteAction', source, actionType, reason, details, durationMs, GetPlayerPrimaryIdentifier(source), duration, ruleId)
end)
