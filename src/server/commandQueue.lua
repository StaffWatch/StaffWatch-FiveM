local UPDATE_INTERVAL = 3000

Citizen.CreateThread(function()
  while true do
    pcall(HandleCommandQueue)
    Citizen.Wait(UPDATE_INTERVAL)
  end
end)

function HandleCommandQueue()
    -- Convert request to JSON
    DebugLog("Checking command queue...")
    local jsonData = json.encode({ secret = Config.SECRET })

    -- Send request to server
    local status, resultData, _, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/command-queue", "POST", jsonData, {["Content-Type"] = 'application/json'}
    )
    
    -- Handle failure
    if (status ~= 200) then
        print("Warning: Scheduled update failed with status code: " .. status)
        print("Failure reason: " .. errorData)
        return
    end

    DebugLog("Command queue response: " .. resultData)
    local commands = json.decode(resultData)
    
    -- Execute commands from command queue
    for i in pairs(commands) do
      DebugLog("Executing command from command queue: " .. commands[i])
      ExecuteCommand(commands[i])
    end

end