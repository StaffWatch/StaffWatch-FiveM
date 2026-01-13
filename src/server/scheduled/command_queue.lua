Citizen.CreateThread(function()
  while true do
    pcall(HandleCommandQueue)
    Citizen.Wait(3000)
  end
end)

function HandleCommandQueue()
  -- Retrieve queued commands from API
  local success, rawResponse = SendAPIRequest("/api/command-queue", {
      secret = Config.SECRET
  })
  
  -- Execute commands
  if (success) then
    local commands = json.decode(rawResponse)
    for i in pairs(commands) do
      DebugLog("Executing command from command queue: " .. commands[i])
      ExecuteCommand(commands[i])
    end
  end
end