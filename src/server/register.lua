Citizen.CreateThread(function()

    -- Wait to make sure server online
    Citizen.Wait(5000)
      
    -- Convert request to JSON
    local jsonData = json.encode({
        secret = Config.SECRET,
        actions = Config.TEMPLATED_ACTIONS
    })

    DebugLog('Registration JSON:')
    DebugLog(jsonData)

    -- Send request to server
    local status, resultData, resultHeaders, errorData = PerformHttpRequestAwait(
        Config.API_URL .. "/api/register", "POST", jsonData, {["Content-Type"] = 'application/json'}
    )
    
    -- Handle failure
    if (status ~= 200) then
        print("Warning: Registration failed with status code: " .. status)
        print("Failure reason: " .. errorData)
    end

    -- Get result from API call
    DebugLog(resultData)
    print("Registered successfully!")
      
  end)