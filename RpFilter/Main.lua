import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.OptionsPanel"

import "Turbine.Gameplay"

LOCAL_PLAYER_NAME = Turbine.Gameplay.LocalPlayer:GetInstance():GetName()
print = Turbine.Shell.WriteLine

local function chatParser(_, args)
    local ChatType = Turbine.ChatType
    local message, channel = args.Message, args.ChatType

    if channel == ChatType.Standard then
        Location.update(message)
    elseif channel == ChatType.Say and Say.isAllowed(message) then
        print(Say.format(message, Settings.getSayColor()))
    elseif channel == ChatType.Emote then
        local s = Settings
        print(Emote.format(message, s.getEmoteColor(), s.getSayColor(), s.getOptions()))
    end
end

function plugin.Load(_, _)
    Settings.loadSync()
    Callback.add(Turbine.Chat, "Received", chatParser)

    DrawOptionsPanel(Settings.getOptions())

    print("<rgb=#DAA520><u>RP Filter v"..plugin:GetVersion().." by Dandiron</u></rgb>")
    if Settings.isFirstTime() then
        print("You can choose say and emote colour in /plugins manager")
    end
end

function plugin.Unload(_, _)
    Settings.saveSync()
    Callback.remove(Turbine.Chat, "Received", chatParser)
end
