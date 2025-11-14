Logger = {}

local log = {}

function Logger.log(message)
    table.insert(log, message)
end

function Logger.dump()
    for _, message in ipairs(log) do print(message) end
end
