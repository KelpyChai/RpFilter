import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.OptionsPanel"
import "Dandiron.RpFilter.Logger"

import "Turbine.Gameplay"

LOCAL_PLAYER_NAME = Turbine.Gameplay.LocalPlayer:GetInstance():GetName()
print = Turbine.Shell.WriteLine

local function chatParser(_, args)
    local ChatType = Turbine.ChatType
    local message, channel = args.Message, args.ChatType

    if channel == ChatType.Standard then
        Location.update(message)
    elseif channel == ChatType.Say and Say.isAllowed(message) then
        local formatted = Say.format(message, Settings.getSayColor())
        print(formatted)
        if Say.isFromPlayer(message) then Logger.log(formatted) end
    elseif channel == ChatType.Emote then
        local s = Settings
        local formatted = Emote.format(message, s.getEmoteColor(), s.getSayColor(), s.getOptions())
        print(formatted)
        Logger.log(formatted)
    end
end

local replayCmd = Turbine.ShellCommand()
function replayCmd:Execute() Logger.dump() end
function replayCmd:GetHelp() return "replay: Print all says and emotes that have occurred" end

function plugin.Load(_, _)
    Settings.loadSync()
    Callback.add(Turbine.Chat, "Received", chatParser)
    Turbine.Shell.AddCommand("replay", replayCmd)

    DrawOptionsPanel(Settings.getOptions())

    print("<rgb=#DAA520><u>RP Filter v"..plugin:GetVersion().." by Dandiron</u></rgb>")
    if Settings.isFirstLoad() then
        print("You can choose say and emote colour in /plugins manager")
    end
    print("To help with logging, /replay will print all prior says and emotes")
end

function plugin.Unload(_, _)
    Settings.saveSync()
    Callback.remove(Turbine.Chat, "Received", chatParser)
    Turbine.Shell.RemoveCommand(replayCmd)
end
