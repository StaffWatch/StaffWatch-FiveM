local commandSuggestions = {
    {
        name = "/link",
        help = "Generate a code to link your in-game player profile to StaffWatch",
        params = {}
    },
    {
        name = "/portal",
        help = "Generate a player portal access link",
        params = {}
    },
    {
        name = "/report",
        help = "Report a player to staff",
        params = {
            { name = "playerId", help = "In-game server ID of the player" },
            { name = "reason", help = "Reason for the report" }
        }
    },
    {
        name = "/staffrequest",
        help = "Request assistance from staff",
        params = {
            { name = "reason", help = "Reason you need staff assistance" }
        }
    },
    {
        name = "/note",
        help = "Add a staff note to a player",
        params = {
            { name = "id", help = "In-game server ID of the target player" },
            { name = "reason", help = "Reason for the note" }
        }
    },
    {
        name = "/commend",
        help = "Commend a player",
        params = {
            { name = "id", help = "In-game server ID of the target player" },
            { name = "reason", help = "Reason for the commendation" }
        }
    },
    {
        name = "/warn",
        help = "Warn a player",
        params = {
            { name = "id", help = "In-game server ID of the target player" },
            { name = "reason", help = "Reason for the warning" }
        }
    },
    {
        name = "/kick",
        help = "Kick a player",
        params = {
            { name = "id", help = "In-game server ID of the target player" },
            { name = "reason", help = "Reason for the kick" }
        }
    },
    {
        name = "/ban",
        help = "Ban a player",
        params = {
            { name = "id", help = "In-game server ID of the target player" },
            { name = "duration", help = "Duration (ex: 5yr2mo3d4h5m) or perm" },
            { name = "reason", help = "Reason for the ban" }
        }
    }
}

Citizen.CreateThread(function()
    TriggerEvent("chat:addSuggestions", commandSuggestions)
end)
