-- Constants for security configuration
local MAX_ATTEMPTS = 3
local LOCKOUT_TIME = 30
local OS_VERSION = "Doggy OS v13"

local USERS_FOLDER = "/disk/users/"
local ERROR_FOLDER = "/disk/error/"
local BSOD_PROGRAM = "BSOD.lua"
local CURRENT_USER_FILE = ".currentusr"
local SHOW_ALL_USERS_FILE = "/disk/config/security/login/ShowAllUsers.cfg"
local SECURITY_LOG_FILE = "/disk/security.log"
local DARK_MODE_FILE = "/disk/.darkmode.cfg"

-- Dynamic Theme Configuration
local theme = {}

if fs.exists(DARK_MODE_FILE) then
    -- Dark Mode Theme
    theme = {
        bg              = colors.black,
        text            = colors.lightGray,
        titleBg         = colors.blue,
        titleText       = colors.white,
        btnBg           = colors.gray,
        btnText         = colors.white,
        inputBg         = colors.gray,
        inputText       = colors.white,
        errorText       = colors.red,
        successText     = colors.lime,
        footerBg        = colors.gray,
        rebootBtn       = colors.orange,
        shutdownBtn     = colors.red,
        popupTitleBg    = colors.red,
        popupTitleText  = colors.white,
        popupBg         = colors.gray,
        popupText       = colors.white
    }
else
    -- Light Mode Theme
    theme = {
        bg              = colors.white,
        text            = colors.gray,
        titleBg         = colors.blue,
        titleText       = colors.white,
        btnBg           = colors.lightBlue,
        btnText         = colors.white,
        inputBg         = colors.lightGray,
        inputText       = colors.black,
        errorText       = colors.red,
        successText     = colors.green,
        footerBg        = colors.lightGray,
        rebootBtn       = colors.orange,
        shutdownBtn     = colors.red,
        popupTitleBg    = colors.red,
        popupTitleText  = colors.white,
        popupBg         = colors.lightGray,
        popupText       = colors.black
    }
end

local w, h = term.getSize()

-- Global State Variables
local appState = "INIT" 
local targetUser = ""
local inputBuffer = ""
local isFocused = false
local passwordAttempts = 0
local clickables = {}
local clockTimer = os.startTimer(1)

-- Popup Window State
local errorPopup = {
    active = false,
    msg = "",
    x = 10,
    y = 5,
    w = 26,
    h = 5,
    dragging = false,
    dragOffsetX = 0,
    dragOffsetY = 0
}

-- Utility: Logging
local function logEvent(action)
    local timeStr = textutils.formatTime(os.time(), false)
    local file = fs.open(SECURITY_LOG_FILE, "a")
    if file then
        file.write("[" .. timeStr .. "] " .. action .. "\n")
        file.close()
    end
end

-- Utility: File System & Logic
local function listUsers()
    if not fs.exists(USERS_FOLDER) then return {} end
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

local function getUserCredentials(username)
    local passwordFile = fs.combine(USERS_FOLDER .. username, "password.txt")
    if fs.exists(passwordFile) then
        local file = fs.open(passwordFile, "r")
        local storedPassword = file.readLine()
        file.close()
        return storedPassword
    end
    return nil
end

local function saveCurrentUser(username)
    if fs.exists(CURRENT_USER_FILE) then fs.delete(CURRENT_USER_FILE) end
    local file = fs.open(CURRENT_USER_FILE, "w")
    file.write(username)
    file.close()
end

local function lockoutUser(username)
    local disabledFile = fs.combine(USERS_FOLDER .. username, "disabled.txt")
    local file = fs.open(disabledFile, "w")
    file.close()
    logEvent("LOCKOUT: User '" .. username .. "' exceeded max attempts.")
end

local function checkDisabled(username)
    local disabledFile = fs.combine(USERS_FOLDER .. username, "disabled.txt")
    return fs.exists(disabledFile)
end

local function checkDiskIDs()
    local peripherals = peripheral.getNames()
    local diskIDs = {}
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "drive" then
            local diskID = disk.getID(name)
            if diskID then table.insert(diskIDs, {id = diskID, name = name}) end
        end
    end
    return #diskIDs > 0 and diskIDs or nil
end

local function ejectDisk(diskName)
    peripheral.call(diskName, "ejectDisk")
end

