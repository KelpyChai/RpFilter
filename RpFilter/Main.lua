import "Dandiron.RpFilter.Callback"

ChatType = Turbine.ChatType

function ChatParser(sender, args)
    if not args.Message then return end

    local message = args.Message:gsub("%s+$", "")
    local channel = args.ChatType

    if channel == ChatType.Standard then
        Location:updateIfChanged(message)
    elseif channel == ChatType.Quest then
        Location:updateIfInstanced(message)
    elseif channel == ChatType.Say then
        Turbine.Shell.WriteLine(message)
    elseif channel == ChatType.Emote then
        Turbine.Shell.WriteLine(message)
    end
end

AddCallback(Turbine.Chat, "Received", ChatParser)

Plugins["RP Filter"].Unload = function (sender, args)
    RemoveCallback(Turbine.Chat, "Received", ChatParser)
end
