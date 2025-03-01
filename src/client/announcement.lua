-- Create variables to store state
local announce = false
local announcementTitle = ''
local announcementDescription = ''

-- Event to create announcement
RegisterNetEvent('sw:createAnnouncement')
AddEventHandler('sw:createAnnouncement', function(title, description, time)
    if (not announce) then
        announce = true
        announcementTitle = title
        announcementDescription = description
        PlaySoundFrontend(-1, "DELETE","HUD_DEATHMATCH_SOUNDSET", 1)
        Citizen.Wait(time)
        announce = false
    end
end)

-- Display Notification
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if announce then
            local scaleform = RequestScaleformMovie('mp_big_message_freemode')
            while not HasScaleformMovieLoaded(scaleform) do
                Citizen.Wait(0)
            end
            PushScaleformMovieFunction(scaleform, 'SHOW_SHARD_WASTED_MP_MESSAGE')
            PushScaleformMovieFunctionParameterString(announcementTitle)
            PushScaleformMovieFunctionParameterString(announcementDescription)
            PopScaleformMovieFunctionVoid()
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        else
            Wait(500) -- If no announcement we can slow down the thread
        end
    end
end)