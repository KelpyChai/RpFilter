Logger = {}

local log = {}

function Logger.log(message)
    table.insert(log, message)
end

local function replay()
    if #log == 0 then
        print("Nothing to replay yet!")
    else
        for _, message in ipairs(log) do print(message) end
    end
end

local replayCmd = Turbine and Turbine.ShellCommand() or {}
function replayCmd:Execute() replay() end
function replayCmd:GetShortHelp() return "Prints all says and emotes from this session." end
function replayCmd:GetHelp()
    return "usage: /replay\nThis command prints out all says and emotes by players.\n\n"
        .. "The history is cleared whenever the player logs out (or unloads the plugin), "
        .. "so make sure to grab logs first. Once you're done with RP,\n"
        .. "1. Start logging your RP tab\n2. Use /replay\n3. Stop logging"
end
Logger.replay = replayCmd
