local queuedLogs = {}

LogEvent = function(message, arbitratorId, targetId)
    local log = {
        timestamp = os.time(),
        arbitratorPrimaryIdentifier = GetPlayerPrimaryIdentifier(arbitratorId),
        logContent = message,
    }
    if (targetId ~= nil) then
        log.targetPrimaryIdentifier = GetPlayerPrimaryIdentifier(targetId)
    end
    table.insert(queuedLogs, log)
end

Citizen.CreateThread(function()
  while true do
    pcall(UploadLogs)
    Citizen.Wait(5000)
  end
end)

function UploadLogs()
    -- If there are no logs to upload, skip the request
    if #queuedLogs == 0 then
        return
    end

    -- Upload logs to the API endpoint
    local success, _ = SendAPIRequest("/api/log", {
        secret = Config.SECRET,
        logs = queuedLogs
    })

    -- Only clear queue if the request was successful
    if (success) then
        queuedLogs = {}
    end
end