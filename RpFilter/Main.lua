import "Dandiron.RpFilter.Callback"

function ChatParser(sender, args)
    if not args.Message then return end

    local message = args.Message:gsub("%s+$", "")

    if args.ChatType == Turbine.ChatType.Say then
        Turbine.Shell.WriteLine(message)
    elseif args.ChatType == Turbine.ChatType.Emote then
        Turbine.Shell.WriteLine(message)
    end
end

AddCallback(Turbine.Chat, "Received", ChatParser)

Plugins["RP Filter"].Unload = function (sender, args)
    RemoveCallback(Turbine.Chat, "Received", ChatParser)
end
