local queuedLogs = {}

LogEvent = function(eventType, arbitratorId, targetId, opts)
    opts = opts or {}

    local log = {
        type = eventType, -- e.g. "PLAYER_JOIN", "CHAT_MESSAGE", etc.
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),

        arbitratorPrimary = arbitratorId ~= nil
            and GetPlayerPrimaryIdentifier(arbitratorId)
            or nil,

        targetPrimary = targetId ~= nil
            and GetPlayerPrimaryIdentifier(targetId)
            or nil,

        content = opts.content or nil,
        reason = opts.reason or nil,
        location = opts.location or nil,

        coordinatesX = opts.coordinatesX or nil,
        coordinatesY = opts.coordinatesY or nil,
        coordinatesZ = opts.coordinatesZ or nil,

        damageAmt = opts.damageAmt or nil,
        weapon = opts.weapon or nil
    }

    table.insert(queuedLogs, log)
end

Citizen.CreateThread(function()
  while true do
    pcall(UploadLogs)
    Citizen.Wait(OrDefault('logUploadInterval', 5000))
  end
end)

function UploadLogs()
    -- If there are no logs to upload, skip the request
    if #queuedLogs == 0 then
        return
    end

    -- Upload logs to the API endpoint
    local success, _ = SendAPIRequest("/api/log-events", {
        secret = Config.SECRET,
        events = queuedLogs
    })

    -- Only clear queue if the request was successful
    if (success) then
        queuedLogs = {}
    end
end