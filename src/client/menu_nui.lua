local menuOpen = false
local toggleCommandName = "swmenu"

local function setMenuState(state)
    menuOpen = state
    SetNuiFocus(state, false)
    SetNuiFocusKeepInput(state)
    SendNUIMessage({
        action = "setVisible",
        visible = state
    })
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
    local tab = tostring(payload.tab or "Unknown Tab")
    local index = tonumber(payload.index) or 0
    local label = tostring(payload.label or "Unknown Action")
    TriggerEvent("sw:notify", "Menu", ("[%s] Executed placeholder %d: %s"):format(tab, index, label))
    cb({})
end)

RegisterCommand(toggleCommandName, function()
    toggleMenu()
end, false)

RegisterKeyMapping(toggleCommandName, "Open/Close StaffWatch Placeholder Menu", "keyboard", "F6")
