RegisterNetEvent('sw:requestLivePlayer')
AddEventHandler('sw:requestLivePlayer', function()
    local player_data = {}

    -- Identification fields
    player_data["InGameId"] = GetPlayerServerId(PlayerId())
    player_data["Name"] = GetPlayerName(PlayerId())

    -- Standard fields
    player_data["Health"] = GetHealth()
    player_data["Armor"] = GetArmor()
    player_data["Status"] = GetPlayerStatus()
    player_data["Action"] = GetAction()
    player_data["Street"] = GetStreetName()
    player_data["Area"] = GetAreaName()

    local coords = GetCoordinates()
    player_data["X"] = string.format("%.3f", coords.x)
    player_data["Y"] = string.format("%.3f", coords.y)
    player_data["Z"] = string.format("%.3f", coords.z)

    -- Vehicle fields
    if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
        player_data["Vehicle"] = GetVehicleMakeModel()
        player_data["Speed"] = GetVehicleSpeed() .. " mph"
        player_data["Seat"] = GetVehicleSeat()
    end

    TriggerServerEvent('sw:updateLivePlayer', player_data)
end)

function GetHealth()
    return GetEntityHealth(GetPlayerPed(-1))
end

function GetArmor()
    return GetPedArmour(GetPlayerPed(-1))
end

function GetPlayerStatus()
    if IsPlayerDead(PlayerId()) then
        return "Dead"
    else
        return "Alive"
    end
end

function GetAreaName()
    local playerPed = GetPlayerPed(-1)
    local coord = GetEntityCoords(playerPed)
    local areaNameHash = GetNameOfZone(coord.x, coord.y, coord.z)
    local areaName = GetLabelText(areaNameHash)
    return areaName
end

function GetAction()
    if IsPedSittingInAnyVehicle(GetPlayerPed(-1)) then
        return "Driving"
    elseif IsPedSwimming(GetPlayerPed(-1)) then
        return "Swimming"
    elseif IsPedRunning(GetPlayerPed(-1)) then
        return "Running"
    elseif IsPedSprinting(GetPlayerPed(-1)) then
        return "Sprinting"
    elseif IsPedWalking(GetPlayerPed(-1)) then
        return "Walking"
    else
        return "Standing"
    end
end

GetStreetName = function()
    local playerPed = GetPlayerPed(-1)
    local coord = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(coord.x, coord.y, coord.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    return streetName
end

function GetCoordinates()
    local playerPed = GetPlayerPed(-1)
    local coord = GetEntityCoords(playerPed)
    return { x = coord.x, y = coord.y, z = coord.z }
end

function GetVehicleMakeModel()
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    local make = GetMakeNameFromVehicleModel(GetEntityModel(vehicle))
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    return make .. " " .. model
end

function GetVehicleSpeed()
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
    local speed = GetEntitySpeed(vehicle) * 2.23694 -- Convert m/s to mph
    return math.floor(speed)
end

function GetVehicleSeat()
    local ped = GetPlayerPed(-1)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then
            if seat == -1 then
                return "Driver"
            else
                return "Seat #" .. seat
            end
        end
    end
    return "Unknown"
end