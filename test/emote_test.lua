import = require

require "Dandiron.RpFilter.Emote"

local HORIZONTAL_RULE = "--------------------------------------------------------------------------------"

local BLACK = { red = 0, green = 0, blue = 0 }
local WHITE = { red = 255, green = 255, blue = 255 }
local SETTINGS = { sayColor = BLACK, emoteColor = WHITE, isDialogueColored = true }

local COLOR_DIALOGUE_CASES = {
    ["no dialogue"] = {
        { emote = "'",    expected = "'" },
        { emote = '"',    expected = '"' },
        { emote = '""',  expected = '""' },
        { emote = '" "', expected = '" "' },
        { emote = 'Not quoted', expected = 'Not quoted' },
    },
    ["double quotes - simple"] = {
        { emote = '"Hello"', expected = '<rgb=#000000>"Hello"</rgb>' },
        { emote = '" Hello "', expected = '<rgb=#000000>"Hello"</rgb>' },
        { emote = '"Hello',  expected = '<rgb=#000000>"Hello</rgb>' },
        { emote = '"Hello there"', expected = '<rgb=#000000>"Hello there"</rgb>' },
        { emote = '"Hello there', expected = '<rgb=#000000>"Hello there</rgb>' },
        { emote = '"Hello""there"', expected = '<rgb=#000000>"Hello"</rgb><rgb=#000000>"there"</rgb>' },
        { emote = '"Hello","there"', expected = '<rgb=#000000>"Hello"</rgb>,<rgb=#000000>"there"</rgb>' },
        { emote = '"Hello" "there"', expected = '<rgb=#000000>"Hello"</rgb> <rgb=#000000>"there"</rgb>' },
        { emote = '"hello"hello"', expected = '<rgb=#000000>"hello"</rgb>hello"' },
    },
    ["double quotes - complex"] = {
        { emote = 'He said,"Hello?", but', expected = 'He said,<rgb=#000000>"Hello?"</rgb>, but' },
        { emote = 'She said,"Oh hi."', expected = 'She said,<rgb=#000000>"Oh hi."</rgb>' },
        { emote = '"Yes!""No?"', expected = '<rgb=#000000>"Yes!"</rgb><rgb=#000000>"No?"</rgb>' },
        { emote = '"First." "Second."', expected = '<rgb=#000000>"First."</rgb> <rgb=#000000>"Second."</rgb>' },
        { emote = '"Hello!"he shouted.', expected = '<rgb=#000000>"Hello!"</rgb>he shouted.' },
        { emote = '"Wow?"is amazing.', expected = '<rgb=#000000>"Wow?"</rgb>is amazing.' },
        { emote = '"Hi!","Bye?"', expected = '<rgb=#000000>"Hi!"</rgb>,<rgb=#000000>"Bye?"</rgb>' },
        { emote = '"past", "present", "future"', expected = '<rgb=#000000>"past"</rgb>, <rgb=#000000>"present"</rgb>, <rgb=#000000>"future"</rgb>' },
    },
    ["single quotes - simple"] = {
        { emote = "'Hello'", expected = "<rgb=#000000>'Hello'</rgb>" },
        { emote = "'Hello",  expected = "<rgb=#000000>'Hello</rgb>" },
        { emote = "''Ello there'", expected = "<rgb=#000000>''Ello there'</rgb>" },
        { emote = "'Hello there'", expected = "<rgb=#000000>'Hello there'</rgb>" },
        { emote = "'Hello there", expected = "<rgb=#000000>'Hello there</rgb>" },
        { emote = "'Hello','there'", expected = "<rgb=#000000>'Hello'</rgb>,<rgb=#000000>'there'</rgb>" },
        { emote = "'Hello' 'there'", expected = "<rgb=#000000>'Hello'</rgb> <rgb=#000000>'there'</rgb>" },
        -- Differs from double quotes
        { emote = "'hello'hello'", expected = "<rgb=#000000>'hello'hello'</rgb>" },
    },
    ["single quotes - complex"] = {
        { emote = "He said 'Hello?', but", expected = "He said <rgb=#000000>'Hello?'</rgb>, but" },
        { emote = "She said,'Oh hi.'", expected = "She said,<rgb=#000000>'Oh hi.'</rgb>" },
        { emote = "'Yes!' 'No?'", expected = "<rgb=#000000>'Yes!'</rgb> <rgb=#000000>'No?'</rgb>" },
        { emote = "'First.' 'Second.'", expected = "<rgb=#000000>'First.'</rgb> <rgb=#000000>'Second.'</rgb>" },
        { emote = "'Hello!'he shouted.", expected = "<rgb=#000000>'Hello!'</rgb>he shouted." },
        { emote = "'Wow?'is amazing.", expected = "<rgb=#000000>'Wow?'</rgb>is amazing." },
        { emote = "'Hi!','Bye?'", expected = "<rgb=#000000>'Hi!'</rgb>,<rgb=#000000>'Bye?'</rgb>" },
        { emote = "'past', 'present', 'future'", expected = "<rgb=#000000>'past'</rgb>, <rgb=#000000>'present'</rgb>, <rgb=#000000>'future'</rgb>" },
    },
    ["single quotes - edge cases"] = {
        { emote = "'Hello!'he said.", expected = "<rgb=#000000>'Hello!'</rgb>he said." },
        { emote = "'Oops!' 'Ah!'", expected = "<rgb=#000000>'Oops!'</rgb> <rgb=#000000>'Ah!'</rgb>" },
        { emote = "'Oops!!' 'Ah!!'", expected = "<rgb=#000000>'Oops!!'</rgb> <rgb=#000000>'Ah!!'</rgb>" },
        { emote = "'Hello?'she asked.", expected = "<rgb=#000000>'Hello?'</rgb>she asked." },
        { emote = "Before, 'Yes!'after", expected = "Before, <rgb=#000000>'Yes!'</rgb>after" },
        { emote = "Before,'Yes!' after", expected = "Before,<rgb=#000000>'Yes!'</rgb> after" },
        { emote = "'Yes!!','No??'", expected = "<rgb=#000000>'Yes!!'</rgb>,<rgb=#000000>'No??'</rgb>" },
        { emote = "''Tis true,'he said.", expected = "<rgb=#000000>''Tis true,'</rgb>he said." },
        { emote = "They were saying 'pigs ain't goin' to fly, 'tis Lewis' fancy", expected = "They were saying <rgb=#000000>'pigs ain't goin' to fly, 'tis Lewis' fancy</rgb>" },
        { emote = "They were saying 'pigs ain't goin' to fly, 'tis Lewis' fancy'", expected = "They were saying <rgb=#000000>'pigs ain't goin' to fly, 'tis Lewis' fancy'</rgb>" }
    },
    ["ellipsis"] = {
        { emote = "'.'", expected = "'.'" },
        { emote = "'..'", expected = "'..'" },
        { emote = "'...'", expected = "<rgb=#000000>'...'</rgb>" },
        { emote = "'Below...'", expected = "<rgb=#000000>'Below...'</rgb>" },
        { emote = "'Below...?'", expected = "<rgb=#000000>'Below...?'</rgb>" },
        { emote = "'...What did you say?'", expected = "<rgb=#000000>'...What did you say?'</rgb>" },
        { emote = "'Wait...'he muttered.", expected = "<rgb=#000000>'Wait...'</rgb>he muttered." },
        { emote = "'Wait...!'he muttered.", expected = "<rgb=#000000>'Wait...!'</rgb>he muttered." },
        { emote = "'Below--'", expected = "<rgb=#000000>'Below--'</rgb>" },
        { emote = "'--What did you say?'", expected = "<rgb=#000000>'--What did you say?'</rgb>" },
        { emote = "'Wait--'he muttered.", expected = "<rgb=#000000>'Wait--'</rgb>he muttered." },
        { emote = "'Below-'", expected = "<rgb=#000000>'Below-'</rgb>" },
        { emote = "'-What did you say?'", expected = "<rgb=#000000>'-What did you say?'</rgb>" },
        { emote = "'Wait-'he muttered.", expected = "<rgb=#000000>'Wait-'</rgb>he muttered." },
    }
}

