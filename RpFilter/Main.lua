import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"

local ChatType = Turbine.ChatType
local print = Turbine.Shell.WriteLine

local function chatParser(sender, args)
    if not args.Message then return end

    local message = args.Message:gsub("%s+$", "")
    local channel = args.ChatType

    if channel == ChatType.Standard then
        Location:updateIfChanged(message)
    elseif channel == ChatType.Say and Say:isAllowed(message) then
        print(message, toHexColor(Settings:getSayColor()))
        -- if message:sub(1, 1) == "<" then print(message:gsub("<", "|"):gsub(">", "|")) end -- debugging
    elseif channel == ChatType.Emote then
        print(Emote:format(message), toHexColor(Settings:getEmoteColor()))
    end
end

local function main()
    Settings:load()
    AddCallback(Turbine.Chat, "Received", chatParser)

    function plugin.Unload(sender, args)
        RemoveCallback(Turbine.Chat, "Received", chatParser)
        Settings:save()
    end
end

main()
