-- Define the key elements to check for in the startup scripts
local requiredElements = {
    "local requiredFiles = {",                -- Definition of the requiredFiles table
    "/disk/bootloader/VA11-ILLA.lua",         -- Specific file path
    "/disk/os/home.lua",                      -- Specific file path
    "/disk/os/lock.lua",                      -- Specific file path
    "/disk/boot/boot-animation",              -- Specific file path
    "/disk/error/BSOD.lua",                   -- Specific file path
    "os.pullEvent = os.pullEventRaw",         -- Overriding os.pullEvent
    "local function checkFiles()",            -- Definition of checkFiles function
    "local missingFiles = {}",                -- Initialization of missingFiles table
    "for _, fileName in ipairs(requiredFiles) do",  -- Loop through requiredFiles
    "if not fs.exists(fileName) then",       -- Check for file existence
    "table.insert(missingFiles, fileName)",  -- Inserting missing files
    "return missingFiles",                   -- Return missing files
    "local function main()",                 -- Definition of main function
    "local missing = checkFiles()",           -- Call checkFiles function
    "if #missing > 0 then",                  -- Check if any files are missing
    "shell.run(\"no-os\")",                  -- Run no-os script
    "else",                                  -- Else branch for file existence
    "shell.run(\"/disk/boot/CFW-check.lua\")", -- Run start-check.lua
    "end",                                    -- End of if-else block
    "main()"                                 -- Call the main function
}

-- Function to read a file's content
local function readFile(path)
    if not fs.exists(path) then
        return nil
    end

    local file = fs.open(path, "r")
    local content = file.readAll()
    file.close()
    return content
end

-- Function to check for the presence of key elements in a script
local function checkForElements(content, elements)
    if not content then
        return false
    end

    for _, element in ipairs(elements) do
        if not string.find(content, element, 1, true) then
            return false
        end
    end

    return true
end

-- Main function to compare the contents of `startup` and `startup.lua`
local function compareStartupFiles()
    local startupContent = readFile("/startup")
    local startupLuaContent = readFile("/startup.lua")

    if checkForElements(startupContent, requiredElements) or checkForElements(startupLuaContent, requiredElements) then
        -- All required elements are present; run the start-check.lua script
        shell.run("/disk/boot/start-check.lua")
    else
        -- Required elements are missing; show fatal error
        print("Error: The startup script does not contain all required elements.")
        showFatalError()
    end
end

-- Function to clear the screen and display a fixed error message
local function showFatalError()
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    local width, height = term.getSize()

    local function centerText(y, text, textColor)
        local x = math.floor((width - #text) / 2)
        term.setCursorPos(x, y)
        term.setTextColor(textColor)
        term.write(text)
    end

    local fatalArt = {
        "     |\\_/|                  ",
        "     | X X  Bootloader Error ",
        "     |   <>              _   ",
        "     |  _/\\------____ ((| |))",
        "     |               `--' |  ",
        " _____|_       ___|   |___.  ",
        "/_/_____/____/_______|       "
    }

    term.setTextColor(colors.red)
    local startLine = math.floor((height - #fatalArt - 4) / 2) -- Adjust start line for ASCII art

    for i, line in ipairs(fatalArt) do
        centerText(startLine + i, line, colors.red)
    end

    term.setTextColor(colors.white)
    centerText(startLine + #fatalArt + 2, "Error:", colors.white) -- Position adjusted
    centerText(startLine + #fatalArt + 3, "CFW Verification Error", colors.white) -- Position adjusted
    centerText(height - 2, "Please contact support.", colors.white) -- Added back at the bottom

    while true do
        sleep(1)
    end
end

-- Run the comparison function with error handling
local success, _ = pcall(compareStartupFiles)
if not success then
    showFatalError()
end
