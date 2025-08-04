import "Dandiron.RpFilter.Callback"
import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.Say"
import "Dandiron.RpFilter.Emote"
import "Dandiron.RpFilter.Settings"

local ChatType = Turbine.ChatType
print = Turbine.Shell.WriteLine

local function toHexColor(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.red + 0.5),
        math.floor(color.green + 0.5),
        math.floor(color.blue + 0.5)
    )
end

---Wraps text in an RGB tag
---@param text string
---@param color table
---@return string
function AddRgbTag(text, color)
    return "<rgb=" .. toHexColor(color) .. ">" .. text .. "</rgb>"
end

local function chatParser(sender, args)
    if not args.Message then return end

    local message = args.Message:gsub("%s+$", "")
    local channel = args.ChatType

    if channel == ChatType.Standard then
        Location:updateIfChanged(message)
    elseif channel == ChatType.Say and Say:isAllowed(message) then
        print(AddRgbTag(Say:format(message), Settings:getSayColor()))
        -- if message:sub(1, 1) == "<" then print(message:gsub("<", "|"):gsub(">", "|")) end -- debugging
    elseif channel == ChatType.Emote then
        print(AddRgbTag(Emote:format(message), Settings:getEmoteColor()))
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

    print("<u>RP Filter v1.0.1 by Dandiron</u>")
    print("- Chat colour can be customized in Options (via /plugins manager)")
    print("- NPC filter not working? Disable Regional and OOC, then reenable")
end

main()
