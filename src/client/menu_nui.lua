local menuOpen = false
local toggleCommandName = "swmenu"
local godmodeEnabled = true

local function applyGodmodeState()
    local ped = PlayerPedId()
    SetPlayerInvincible(PlayerId(), godmodeEnabled)
    SetEntityInvincible(ped, godmodeEnabled)
end

local function syncGodmodeButtonState()
    SendNUIMessage({
        action = "updateMenuAction",
        tabId = "self",
        actionId = "toggle_godmode",
        enabled = godmodeEnabled
    })
end

local function setMenuState(state)
    menuOpen = state
    SetNuiFocus(state, false)
    SetNuiFocusKeepInput(state)
    SendNUIMessage({
        action = "setVisible",
        visible = state
    })

    if state then
        syncGodmodeButtonState()
    end
end

local function toggleMenu()
    setMenuState(not menuOpen)
end

RegisterNUICallback("closeMenu", function(_, cb)
    setMenuState(false)
    cb({})
end)

RegisterNUICallback("executeMenuAction", function(data, cb)
    local payload = data or {}
    local tabLabel = tostring(payload.tabLabel or "Unknown Tab")
    local actionIndex = tonumber(payload.actionIndex) or 0
    local actionId = tostring(payload.actionId or "")
    local title = tostring(payload.title or "Unknown Action")

    if actionId == "toggle_godmode" then
        godmodeEnabled = not godmodeEnabled
        applyGodmodeState()
        syncGodmodeButtonState()
        TriggerEvent("sw:notify", "Menu", ("Godmode %s"):format(godmodeEnabled and "Enabled" or "Disabled"))
        cb({})
        return
    end

    TriggerEvent("sw:notify", "Menu", ("[%s] Executed placeholder %d: %s"):format(tabLabel, actionIndex, title))
    cb({})
end)

RegisterCommand(toggleCommandName, function()
    toggleMenu()
end, false)

RegisterKeyMapping(toggleCommandName, "Open/Close StaffWatch Placeholder Menu", "keyboard", "F6")

CreateThread(function()
    while true do
        Citizen.Wait(0)

        if godmodeEnabled then
            applyGodmodeState()
        end
    end
end)
