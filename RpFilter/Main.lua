import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.TextUtils"

local ChatType = Turbine.ChatType
print = Turbine.Shell.WriteLine

local function chatParser(sender, args)
    if not args.Message then return end

    local message = Strip(args.Message)
    local channel = args.ChatType

    if channel == ChatType.Standard then
        Location.updateIfChanged(message)
    elseif channel == ChatType.Say and Say.isAllowed(message) then
        print(Say.format(message, Settings.get().sayColor))
        -- if message:sub(1, 1) == "<" then print(message:gsub("<", "|"):gsub(">", "|")) end -- debugging
    elseif channel == ChatType.Emote then
        print(Emote.format(message, Settings.get()))
    end
end

function plugin.Load(sender, args)
    Settings.load()
    Callback.add(Turbine.Chat, "Received", chatParser)

    Settings.DrawOptionsPanel()

    print("<u>RP Filter v"..plugin:GetVersion().." by Dandiron</u>")
    print("- Chat colour can be customized in Options (via /plugins manager)")
    print("- NPC filter not working? Disable Regional and OOC, then reenable")
end

function plugin.Unload(sender, args)
    Settings.save()
    Callback.remove(Turbine.Chat, "Received", chatParser)
end
