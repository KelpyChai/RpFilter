Logger = {}

local log = {}

function Logger.log(message)
    table.insert(log, message)
end

function Logger.dump()
    if #log == 0 then print("Nothing to replay yet!") end
    for _, message in ipairs(log) do print(message) end
end
