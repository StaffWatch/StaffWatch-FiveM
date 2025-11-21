local isFrozen = false

-- Freeze Command
RegisterNetEvent('sw:freeze')
AddEventHandler('freeze:freezePlayer', function()
    FreezeEntityPosition(GetPlayerPed(-1), true)
    ClearPedTasksImmediately(GetPlayerPed(-1))
    isFrozen = true
end)

-- Unfreeze Command
RegisterNetEvent('sw:unfreeze')
AddEventHandler('sw:unfreeze', function()
    FreezeEntityPosition(GetPlayerPed(-1), false)
    isFrozen = false
end)