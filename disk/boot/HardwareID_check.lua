-- Function to read the hashed ID from the JSON-like config file
local function readHashedID()
    if not fs.exists("HardwareID.cfg") then
        return nil
    end
    
    local file = fs.open("HardwareID.cfg", "r")
    local content = file.readAll()
    file.close()

    -- Extract the HashedID from the JSON-like content
    local hashedID = content:match('"HashedID"%s*:%s*(%d+)')
    return hashedID and tonumber(hashedID)
end

-- Reversible hash function to encode/decode the computer ID
local function generateHash(id)
    return (id * 12345 + 67890) % 1000000
end

-- Function to "unhash" the hashed ID to get the original ID
local function unhashID(hashedID)
    for possibleID = 0, 10000 do  -- Assuming a reasonable range for computer IDs
        if generateHash(possibleID) == hashedID then
            return possibleID
        end
    end
    return nil  -- If no valid ID is found
end

-- Function to display the error screen
local function showErrorScreen()
    -- Clear the screen and set up colors
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    -- Define the width and height of the screen
    local width, height = term.getSize()

    -- Helper function to center text on the screen
    local function centerText(y, text, textColor)
        local x = math.floor((width - #text) / 2)
        term.setCursorPos(x, y)
        term.setTextColor(textColor)
        term.write(text)
    end

    -- Display the dog ASCII art with red Xes for eyes
    local dogArt = {
        "     |\\_/|                  ",
        "     | X X    HARDWARE ERROR!",
        "     |   <>              _   ",
        "     |  _/\\------____ ((| |))",
        "     |               `--' |  ",
        " _____|_       ___|   |___.  ",
        "/_/_____/____/_______|       "
    }

    local startLine = math.floor((height - #dogArt) / 2) - 2

    -- Display the dog ASCII art with red Xes for eyes in red
    term.setTextColor(colors.red)
    for i, line in ipairs(dogArt) do
        centerText(startLine + i, line, colors.red)
    end

    -- Display error message below the dog ASCII art in white
    term.setTextColor(colors.white)
    centerText(startLine + #dogArt + 2, "HARDWARE ID ERROR", colors.white)
    centerText(startLine + #dogArt + 3, "Error: ACCESS DENIED", colors.white)

    -- Move "Please contact support." to the bottom in white
    centerText(height - 2, "Please contact support.", colors.white)

    -- Keep the screen static with the error message
    while true do
        sleep(1)
    end
end

-- Read the hashed ID from the config file
local hashedID = readHashedID()
if not hashedID then
    showErrorScreen()
    return
end

-- Retrieve the real computer ID
local currentID = os.getComputerID()

-- Unhash the hashed ID to get the original ID
local unhashedID = unhashID(hashedID)

-- Check if the real computer ID matches the unhashed ID
if currentID == unhashedID then
    print("Computer ID verified successfully. Access granted.")

    -- Run the /disk/boot/CFW-check.lua script if verification passes
    if fs.exists("/disk/boot/CFW-check.lua") then
        shell.run("/disk/boot/CFW-check.lua")
    else
        print("Error: /disk/boot/CFW-check.lua not found.")
    end
else
    showErrorScreen()
end