-- Death Logs
Citizen.CreateThread(function()
    local isDead = false
    local Melee = { -1569615261, 1737195953, 1317494643, -1786099057, 1141786504, -2067956739, -868994466 }
    local Bullet = { 453432689, 1593441988, 584646201, -1716589765, 324215364, 736523883, -270015777, -1074790547, -2084633992, -1357824103, -1660422300, 2144741730, 487013001, 2017895192, -494615257, -1654528753, 100416529, 205991906, 1119849093 }
    local Knife = { -1716189206, 1223143800, -1955384325, -1833087301, 910830060, }
    local Car = { 133987706, -1553120962 }
    local Animal = { -100946242, 148160082 }
    local FallDamage = { -842959696 }
    local Explosion = { -1568386805, 1305664598, -1312131151, 375527679, 324506233, 1752584910, -1813897027, 741814745, -37975472, 539292904, 341774354, -1090665087 }
    local Gas = { -1600701090 }
    local Burn = { 615608432, 883325847, -544306709 }
    local Drown = { -10959621, 1936677264 }
    while true do
        Citizen.Wait(50)
        local ped = GetPlayerPed(-1)
        local coords = GetEntityCoords(ped)
        if IsEntityDead(ped) and not isDead then
			local killer = GetPedKiller(ped)
            local KillerId = nil
			for id = 0, 255 do
                if killer == GetPlayerPed(id) then
                    KillerId = GetPlayerServerId(id)
				end				
            end
            local death = GetPedCauseOfDeath(ped)
            local weaponName = GetWeaponDisplayName(death)
            local message = ""
            local byPlayer = KillerId ~= nil and KillerId ~= 0 and KillerId ~= GetPlayerServerId(PlayerId())
            if checkArray (Melee, death) then
                message = "meleed"
            elseif checkArray (Bullet, death) then
                message = "shot"
            elseif checkArray (Knife, death) then
                message = "stabbed"
            elseif checkArray (Car, death) then
                message = "was struck by a vehicle"
            elseif checkArray (Animal, death) then
                message = "died by an animal"
            elseif checkArray (FallDamage, death) then
                message = "died of fall damage"
            elseif checkArray (Explosion, death) then
                message = "died of an explosion"
            elseif checkArray (Gas, death) then
                message = "died of gas"
            elseif checkArray (Burn, death) then
                message = "burned to death"
            elseif checkArray (Drown, death) then
                message = "drowned"
            else
                message = byPlayer and "killed" or "died"
            end
            if byPlayer then
                print("Player died from player: " .. message .. " by " .. KillerId)
                TriggerServerEvent('sw:playerDiedFromPlayer', message, KillerId, GetCombinedLocation(), coords.x, coords.y, coords.z, weaponName)
            else
                print("Player died: " .. message)
                TriggerServerEvent('sw:playerDied', message, GetCombinedLocation(), coords.x, coords.y, coords.z, weaponName)
            end
            isDead = true
        end
		if not IsEntityDead(ped) and isDead then
            TriggerServerEvent('sw:playerRespawned', GetCombinedLocation(), coords.x, coords.y, coords.z)
			isDead = false
        end
	end
end)

-- Functions
function checkArray (array, val)
    for name, value in ipairs(array) do
        if value == val then
            return true
        end
    end
    return false
end