local SPECIFIC_CASES = {
    ["contractions"] = {
        { emote = "'Tisn't fair,'he said.", expected = "<rgb=#000000>'Tisn't fair,'</rgb>he said." },
        { emote = "'Tis true.", expected = "<rgb=#000000>'Tis true.</rgb>" },
        { emote = "'Tisn't Lewis' dog", expected = "<rgb=#000000>'Tisn't Lewis' dog</rgb>" },
        { emote = "'But 'tis true.", expected = "<rgb=#000000>'But 'tis true.</rgb>" },
        { emote = "'Tweren't easy,'she admitted.", expected = "<rgb=#000000>'Tweren't easy,'</rgb>she admitted." },
        { emote = "'Bout time!'", expected = "<rgb=#000000>'Bout time!'</rgb>" },
        { emote = "''Neath the bridge,'he whispered.", expected = "<rgb=#000000>''Neath the bridge,'</rgb>he whispered." },
    },
    ["missing spaces after dialogue"] = {
        { emote = "'Tisn't it,'he said.", expected = "<rgb=#000000>'Tisn't it,'</rgb>he said." },
        { emote = "'Bout time!'he shouted.", expected = "<rgb=#000000>'Bout time!'</rgb>he shouted." },
        { emote = "'Ello!'she said.", expected = "<rgb=#000000>'Ello!'</rgb>she said." },
        { emote = "''Round the hill,' he whispered.", expected = "<rgb=#000000>''Round the hill,'</rgb> he whispered." },
        { emote = "'Round little houses'", expected = "<rgb=#000000>'Round little houses'</rgb>" },
    },
    ["adjacent dialogue"] = {
        { emote = "'Tisn't!' 'Indeed!'", expected = "<rgb=#000000>'Tisn't!'</rgb> <rgb=#000000>'Indeed!'</rgb>" },
        { emote = "'Ello!' ''Ouse?'+", expected = "<rgb=#000000>'Ello!'</rgb> <rgb=#000000>''Ouse?'</rgb>+" },
        { emote = "'Tisn't!' 'Indeed?'", expected = "<rgb=#000000>'Tisn't!'</rgb> <rgb=#000000>'Indeed?'</rgb>" },
        { emote = "'Bout!' 'Low?'", expected = "<rgb=#000000>'Bout!'</rgb> <rgb=#000000>'Low?'</rgb>" },
        { emote = "''Ello!!' 'Ouse?'", expected = "<rgb=#000000>''Ello!!'</rgb> <rgb=#000000>'Ouse?'</rgb>" },
    },
}

