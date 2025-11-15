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
        print(Say.format(message, Settings.getSayColor()))
        if Say.isFromPlayer(message) then Logger.log(message) end
    elseif channel == ChatType.Emote then
        local s = Settings
        print(Emote.format(message, s.getEmoteColor(), s.getSayColor(), s.getOptions()))
        Logger.log(message)
    end
end

local replayCmd = Turbine.ShellCommand()
function replayCmd:Execute() Logger.dump() end
function replayCmd:GetShortHelp() return "Prints all says and emotes from this session." end
function replayCmd:GetHelp()
    return "usage: /replay\nThis command prints out all says and emotes by players.\n\n"
        .. "The history is cleared whenever the player logs out (or unloads the plugin), "
        .. "so make sure to grab logs first. Once you're done with RP,\n"
        .. "1. Start logging your RP tab\n2. Use /replay\n3. Stop logging"
end

function plugin.Load(_, _)
    Settings.loadSync()
    Callback.add(Turbine.Chat, "Received", chatParser)
    Turbine.Shell.AddCommand("replay", replayCmd)

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
    Turbine.Shell.RemoveCommand(replayCmd)
end
