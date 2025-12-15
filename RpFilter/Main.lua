import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.OptionsPanel"
import "Dandiron.RpFilter.Logger"

import "Turbine.Gameplay"

LOCAL_PLAYER_NAME = Turbine.Gameplay.LocalPlayer:GetInstance():GetName()

do
    local lastPoster
    function print(message, player)
        if not player then
            Turbine.Shell.WriteLine(message)
            return
        end

        if Settings.getOptions().areNewlinesPrinted and player ~= lastPoster then
            Turbine.Shell.WriteLine("")
        end
        lastPoster = player
        Turbine.Shell.WriteLine(message)
    end
end

local function chatParser(_, args)
    local ChatType = Turbine.ChatType
    local message, channel = args.Message, args.ChatType

    if channel == ChatType.Standard then
        Location.update(message)
    elseif channel == ChatType.Say and Say.isAllowed(message) then
        Say.print(message, Settings.getSayColor())
    elseif channel == ChatType.Emote then
        local s = Settings
        Emote.print(message, s.getEmoteColor(), s.getSayColor(), s.getOptions())
    end
end

function plugin.Load(_, _)
    Settings.loadSync()
    Callback.add(Turbine.Chat, "Received", chatParser)
    Turbine.Shell.AddCommand("replay", Logger.replay)

    DrawOptionsPanel(Settings.getOptions())

    print("<rgb=#DAA520><u>RP Filter v"..plugin:GetVersion().." by Dandiron</u></rgb>")
    if Settings.isFirstLoad() then
        print("You can choose say and emote colour in /plugins manager")
    end
    print("For easy logging, use /replay to print all previous says and emotes")
end

function plugin.Unload(_, _)
    Settings.saveSync()
    Callback.remove(Turbine.Chat, "Received", chatParser)
    Turbine.Shell.RemoveCommand(Logger.replay)
end
