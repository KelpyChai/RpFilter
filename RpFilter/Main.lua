import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"

ChatType = Turbine.ChatType
print = Turbine.Shell.WriteLine

function ChatParser(sender, args)
    if not args.Message then return end

    local message = args.Message:gsub("%s+$", "")
    local channel = args.ChatType

    if channel == ChatType.Standard then
        Location:updateIfChanged(message)
    elseif channel == ChatType.Quest then
        Location:updateIfInstanced(message)
    elseif channel == ChatType.Say then
        print(message)
    elseif channel == ChatType.Emote then
        print(message)
    end
end

AddCallback(Turbine.Chat, "Received", ChatParser)

Plugins["RP Chat Filter"].Unload = function (sender, args)
    RemoveCallback(Turbine.Chat, "Received", ChatParser)
end
