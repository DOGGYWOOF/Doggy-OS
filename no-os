-- Helper function to display ASCII art and message
local function displayMessage(message)
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

    -- Define the dog ASCII art with white color and @ for eyes
    local dogArt = {
        "     |\\_/|                  ",
        "     | @ @                  ",
        "     |   <>              _   ",
        "     |  _/\\------____ ((| |))",
        "     |               `--' |  ",
        " _____|_       ___|   |___.  ",
        "/_/_____/____/_______|       "
    }

    local startLine = math.floor((height - #dogArt) / 2) - 2

    -- Display the dog ASCII art with white color
    term.setTextColor(colors.white)
    for i, line in ipairs(dogArt) do
        centerText(startLine + i, line, colors.white)
    end

    -- Display the provided message below the ASCII art
    centerText(startLine + #dogArt + 2, message, colors.white)
end

-- Initial Error Screen Code
local function displayErrorScreen()
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
        "     | X X   SYSTEM ERROR!   ",
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
    centerText(startLine + #dogArt + 2, "Fatal startup failure", colors.white)
    centerText(startLine + #dogArt + 3, "Error code: DOSx1009", colors.white)

    -- Move "Press F1 for advanced options." to the bottom in white
    centerText(height - 2, "Press F1 for advanced options.", colors.white)
end

-- Recovery Menu UI
local function displayRecoveryMenu()
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

    -- Display a menu header
    local header = "System Recovery on boot failure"
    local options = {
        "1. Repair Bootloader",
        "2. Recover from /recovery",
        "3. Recover from external source",
        "4. Run recovery shell",
        "5. Exit"
    }

    local startLine = math.floor((height - #options - 4) / 2)

    -- Display the header
    term.setTextColor(colors.cyan)
    centerText(startLine, header, colors.cyan)
    term.setTextColor(colors.white)
    for i, option in ipairs(options) do
        centerText(startLine + i + 1, option, colors.white)
    end
end

-- Repair Code Function
local function repairBootloader()
    displayMessage("Repairing System Bootloader...")

    -- Wait for 10 seconds to simulate the repair process
    sleep(10)

    -- Delete existing startup and no-os files
    fs.delete("/startup")
    fs.delete("/no-os")

    -- Copy the recovery files to the root directory
    fs.copy("/recovery/boot/error", "/startup")
    fs.copy("/recovery/bootloader/no-os.lua", "/no-os")

    -- Display the "Repair Completed. Rebooting..." message in white
    displayMessage("Repair Completed. Rebooting...")

    -- Wait for 3 seconds before rebooting
    sleep(3)

    -- Reboot the system
    os.reboot()
end

-- Recovery from /recovery Function
local function recoverFromRecovery()
    displayMessage("Repairing File System")

    -- Wait for 10 seconds to simulate the recovery process
    sleep(10)

    -- Delete existing disk directory and copy files from /recovery
    fs.delete("/disk/")
    fs.copy("/recovery/", "/disk/")

    -- Display the "Recovery Completed. Rebooting..." message in white
    displayMessage("Recovery Completed. Rebooting...")

    -- Wait for 3 seconds before rebooting
    sleep(3)

    -- Reboot the system
    os.reboot()
end

-- Recovery from External Source Function
local function recoverFromExternalSource()
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

    -- Define the dog ASCII art with white color and @ for eyes
    local dogArt = {
        "     |\\_/|                  ",
        "     | @ @                  ",
        "     |   <>              _   ",
        "     |  _/\\------____ ((| |))",
        "     |               `--' |  ",
        " _____|_       ___|   |___.  ",
        "/_/_____/____/_______|       "
    }

    local startLine = math.floor((height - #dogArt) / 2) - 2

    -- Display the dog ASCII art with white color
    term.setTextColor(colors.white)
    for i, line in ipairs(dogArt) do
        centerText(startLine + i, line, colors.white)
    end

    -- Display the "Installing System Update from /disk2/" message in white
    centerText(startLine + #dogArt + 2, "Installing System Update from /disk2/", colors.white)

    -- Wait for 10 seconds to simulate the update process
    sleep(10)

    -- Check if /disk2 exists before copying
    if fs.exists("/disk2/") then
        fs.delete("/disk/")
        fs.copy("/disk2/", "/disk/")
        -- Display the "Update Completed. Rebooting..." message in white
        centerText(startLine + #dogArt + 4, "Update Completed. Rebooting...", colors.white)
    else
        -- Display an error message if /disk2 does not exist
        centerText(startLine + #dogArt + 4, "Error: /disk2 does not exist.", colors.red)
    end

    -- Wait for 3 seconds before rebooting
    sleep(3)

    -- Reboot the system
    os.reboot()
end

-- Recovery Shell Function
local function recoveryShell()
    -- Clear the screen and set up colors
    term.clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()

    -- Alternative shell from CraftOS shell
    termutils = {}

    termutils.clear = function()
        term.clear()
        term.setCursorPos(1,1)
    end

    termutils.clearColor = function()
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
    end

    function input()
        term.setTextColor(colors.white)
        local dir = shell.dir().."/"..">"
        write(dir)
        termutils.clearColor()
        command = io.read()
    end

    termutils.clear()
    print("VA11-ILLA EFI Recovery Shell")
    while true do
        input()
        shell.run(command)
    end
end

-- Main Menu Logic
displayErrorScreen()

while true do
    local event, key = os.pullEvent("key")

    if key == keys.f1 then
        displayRecoveryMenu()

        while true do
            event, key = os.pullEvent("key")
            if key == keys.one then
                repairBootloader()
            elseif key == keys.two then
                recoverFromRecovery()
            elseif key == keys.three then
                recoverFromExternalSource()
            elseif key == keys.f4 then
                recoveryShell()
            elseif key == keys.f5 then
                return  -- Exit the menu
            end
        end
    end
end
