# StaffWatch-FiveM
This resource allows you to integrate your FiveM server with the new release of [StaffWatch](https://panel.staffwatch.app).

![StaffWatch Branding Image](https://panel.staffwatch.app/StaffWatch-logo-background.png)

## Installation
- Add the resource to the `server-data/resources` folder
- Add your server secret to the `config.lua` file
- Configure any other settings within the config file
- Restart the server, or use `refresh` and `start` commands.

## Commands
- `/link` - Generates a code which will allow staff members to link their player profile to StaffWatch
- `/portal` - Generates a link which allows players to view their record in StaffWatch and submit ban appeals
- `/report` - Allows players to report other players to the staff team
- `/staffrequest` - Allows players to request assistance from the staff team
- `/note <id> <reason>` - Adds a staff note to an online player
- `/commend <id> <reason>` - Commends an online player
- `/warn <id> <reason>` - Warns an online player
- `/kick <id> <reason>` - Kicks an online player
- `/ban <id> <duration|perm> <reason>` - Bans an online player