-- GUI Drawing Engine
local function registerClickable(id, x, y, cw, ch)
    table.insert(clickables, {id = id, x = x, y = y, w = cw, h = ch})
end

local function drawText(text, x, y, txtColor, bgColor)
    term.setCursorPos(x, y)
    term.setTextColor(txtColor or theme.text)
    term.setBackgroundColor(bgColor or theme.bg)
    term.write(text)
end

local function drawButton(id, label, x, y, width, bgColor, txtColor)
    term.setCursorPos(x, y)
    term.setBackgroundColor(bgColor or theme.btnBg)
    term.setTextColor(txtColor or theme.btnText)
    
    local padding = math.max(0, math.floor((width - #label) / 2))
    local displayStr = string.rep(" ", padding) .. label
    displayStr = displayStr .. string.rep(" ", width - #displayStr)
    
    term.write(displayStr)
    registerClickable(id, x, y, width, 1)
end

local function drawInputBox(id, x, y, width, isPassword)
    term.setCursorPos(x, y)
    term.setBackgroundColor(theme.inputBg)
    term.setTextColor(theme.inputText)
    
    local display = inputBuffer
    if isPassword then
        display = string.rep("*", #display)
    end
    
    if #display > width - 1 then
        display = string.sub(display, #display - width + 2)
    end
    
    display = display .. string.rep(" ", width - #display)
    term.write(display)
    registerClickable(id, x, y, width, 1)

    if isFocused and not errorPopup.active then
        local cursorX = x + math.min(#inputBuffer, width - 1)
        term.setCursorPos(cursorX, y)
        term.setCursorBlink(true)
    else
        term.setCursorBlink(false)
    end
end

-- Popup Functions
local function triggerError(msg)
    isFocused = false
    errorPopup.msg = msg
    errorPopup.active = true
    errorPopup.w = math.max(20, #msg + 4)
    errorPopup.x = math.floor((w / 2) - (errorPopup.w / 2))
    errorPopup.y = math.floor((h / 2) - (errorPopup.h / 2))
end

local function drawPopup()
    if not errorPopup.active then return end

    -- Draw Title Bar
    term.setCursorPos(errorPopup.x, errorPopup.y)
    term.setBackgroundColor(theme.popupTitleBg)
    term.setTextColor(theme.popupTitleText)
    term.write(" Error" .. string.rep(" ", errorPopup.w - 9) .. "[X]")

    -- Draw Body
    term.setBackgroundColor(theme.popupBg)
    term.setTextColor(theme.popupText)
    for i = 1, errorPopup.h - 1 do
        term.setCursorPos(errorPopup.x, errorPopup.y + i)
        term.write(string.rep(" ", errorPopup.w))
    end
    
    -- Draw Message
    local textX = errorPopup.x + math.floor((errorPopup.w / 2) - (#errorPopup.msg / 2))
    term.setCursorPos(textX, errorPopup.y + 2)
    term.write(errorPopup.msg)
end

-- Standard Header & Footer
local function drawOSFrames()
    -- Top Header
    term.setBackgroundColor(theme.titleBg)
    term.setTextColor(theme.titleText)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, 1)
    term.write("Doggy OS Security")
    
    local timeStr = textutils.formatTime(os.time(), false)
    term.setCursorPos(w - #timeStr, 1)
    term.write(timeStr)

    -- Bottom Footer
    term.setBackgroundColor(theme.footerBg)
    term.setTextColor(theme.titleText)
    term.setCursorPos(1, h)
    term.write(string.rep(" ", w))
    term.setCursorPos(2, h)
    term.write(OS_VERSION)
    
    drawButton("btn_reboot", " Reboot ", w - 21, h, 10, theme.rebootBtn, colors.white)
    drawButton("btn_shutdown", " Shutdown ", w - 10, h, 10, theme.shutdownBtn, colors.white)
end

-- Screen Rendering
local function renderScreen()
    term.setBackgroundColor(theme.bg)
    term.clear()
    clickables = {}

    drawOSFrames()

    -- Content Frame
    term.setBackgroundColor(theme.bg)
    
    if appState == "USER_LIST" then
        drawText("Select an Account", 4, 4, theme.titleBg, theme.titleText)
        local users = listUsers()
        
        if #users == 0 then
            drawText("No accounts found.", 4, 6, theme.errorText)
        else
            for i, user in ipairs(users) do
                local yPos = 6 + (i - 1) * 2
                if yPos < h - 2 then
                    drawButton("user_" .. user, "  " .. user, 4, yPos, 26)
                end
            end
        end

    elseif appState == "MANUAL_USER" then
        drawText("Sign In to Doggy OS", 4, 4, theme.titleBg, theme.titleText)
        drawText("Enter Username:", 4, 7, theme.text)
        drawInputBox("input_user", 4, 8, 24, false)
        drawButton("btn_next", "Next", 4, 10, 10)

    elseif appState == "CARD_CHECK" then
        drawText("Security Authentication", 4, 4, theme.titleBg, theme.titleText)
        drawText("Account: " .. targetUser, 4, 6, theme.text)
        drawText("Please insert your security card.", 4, 8, theme.titleBg, theme.titleText)
        drawButton("btn_use_pass", "Use Password Instead", 4, 11, 24)

    elseif appState == "PASSWORD" then
        drawText("Authentication Required", 4, 4, theme.titleBg, theme.titleText)
        drawText("Account: " .. targetUser, 4, 6, theme.text)
        drawText("Enter Password:", 4, 8, theme.text)
        drawInputBox("input_pass", 4, 9, 24, true)
        drawButton("btn_login", "Login", 4, 11, 10)
        drawButton("btn_back", "Back", 16, 11, 8)
        
        if passwordAttempts > 0 then
            drawText("Attempts left: " .. (MAX_ATTEMPTS - passwordAttempts), 4, 13, theme.errorText)
        end
        
    elseif appState == "SUCCESS" then
        drawText("Welcome, " .. targetUser .. "!", 4, 6, theme.successText)
        drawText("Starting Doggy OS...", 4, 8, theme.text)
        
    elseif appState == "LOCKED" then
        drawText("Security Lockout", 4, 5, theme.errorText)
        drawText("This account has been disabled.", 4, 7, theme.text)
        drawButton("btn_restart", "Return", 4, 10, 10)
    end

    drawPopup()
end

-- Core Logic Handlers
local function handleLoginAttempt()
    if checkDisabled(targetUser) then
        appState = "LOCKED"
        return
    end

    local storedPassword = getUserCredentials(targetUser)
    if not storedPassword then
        triggerError("Account is corrupted.")
        return
    end

    if inputBuffer == storedPassword then
        logEvent("LOGIN SUCCESS: User '" .. targetUser .. "' logged in via password.")
        saveCurrentUser(targetUser)
        appState = "SUCCESS"
    else
        passwordAttempts = passwordAttempts + 1
        logEvent("FAILED LOGIN: User '" .. targetUser .. "' (Attempt " .. passwordAttempts .. "/" .. MAX_ATTEMPTS .. ")")
        inputBuffer = ""
        isFocused = true
        if passwordAttempts >= MAX_ATTEMPTS then
            lockoutUser(targetUser)
            appState = "LOCKED"
        else
            triggerError("Incorrect Password!")
        end
    end
end

local function transitionToCardOrPass()
    inputBuffer = ""
    isFocused = false
    passwordAttempts = 0
    
    if checkDisabled(targetUser) then
        appState = "LOCKED"
        return
    end

    local idFolder = fs.combine(USERS_FOLDER .. targetUser, "ID")
    if fs.exists(idFolder) then
        appState = "CARD_CHECK"
    else
        appState = "PASSWORD"
        isFocused = true
    end
end

-- Main Event Loop
local function runGUI()
    if fs.exists(SHOW_ALL_USERS_FILE) then
        appState = "USER_LIST"
    else
        appState = "MANUAL_USER"
        isFocused = true
    end

    while true do
        renderScreen()

        if appState == "SUCCESS" then
            term.setCursorBlink(false)
            os.sleep(1.5)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            term.clear()
            term.setCursorPos(1,1)
            shell.run("/disk/os/gui")
            return
        end
        
        local event, p1, p2, p3 = os.pullEvent()

        if event == "timer" and p1 == clockTimer then
            clockTimer = os.startTimer(1) -- Refresh screen for the clock
        end

        if event == "mouse_click" then
            local mb, mx, my = p1, p2, p3
            
            -- Intercept clicks for popup window
            if errorPopup.active then
                if mx >= errorPopup.x and mx < errorPopup.x + errorPopup.w and my >= errorPopup.y and my < errorPopup.y + errorPopup.h then
                    if my == errorPopup.y then
                        -- Clicked Title bar
                        if mx >= errorPopup.x + errorPopup.w - 3 then
                            -- Clicked [X]
                            errorPopup.active = false
                            if appState == "MANUAL_USER" or appState == "PASSWORD" then isFocused = true end
                        else
                            -- Start dragging
                            errorPopup.dragging = true
                            errorPopup.dragOffsetX = mx - errorPopup.x
                            errorPopup.dragOffsetY = my - errorPopup.y
                        end
                    end
                end
            else
                -- Normal interaction
                local clickedId = nil
                for _, item in ipairs(clickables) do
                    if mx >= item.x and mx < item.x + item.w and my >= item.y and my < item.y + item.h then
                        clickedId = item.id
                        break
                    end
                end

                isFocused = (clickedId == "input_user" or clickedId == "input_pass")

                if clickedId then
                    if string.sub(clickedId, 1, 5) == "user_" then
                        targetUser = string.sub(clickedId, 6)
                        transitionToCardOrPass()
                    elseif clickedId == "btn_next" and inputBuffer ~= "" then
                        targetUser = inputBuffer
                        transitionToCardOrPass()
                    elseif clickedId == "btn_use_pass" then
                        appState = "PASSWORD"
                        isFocused = true
                    elseif clickedId == "btn_login" then
                        handleLoginAttempt()
                    elseif clickedId == "btn_back" or clickedId == "btn_restart" then
                        targetUser = ""
                        inputBuffer = ""
                        passwordAttempts = 0
                        if fs.exists(SHOW_ALL_USERS_FILE) then
                            appState = "USER_LIST"
                            isFocused = false
                        else
                            appState = "MANUAL_USER"
                            isFocused = true
                        end
                    elseif clickedId == "btn_reboot" then
                        os.reboot()
                    elseif clickedId == "btn_shutdown" then
                        os.shutdown()
                    end
                end
            end

        elseif event == "mouse_drag" then
            if errorPopup.dragging then
                local mx, my = p2, p3
                errorPopup.x = mx - errorPopup.dragOffsetX
                errorPopup.y = my - errorPopup.dragOffsetY
                
                -- Clamp to screen borders
                errorPopup.x = math.max(1, math.min(w - errorPopup.w + 1, errorPopup.x))
                errorPopup.y = math.max(1, math.min(h - errorPopup.h + 1, errorPopup.y))
            end

        elseif event == "mouse_up" then
            errorPopup.dragging = false

        elseif event == "char" then
            if isFocused and not errorPopup.active and appState ~= "LOCKED" then
                inputBuffer = inputBuffer .. p1
            end

        elseif event == "key" then
            if isFocused and not errorPopup.active then
                if p1 == keys.backspace and #inputBuffer > 0 then
                    inputBuffer = string.sub(inputBuffer, 1, -2)
                elseif p1 == keys.enter then
                    if appState == "MANUAL_USER" and inputBuffer ~= "" then
                        targetUser = inputBuffer
                        transitionToCardOrPass()
                    elseif appState == "PASSWORD" then
                        handleLoginAttempt()
                    end
                end
            end

        elseif event == "disk" or event == "disk_insert" then
            if appState == "CARD_CHECK" and not errorPopup.active then
                local diskIDs = checkDiskIDs()
                if diskIDs then
                    local idFolder = fs.combine(USERS_FOLDER .. targetUser, "ID")
                    local verified = false
                    
                    for _, diskInfo in ipairs(diskIDs) do
                        ejectDisk(diskInfo.name)
                        local idFile = fs.combine(idFolder, tostring(diskInfo.id) .. ".file")
                        if fs.exists(idFile) then
                            verified = true
                        end
                    end
                    
                    if verified then
                        logEvent("LOGIN SUCCESS: User '" .. targetUser .. "' via security card.")
                        saveCurrentUser(targetUser)
                        appState = "SUCCESS"
                    else
                        logEvent("FAILED LOGIN: Invalid security card used for '" .. targetUser .. "'.")
                        triggerError("Invalid Security Card.")
                    end
                end
            end
        end
    end
end

-- Initialization
term.clear()
runGUI()
