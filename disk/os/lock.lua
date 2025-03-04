-- Constants for security configuration
local MAX_ATTEMPTS = 3   -- Maximum number of incorrect password attempts allowed
local LOCKOUT_TIME = 30  -- Lockout time in seconds after reaching maximum attempts

local USERS_FOLDER = "/disk/users/"
local ERROR_FOLDER = "/disk/error/"
local BSOD_PROGRAM = "BSOD.lua"
local CURRENT_USER_FILE = ".currentusr"
local SHOW_ALL_USERS_FILE = "/disk/config/security/login/ShowAllUsers.cfg"

-- Utility function to draw a centered popup window with a text-based border
local function drawPopupWindow(headerText, contentLines, windowWidth, windowHeight)
    term.clear()
    local w, h = term.getSize()

    -- Determine dimensions of the popup
    local maxLength = #headerText
    for _, line in ipairs(contentLines) do
        maxLength = math.max(maxLength, #line)
    end
    windowWidth = windowWidth or (maxLength + 4)
    windowHeight = windowHeight or (#contentLines + 4)

    local xStart = math.floor(w / 2 - windowWidth / 2)
    local yStart = math.floor(h / 2 - windowHeight / 2)

    -- Draw border with animation
    term.setCursorPos(xStart, yStart)
    term.write("+" .. string.rep("-", windowWidth - 2) .. "+")
    for i = 1, windowHeight - 2 do
        term.setCursorPos(xStart, yStart + i)
        term.write("|" .. string.rep(" ", windowWidth - 2) .. "|")
        os.sleep(0.05)
    end
    term.setCursorPos(xStart, yStart + windowHeight - 1)
    term.write("+" .. string.rep("-", windowWidth - 2) .. "+")

    -- Draw header
    term.setCursorPos(xStart + 2, yStart + 1)
    term.write(headerText)

    -- Draw content
    for i, line in ipairs(contentLines) do
        term.setCursorPos(xStart + 2, yStart + 1 + i + 1)
        term.write(line)
        os.sleep(0.05)
    end
end

-- Function to list all users
local function listUsers()
    local users = fs.list(USERS_FOLDER)
    local usernames = {}
    for _, user in ipairs(users) do
        local userDir = fs.combine(USERS_FOLDER, user)
        if fs.isDir(userDir) then
            table.insert(usernames, user)
        end
    end
    return usernames
end

-- Function to handle user selection from the list
local function drawUsersScreen(usernames, selectedIndex)
    local contentLines = {}
    for i, username in ipairs(usernames) do
        if i == selectedIndex then
            table.insert(contentLines, "> " .. username)
        else
            table.insert(contentLines, "  " .. username)
        end
    end
    drawPopupWindow("Select your user account:", contentLines, 30, #contentLines + 4)
end

-- Function to select a user from the list interactively
local function selectUserFromList()
    local usernames = listUsers()
    local selectedIndex = 1

    while true do
        drawUsersScreen(usernames, selectedIndex)

        local event, key = os.pullEvent("key")
        if key == keys.up then
            selectedIndex = math.max(1, selectedIndex - 1)
        elseif key == keys.down then
            selectedIndex = math.min(#usernames, selectedIndex + 1)
        elseif key == keys.enter then
            return usernames[selectedIndex]
        end
    end
end

-- Function to get user credentials
local function getUserCredentials(username)
    local passwordFile = fs.combine(USERS_FOLDER .. username, "password.txt")
    if fs.exists(passwordFile) then
        local file = fs.open(passwordFile, "r")
        local storedPassword = file.readLine()
        file.close()
        return storedPassword
    else
        return nil
    end
end

-- Function to save the current user
local function saveCurrentUser(username)
    if fs.exists(CURRENT_USER_FILE) then
        fs.delete(CURRENT_USER_FILE)
    end
    local file = fs.open(CURRENT_USER_FILE, "w")
    file.write(username)
    file.close()
end

-- Function to lock out user
local function lockoutUser(username)
    local disabledFile = fs.combine(USERS_FOLDER .. username, "disabled.txt")
    local file = fs.open(disabledFile, "w")
    file.close()
end

-- Function to check if user is disabled
local function checkDisabled(username)
    local disabledFile = fs.combine(USERS_FOLDER .. username, "disabled.txt")
    return fs.exists(disabledFile)
end

-- Function to handle user login process
local function checkCredentials(username)
    if checkDisabled(username) then
        drawPopupWindow("Doggy OS Account Lockout Service", {"This user account has been disabled."})
        os.sleep(2)
        return false
    end

    local storedPassword = getUserCredentials(username)
    if not storedPassword then
        drawPopupWindow("Doggy OS Login Failure", {"User account doesn't exist or is corrupted."})
        os.sleep(3)
        return false
    end

    local attempts = 0
    repeat
        drawPopupWindow("Login to Doggy OS", {"Username: " .. username, "Attempts left: " .. (MAX_ATTEMPTS - attempts), "", "Enter password:"})
        term.setCursorPos(1, select(2, term.getSize()))
        term.write(":")
        local enteredPassword = read("*")
        attempts = attempts + 1

        if enteredPassword == storedPassword then
            saveCurrentUser(username)
            return true
        else
            drawPopupWindow("Access Denied", {"Incorrect Password"})
            os.sleep(2)
        end
    until attempts >= MAX_ATTEMPTS

    lockoutUser(username)
    drawPopupWindow("Doggy OS Account Lockout Service", {"Too many incorrect attempts."})
    os.sleep(2)
    return false
end

-- Function to check for connected disks and retrieve IDs
local function checkDiskIDs()
    local peripherals = peripheral.getNames()
    local diskIDs = {}

    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "drive" then
            local diskID = disk.getID(name)
            if diskID then
                table.insert(diskIDs, {id = diskID, name = name})
            end
        end
    end

    if #diskIDs > 0 then
        return diskIDs
    else
        return nil
    end
end

-- Function to prompt for security card insertion
local function drawSecurityCardPrompt()
    local contentLines = {
        "Insert a valid security card to login",
        "To login with a password press (ENTER)"
    }
    drawPopupWindow("Doggy OS Security", contentLines)
end

-- Function to display an error message
local function drawErrorMessage(message)
    drawPopupWindow("Doggy OS Login Failure", {message})
end

-- Function to eject a disk
local function ejectDisk(diskName)
    peripheral.call(diskName, "ejectDisk")
end

-- Function to handle security card login
local function insertSecurityCard(username)
    local idFolder = fs.combine(USERS_FOLDER .. username, "ID")
    if not fs.exists(idFolder) then
        return false
    end
    
    while true do
        drawSecurityCardPrompt()
        
        local event, key = os.pullEvent()
        
        if event == "key" and key == keys.enter then
            return false  -- Allow password login if enter is pressed
        elseif event == "disk" or event == "disk_insert" then
            local diskIDs = checkDiskIDs()
            if diskIDs then
                for _, disk in ipairs(diskIDs) do
                    ejectDisk(disk.name)  -- Eject the disk after checking
                    local idFile = fs.combine(idFolder, tostring(disk.id) .. ".file")
                    if fs.exists(idFile) then
                        return true  -- Allow access if a valid security ID is found
                    end
                end
                drawErrorMessage("False Security Card Credintials")
                os.sleep(3)
            end
        end
    end
end

-- Main function for login process
local function main()
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.clear()

    local username

    if fs.exists(SHOW_ALL_USERS_FILE) then
        username = selectUserFromList()
    else
        drawPopupWindow("Protected by Doggy OS Security", {"Enter username:"})
        username = read()
    end

    -- Attempt security card login first
    if insertSecurityCard(username) then
        drawPopupWindow("Access Granted", {"Security card verified. Welcome, " .. username .. "!"})
        os.sleep(2)
        saveCurrentUser(username)
        shell.run("/disk/os/gui")
        return
    end

    -- Fallback to password login if card verification fails or is bypassed
    if checkCredentials(username) then
        drawPopupWindow("Access Granted", {"Welcome, " .. username .. "!"})
        os.sleep(2)
        shell.run("/disk/os/gui")
    else
        shell.run("/disk/os/lock.lua")
    end
end

main()