local function errMsg(funcName, emote, expected, received)
    return string.format(
        "%s with emote=`%s`\nExpected:\t%s\nReceived:\t%s\n",
        funcName, emote, expected, received
    )
end

local function runTestGroup(func, funcName, caseGroup, groupName, settings)
    local numFailed = 0
    for _, case in pairs(caseGroup) do
        local res1 = func(case.emote, "Bob", BLACK)
        local res2 = Emote.formatText("Bob "..case.emote, "Bob", BLACK, settings):gsub("—", "--")
        local expected2 = "Bob "..case.expected

        if res1 ~= case.expected then
            numFailed = numFailed + 1
            if numFailed == 1 then print(HORIZONTAL_RULE) end
            print(errMsg(funcName, case.emote, case.expected, res1))
        elseif res2 ~= expected2 then
            numFailed = numFailed + 1
            if numFailed == 1 then print(HORIZONTAL_RULE) end
            print(errMsg("format()", "Bob "..case.emote, expected2, res2))
        end
    end
    print(string.format("%s: passed %d/%d tests for %s", funcName, #caseGroup - numFailed, #caseGroup, groupName))
    if numFailed > 0 then print(HORIZONTAL_RULE) end
end

local function testFunction(func, funcName, settings, cases)
    for name, group in pairs(cases) do
        runTestGroup(func, funcName, group, name, settings)
    end
end

local function test()
    testFunction(Emote.colorDialogue, "colorDialogue()", SETTINGS, COLOR_DIALOGUE_CASES)
    testFunction(Emote.colorDialogue, "colorDialogue()", SETTINGS, SPECIFIC_CASES)
end

if ... == nil then
    test()
end

return test
