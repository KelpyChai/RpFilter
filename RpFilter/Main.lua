import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.ColorPicker"

local ChatType = Turbine.ChatType

local function print(text, hexColor)
    Turbine.Shell.WriteLine("<rgb=" .. hexColor .. ">" .. text .. "</rgb>")
end

local function toHexColor(color)
    return string.format("#%02X%02X%02X", color.red, color.green, color.blue)
end

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

    DrawOptionsPanel()

    function plugin.Unload(sender, args)
        RemoveCallback(Turbine.Chat, "Received", chatParser)
        Settings:save()
    end

    Turbine.Shell.WriteLine("RP Filter v1.0 by Dandiron")
    Turbine.Shell.WriteLine("- If the NPC filter isn't working, make sure you have Regional or OOC enabled")
    Turbine.Shell.WriteLine("- Chat colour can be customized in settings")
end

main()
