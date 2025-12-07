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
    Citizen.Wait(5000) -- Upload logs every 5 seconds
  end
end)

function UploadLogs()
    if #queuedLogs == 0 then
        return
    end
    -- Convert request to JSON
    local jsonData = json.encode({
        secret = Config.SECRET,
        logs = queuedLogs
    })

    DebugLog('Log upload JSON:')
    DebugLog(jsonData)

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/log", "POST", jsonData, {["Content-Type"] = 'application/json'}
    )

    -- Handle failure
    if (status ~= 200) then
        print("Warning: Bulk log upload failed with status code: " .. status)
        print("Failure reason: " .. errorData)
        return
    end

    -- Get result from API call
    DebugLog(resultData)

    queuedLogs = {}
end