local weaponDisplayNames = {
    [-1834847097] = "Antique Cavalry Dagger",
    [-1786099057] = "Baseball Bat",
    [-102323637]  = "Broken Bottle",
    [2067956739]  = "Crowbar",
    [-1951375401] = "Flashlight",
    [1141786504]  = "Golf Club",
    [1317494643]  = "Hammer",
    [-102973651]  = "Hatchet",
    [-656458692]  = "Brass Knuckles",
    [-1716189206] = "Knife",
    [-581044007]  = "Machete",
    [-538741184]  = "Switchblade",
    [1737195953]  = "Nightstick",
    [419712736]   = "Pipe Wrench",
    [-853065399]  = "Battle Axe",
    [-1810795771] = "Pool Cue",
    [940833800]   = "Stone Hatchet",
    [453432689]   = "Pistol",
    [-1075685676] = "Pistol Mk II",
    [1593441988]  = "Combat Pistol",
    [584646201]   = "AP Pistol",
    [911657153]   = "Stun Gun",
    [-1716589765] = "Pistol .50",
    [-1076751822] = "SNS Pistol",
    [-2009644972] = "SNS Pistol Mk II",
    [-771403250]  = "Heavy Pistol",
    [137902532]   = "Vintage Pistol",
    [1198879012]  = "Flare Gun",
    [-598887786]  = "Marksman Pistol",
    [-1045183535] = "Heavy Revolver",
    [-879347409]  = "Heavy Revolver Mk II",
    [-1746263880] = "Double Action Revolver",
    [-1355376991] = "Up-n-Atomizer",
    [727643628]   = "Ceramic Pistol",
    [-1853920116] = "Navy Revolver",
    [324215364]   = "Micro SMG",
    [736523883]   = "SMG",
    [2024373456]  = "SMG Mk II",
    [-270015777]  = "Assault SMG",
    [171789620]   = "Combat PDW",
    [-619010992]  = "Machine Pistol",
    [-1121678507] = "Mini SMG",
    [1198256469]  = "Unholy Hellbringer",
    [487013001]   = "Pump Shotgun",
    [1432025498]  = "Pump Shotgun Mk II",
    [2017895192]  = "Sawed-Off Shotgun",
    [-494615257]  = "Assault Shotgun",
    [-1654528753] = "Bullpup Shotgun",
    [-1466123874] = "Musket",
    [984333226]   = "Heavy Shotgun",
    [-275439685]  = "Double Barrel Shotgun",
    [317205821]   = "Sweeper Shotgun",
    [-1074790547] = "Assault Rifle",
    [961495388]   = "Assault Rifle Mk II",
    [-2084633992] = "Carbine Rifle",
    [-86904375]   = "Carbine Rifle Mk II",
    [-1357824103] = "Advanced Rifle",
    [-1063057011] = "Special Carbine",
    [-1768145561] = "Special Carbine Mk II",
    [2132975508]  = "Bullpup Rifle",
    [-2066285827] = "Bullpup Rifle Mk II",
    [1649403952]  = "Compact Rifle",
    [-1660422300] = "MG",
    [2144741730]  = "Combat MG",
    [-608341376]  = "Combat MG Mk II",
    [1627465347]  = "Gusenberg Sweeper",
    [100416529]   = "Sniper Rifle",
    [205991906]   = "Heavy Sniper",
    [177293209]   = "Heavy Sniper Mk II",
    [-952879014]  = "Marksman Rifle",
    [1785463520]  = "Marksman Rifle Mk II",
    [-1312131151] = "RPG",
    [-1568386805] = "Grenade Launcher",
    [1305664598]  = "Grenade Launcher Smoke",
    [1119849093]  = "Minigun",
    [2138347493]  = "Firework Launcher",
    [1834241177]  = "Railgun",
    [1672152130]  = "Homing Launcher",
    [125959754]   = "Compact Grenade Launcher",
    [-1238556825] = "Widowmaker",
    [-1813897027] = "Grenade",
    [-1600701090] = "BZ Gas",
    [615608432]   = "Molotov Cocktail",
    [-1420407917] = "Proximity Mines",
    [126349499]   = "Snowballs",
    [-1169823560] = "Pipe Bombs",
    [600439132]   = "Baseball",
    [-37975472]   = "Tear Gas",
    [1233104067]  = "Flare",
    [741814745]   = "Sticky Bomb",
    [883325847]   = "Jerry Can",
    [-72657034]   = "Parachute",
    [101631238]   = "Fire Extinguisher",
    [-1168940174] = "Hazardous Jerry Can"
}

function GetWeaponDisplayName(hash)
    local h = tonumber(hash)
    return weaponDisplayNames[h] or nil
end