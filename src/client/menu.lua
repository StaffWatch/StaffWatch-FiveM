Citizen.CreateThread(function()
    WarMenu.CreateMenu("sw_menu_root", "StaffWatch")
    WarMenu.CreateSubMenu("sw_menu_self_options", "sw_menu_root", "Self Options")
    WarMenu.CreateSubMenu("sw_menu_player_list", "sw_menu_root", "Player List")
    WarMenu.CreateSubMenu("sw_menu_player_actions", "sw_menu_root", "Player")

    WarMenu.SetMenuX("sw_menu_root", 0.75)
    WarMenu.SetMenuX("sw_menu_self_options", 0.75)
    WarMenu.SetMenuX("sw_menu_player_list", 0.75)
    WarMenu.SetMenuX("sw_menu_player_actions", 0.75)

    RegisterCommand("swmenu", function()
        WarMenu.OpenMenu("sw_menu_root")
    end, false)

    RegisterKeyMapping("swmenu", "Open StaffWatch menu", "keyboard", "F6")

    while true do
        if WarMenu.IsMenuOpened("sw_menu_root") then
            WarMenu.MenuButton("Self Options", "sw_menu_self_options")
            WarMenu.MenuButton("Player List", "sw_menu_player_list")
            WarMenu.Display()
        elseif WarMenu.IsMenuOpened("sw_menu_self_options") then
            WarMenu.Button("Godmode Enabled")
            WarMenu.Display()
        elseif WarMenu.IsMenuOpened("sw_menu_player_list") then
            WarMenu.MenuButton("Player #1", "sw_menu_player_actions")
            WarMenu.MenuButton("Player #2", "sw_menu_player_actions")
            WarMenu.MenuButton("Player #3", "sw_menu_player_actions")
            WarMenu.Display()
        elseif WarMenu.IsMenuOpened("sw_menu_player_actions") then
            WarMenu.Button("Commend")
            WarMenu.Button("Warn")
            WarMenu.Button("Kick")
            WarMenu.Button("Ban")
            WarMenu.Display()
        else
            Citizen.Wait(250)
        end

        Citizen.Wait(0)
    end
end)
