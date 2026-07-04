# StaffWatch-FiveM
This resource allows you to integrate your FiveM server with the new release of [StaffWatch](https://panel.staffwatch.app).

![StaffWatch Branding Image](https://panel.staffwatch.app/StaffWatch-logo-background.png)

## Installation
- Download this respository as a ZIP and add the resource to your `server-data/resources` folder.
- Download `ox_lib` from the [ox_lib releases page](https://github.com/overextended/ox_lib/releases), add it to your `server-data/resources` folder
- Add your server secret to `config.lua`.
- Configure any other server settings in `config.lua`.
- Configure client-only menu settings in `client_config.lua`.
- Add both resources to `server.cfg`, making sure `ox_lib` starts first:
  ```cfg
  ensure ox_lib
  ensure StaffWatch-FiveM
  ```
- Restart the server, or run `refresh` followed by `start StaffWatch-FiveM`.

## In-Game Menu
The StaffWatch in-game menu is powered by `ox_lib` and can be opened with `/staffwatch`, `/swmenu`, or the default keybind `F7`.

To change the default keybind, edit `Config.MENU_KEYBIND` in `client_config.lua`:

```lua
Config.MENU_KEYBIND = "F7"
```

Players can use the menu to:
- Request staff assistance.
- Report another online player.
- Generate a StaffWatch player portal access code.
- Generate a staff account linking code.
- Refresh staff permissions after linking their account.

Staff members can use the menu to:
- View online players sorted by in-game ID.
- Find a player directly by server ID.
- View basic player profile details, including trust score, playtime, and first played date.
- View a player's action history.
- Copy a player's StaffWatch profile link.
- Add notes, commend players, issue warnings, kick players, and ban players.
- Attach a StaffWatch rule to warnings, kicks, and bans.
- Teleport to players, summon players, spectate players, and freeze players.
- Use server tools such as announcements, waypoint teleport, coordinate copy, and noclip.

## Commands
- `/staffwatch` - Opens the StaffWatch menu
- `/swmenu` - Opens the StaffWatch menu
- `/link` - Generates a code which will allow staff members to link their player profile to StaffWatch
- `/portal` - Generates a link which allows players to view their record in StaffWatch and submit ban appeals
- `/report` - Allows players to report other players to the staff team
- `/staffrequest` - Allows players to request assistance from the staff team
- `/note <id> <reason>` - Adds a staff note to an online player
- `/commend <id> <reason>` - Commends an online player
- `/warn <id> <reason>` - Warns an online player
- `/kick <id> <reason>` - Kicks an online player
- `/ban <id> <duration|perm> <reason>` - Bans an online player
