Citizen.CreateThread(function()
    while true do
        local ped = GetPlayerPed(-1)
        local priorityCooldown = true -- In a real scenario, this would actually check the priority state
        if (IsPedShooting(ped) and priorityCooldown) then
            TriggerServerEvent(
                "sw:selfRemoteAction",
                "KICK",
                "Shooting during priority cooldown",
                "Player was shooting on " .. GetStreetName() .. " during priority cooldown.",
                nil
            )
            Wait(10000) -- Wait a few seconds to make sure we do not create multiple actions!
        end
        Wait(0)
    end
end)

function GetStreetName()
    local playerPed = GetPlayerPed(-1)
    local coord = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(coord.x, coord.y, coord.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    return streetName
end