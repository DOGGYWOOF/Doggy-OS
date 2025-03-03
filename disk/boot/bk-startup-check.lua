-- Clear the screen and set up colors
term.clear()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()

-- Define the width and height of the screen
local width, height = term.getSize()

-- Function to center text on the screen
local function centerText(y, text, textColor)
    local x = math.floor((width - #text) / 2)
    term.setCursorPos(x, y)
    term.setTextColor(textColor)
    term.write(text)
end

-- Display the initial message "Doggy OS Security Error!" at the top in white
centerText(3, "Doggy OS Security Error!", colors.white)

-- Function to show an error message with ASCII art
local function showError(message)
    term.clear()

    -- ASCII art with yellow dog and ? eyes
    local dogArt = {
        "     |\\_/|                  ",
        "     | ? ?                   ",
        "     |   <>              _   ",
        "     |  _/\\------____ ((| |))",
        "     |               `--' |  ",
        " _____|_       ___|   |___.  ",
        "/_/_____/____/_______|       "
    }

    local startLine = math.floor((height - #dogArt) / 2) - 2

    -- Display the dog ASCII art with yellow color and ? eyes
    term.setTextColor(colors.yellow)
    for i, line in ipairs(dogArt) do
        centerText(startLine + i, line, colors.yellow)
    end

    -- Display error message below the dog ASCII art in white
    term.setTextColor(colors.white)
    centerText(startLine + #dogArt + 2, "Error:", colors.white)
    centerText(startLine + #dogArt + 3, message, colors.white)

    -- Move "Please contact support." to the bottom in white
    centerText(height - 2, "Please contact support.", colors.white)

    -- Keep the screen static with the error message
    while true do
        sleep(1)
    end
end

-- Function to check for boot.lock file
local function checkBootLock()
    if fs.exists("/boot.lock") then
        showError("System Disabled")
    end
end

-- Function to check if .settings file exists and contains shell.allow_disk_startup
local function isSecureBootConfigured()
    local settingsPath = "/.settings"
    if fs.exists(settingsPath) then
        local file = fs.open(settingsPath, "r")
        if file then
            local contents = file.readAll()
            file.close()
            -- Check if .settings contains shell.allow_disk_startup
            if not string.find(contents, '["%s-]shell%.allow_disk_startup["%s-]') then
                return false  -- shell.allow_disk_startup not found
            end
        end
    else
        -- .settings file doesn't exist
        return false  -- Secure boot configuration file is missing
    end
    return true  -- Secure boot is properly configured
end

-- Function to check for malicious paths in a file
local function containsMaliciousPaths(filePath)
    if not fs.exists(filePath) then
        return false
    end
    
    local file = fs.open(filePath, "r")
    if not file then
        return false
    end
    
    local contents = file.readAll()
    file.close()
    
    local maliciousPaths = {
        "/disk/os/", "/disk/boot/", "/disk/bootloader/", "/disk/security/", "/disk/users/", "/disk/",
        "disk/os", "disk/boot", "disk/bootloader", "disk/security", "disk/users", "disk"
    }
    
    for _, path in ipairs(maliciousPaths) do
        if string.find(contents, path, 1, true) then
            return true
        end
    end
    
    return false
end

-- Function to check if /disk2/startup or /disk2/startup.lua includes malicious paths
local function checkMaliciousBoot()
    if containsMaliciousPaths("/disk2/startup") then
        showError("Malicious Boot Device: /disk2/startup")
    elseif containsMaliciousPaths("/disk2/startup.lua") then
        showError("Malicious Boot Device: /disk2/startup.lua")
    end
end

-- Function to check if /disk/users directory is empty
local function checkEmptyUsers()
    local usersDir = "/disk/users"
    if fs.exists(usersDir) and fs.isDir(usersDir) then
        local files = fs.list(usersDir)
        if #files == 0 then
            showError("No user data found")
        end
    else
        showError("No user data found")
    end
end

-- Function to check if /disk/boot/BIOS exists
local function checkCriticalBootFiles()
    if not fs.exists("/disk/boot/BIOS") then
        showError("Critical boot files missing")
    end
end

-- Function to check if any user has admin.txt
local function checkAdmin()
    local usersDir = "/disk/users"
    if fs.exists(usersDir) and fs.isDir(usersDir) then
        local users = fs.list(usersDir)
        for _, user in ipairs(users) do
            local adminPath = fs.combine(usersDir, user, "admin.txt")
            if fs.exists(adminPath) then
                return true
            end
        end
    end
    return false
end

-- Function to check if no-os file exists
local function checkFirmware()
    if not fs.exists("/no-os") then
        showError("System Firmware corrupted")
    end
end

-- Main function to initiate checks and continue boot process
local function main()
    checkBootLock()
    if not isSecureBootConfigured() then
        showError("Secure boot config file corrupted")
    end
    checkMaliciousBoot()
    checkEmptyUsers()
    checkCriticalBootFiles()
    if not checkAdmin() then
        showError("No system administrators found")
    end
    checkFirmware()

    -- If no issues found, continue with normal boot process
    shell.run("/disk/boot/BIOS")
    print("No issues detected. Continuing boot process...")
    -- Your normal boot code here
end

-- Start the main function
main()
