-- Doggy-OS Advanced Setup & Manager
local w, h = term.getSize()

-- Ensure advanced computer (colors) is being used
if not term.isColor() then
    print("This script requires an Advanced Computer.")
    return
end

-- ==========================================
-- UI DRAWING FUNCTIONS
-- ==========================================

local function drawHeader(titleText)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clearLine()
    local title = titleText or " Doggy-OS Setup Utility "
    term.setCursorPos(math.floor((w - #title) / 2) + 1, 1)
    term.write(title)
end

local function drawFooter(text)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(1, h)
    term.clearLine()
    term.setCursorPos(math.floor((w - #text) / 2) + 1, h)
    term.write(text)
end

local function drawProgressBar(current, total, barColor, currentFile)
    local barWidth = w - 8
    local progress = total > 0 and (current / total) or 0
    local filled = math.floor(barWidth * progress)
    
    barColor = barColor or colors.lime

    -- Draw Status Text
    term.setCursorPos(2, h - 3)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lightGray)
    term.clearLine()
    term.setCursorPos(3, h - 3)
    term.write(currentFile and ("Processing: " .. string.sub(currentFile, 1, w - 18)) or "Working...")

    -- Percentage text
    local percentText = math.floor(progress * 100) .. "%"
    term.setTextColor(colors.white)
    term.setCursorPos(w - 2 - #percentText, h - 3)
    term.write(percentText)

    -- Draw Bar Background
    term.setCursorPos(5, h - 2)
    term.setBackgroundColor(colors.gray)
    term.write(string.rep(" ", barWidth))
    
    -- Draw Filled Bar
    term.setCursorPos(5, h - 2)
    term.setBackgroundColor(barColor)
    term.write(string.rep(" ", filled))
end

local function resetTerm()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
end

local function promptReboot()
    local dialogW = math.min(w - 4, 34)
    local dialogH = 7
    local startX = math.floor((w - dialogW) / 2) + 1
    local startY = math.floor((h - dialogH) / 2) + 1

    -- Draw Dialog Box Shadow & Background
    for i = 0, dialogH - 1 do
        term.setCursorPos(startX, startY + i)
        term.setBackgroundColor(colors.cyan)
        term.write(string.rep(" ", dialogW))
    end

    term.setTextColor(colors.white)
    local msg1 = "Process Complete!"
    local msg2 = "Would you like to reboot now?"
    term.setCursorPos(startX + math.floor((dialogW - #msg1)/2), startY + 1)
    term.write(msg1)
    term.setCursorPos(startX + math.floor((dialogW - #msg2)/2), startY + 2)
    term.write(msg2)

    local options = {"Yes", "No"}
    local selected = 1

    while true do
        for i, opt in ipairs(options) do
            local optStr = "  " .. opt .. "  "
            -- Space the buttons evenly
            local offset = (i == 1) and math.floor(dialogW/4 - #optStr/2) or math.floor(dialogW*3/4 - #optStr/2)
            
            term.setCursorPos(startX + offset, startY + 4)
            if i == selected then
                term.setBackgroundColor(colors.blue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.lightGray)
                term.setTextColor(colors.gray)
            end
            term.write(optStr)
        end

        local event, key = os.pullEvent("key")
        if key == keys.left or key == keys.right then
            selected = (selected == 1) and 2 or 1
        elseif key == keys.enter then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.white)
            return options[selected] == "Yes"
        end
    end
end

-- ==========================================
-- FILE DATA
-- ==========================================

local files = {
    {"/disk/os/bk-gui", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/bk-gui"},
    {"/disk/os/bk-home.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/bk-home.lua"},
    {"/disk/os/bk-home2", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/bk-home2"},
    {"/disk/os/browser", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/browser"},
    {"/disk/os/client", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/client"},
    {"/disk/os/command.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/command.lua"},
    {"/disk/os/disabled", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/disabled"},
    {"/disk/os/gui", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/gui"},
    {"/disk/os/home.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/home.lua"},
    {"/disk/os/Lattix", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/Lattix"},
    {"/disk/os/legacy.shutdown", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/legacy.shutdown"},
    {"/disk/os/lock.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/lock.lua"},
    {"/disk/os/programs", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/programs"},
    {"/disk/os/reboot.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/reboot.lua"},
    {"/disk/os/shutdown.exe", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/shutdown.exe"},
    {"/disk/os/sign-out.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/sign-out.lua"},
    {"/disk/os/surface", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/os/surface"},
    {"/disk/security/Unlock.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/security/Unlock.lua"},
    {"/disk/security/users.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/security/users.lua"},
    {"/disk/ACPI/logoff", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/logoff"},
    {"/disk/ACPI/reboot", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/reboot"},
    {"/disk/ACPI/shutdown", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/shutdown"},
    {"/disk/ACPI/soft-reboot", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/soft-reboot"},
    {"/disk/ACPI/soft-reboot-load", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/soft-reboot-load"},
    {"/disk/bootloader/bk-no-os", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/bk-no-os"},
    {"/disk/bootloader/check-bootloader.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/check-bootloader.lua"},
    {"/disk/bootloader/error", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/error"},
    {"/disk/bootloader/no-os.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/no-os.lua"},
    {"/disk/bootloader/recovery", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/recovery"},
    {"/disk/bootloader/recovery-shell.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/recovery-shell.lua"},
    {"/disk/bootloader/repair", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/repair"},
    {"/disk/bootloader/system.config", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/system.config"},
    {"/disk/bootloader/Unlock.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/Unlock.lua"},
    {"/disk/bootloader/VA11-ILLA.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/VA11-ILLA.lua"},
    {"/disk/bootloader/verify-bootloader.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bootloader/verify-bootloader.lua"},
    {"no-os", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/no-os"},
    {"startup", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/error"},
    {"secboot", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/settings"},
    {"bk-install", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bk-install"},
    {"bk-setup", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/bk-setup"},
    {"DOG_FS", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/DOG_FS"},
    {"install.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/install.lua"},
    {"install-assist", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/install-assist"},
    {"install-old", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/install-old"},
    {"INSTALLTEST", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/INSTALLTEST"},
    {"LST_STARTUP_DONOTDELETE", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/LST_STARTUP_DONOTDELETE"},
    {"server", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/server"},
    {"setup", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/setup"},
    {"tesr", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/tesr"},
    {"/disk/boot/anim.old", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/anim.old"},
    {"/disk/boot/BIOS", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/BIOS"},
    {"/disk/boot/bk-BIOS", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/bk-BIOS"},
    {"/disk/boot/bk-error", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/bk-error"},
    {"/disk/boot/bk-startup-check.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/bk-startup-check.lua"},
    {"/disk/boot/boot-animation", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/boot-animation"},
    {"/disk/boot/boot-options", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/boot-options"},
    {"/disk/boot/CFW-check.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/CFW-check.lua"},
    {"/disk/boot/error", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/error"},
    {"/disk/boot/HardwareID_check.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/HardwareID_check.lua"},
    {"/disk/boot/install.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/install.lua"},
    {"/disk/boot/Recovery.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/Recovery.lua"},
    {"/disk/boot/start-check.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/start-check.lua"},
    {"/disk/users/root/admin.txt", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/users/root/admin.txt"},
    {"/disk/users/root/password.txt", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/users/root/password.txt"},
    {"/disk/users/root/user.txt", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/users/root/user.txt"},
    {"/disk/pocket/emergency-firmware-recovery.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/pocket/emergency-firmware-recovery.lua"},
    {"/disk/pocket/start", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/pocket/start"},
    {"/disk/packages/package-installer", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/packages/package-installer"},
}

local move_files = {"tesr", "startup", "setup", "server", "LST_STARTUP_DONOTDELETE", "INSTALLTEST", "install-old", "install-assist", "install.lua", "DOG_FS", "bk-setup", "bk-install"}

-- ==========================================
-- MENU LOGIC
-- ==========================================

local function showMenu()
    local selected = 1
    local options = {}
    local isInstalled = fs.exists("/disk/os") or fs.exists("/disk/setup")
    
    if isInstalled then
        options = { "Reinstall OS", "Uninstall OS", "Exit to Shell" }
    else
        options = { "Install Doggy-OS", "Exit to Shell" }
    end

    while true do
        term.setBackgroundColor(colors.black)
        term.clear()
        drawHeader(" Doggy-OS System Manager ")
        drawFooter("[Up/Down] Navigate   [Enter] Select")
        
        -- Draw main menu container
        local menuH = #options * 2
        local startY = math.floor((h - menuH) / 2)
        
        for i, opt in ipairs(options) do
            local text = opt
            if i == selected then
                term.setBackgroundColor(colors.lightBlue)
                term.setTextColor(colors.white)
                text = " >  " .. text .. "  < "
            else
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.lightGray)
                text = "    " .. text .. "    "
            end
            term.setCursorPos(math.floor((w - #text) / 2) + 1, startY + (i * 2))
            term.write(text)
        end

        local event, key = os.pullEvent("key")
        if key == keys.up then
            selected = selected - 1
            if selected < 1 then selected = #options end
        elseif key == keys.down then
            selected = selected + 1
            if selected > #options then selected = 1 end
        elseif key == keys.enter then
            return options[selected]
        end
    end
end

-- ==========================================
-- CORE ACTIONS
-- ==========================================

local function doUninstall(isReinstall)
    term.setBackgroundColor(colors.black)
    term.clear()
    drawHeader(isReinstall and " Reinstalling Doggy-OS... " or " Uninstalling Doggy-OS... ")
    drawFooter("Please wait, removing system files...")

    -- Create Log Window
    local logWindow = window.create(term.current(), 1, 2, w, h - 6)
    local function logMsg(msg, textColor)
        local oldTerm = term.redirect(logWindow)
        term.setTextColor(textColor or colors.white)
        print(msg)
        term.redirect(oldTerm)
    end

    -- Build a list of every single file/folder to delete
    local to_delete = {}
    for _, file in ipairs(files) do table.insert(to_delete, file[1]) end
    for _, file in ipairs(move_files) do
        table.insert(to_delete, "/" .. file)
        table.insert(to_delete, "/disk/" .. file)
    end

    local directories = {
        "/disk/os", "/disk/security", "/disk/ACPI", 
        "/disk/bootloader", "/disk/boot", "/disk/users", 
        "/disk/pocket", "/disk/packages"
    }
    for _, dir in ipairs(directories) do table.insert(to_delete, dir) end

    local totalItems = #to_delete

    if isReinstall then
        logMsg(" [i] Preparing clean state...", colors.yellow)
    else
        logMsg(" [i] Initializing Uninstaller...", colors.orange)
    end
    os.sleep(0.5)

    -- Live Deletion Process
    for i, path in ipairs(to_delete) do
        drawProgressBar(i, totalItems, colors.red, fs.getName(path))

        if fs.exists(path) then
            fs.delete(path)
            logMsg(" [-] Removed " .. path, colors.red)
            os.sleep(0.01) -- Brief pause for live visual effect
        else
            logMsg(" [=] Skipped " .. path, colors.gray)
        end
    end

    drawProgressBar(totalItems, totalItems, colors.red, "Cleanup Done")
    logMsg("\n [+] Cleanup Complete!", colors.lime)
    os.sleep(1)
end

local function doInstall(isReinstall)
    if not isReinstall then
        term.setBackgroundColor(colors.black)
        term.clear()
        drawHeader(" Installing Doggy-OS... ")
    end
    drawFooter("Please wait, downloading files...")

    -- Create log window
    local logWindow = window.create(term.current(), 1, 2, w, h - 6)
    local function logMsg(msg, textColor)
        local oldTerm = term.redirect(logWindow)
        term.setTextColor(textColor or colors.white)
        print(msg)
        term.redirect(oldTerm)
    end

    local function create_directory(file_path)
        local dir_path = fs.getDir(file_path)
        if dir_path and dir_path ~= ".." and not fs.exists(dir_path) then
            fs.makeDir(dir_path)
        end
    end

    local totalFiles = #files

    for i, file in ipairs(files) do
        local file_path = file[1]
        local file_url = file[2]
        
        drawProgressBar(i, totalFiles, colors.lime, fs.getName(file_path))
        create_directory(file_path) 
        
        if not fs.exists(file_path) then
            local handle = http.get(file_url)
            if handle then
                local data = handle.readAll()
                handle.close()
                
                local file_handle = fs.open(file_path, "w")
                file_handle.write(data)
                file_handle.close()
                logMsg(" [+] " .. file_path, colors.lime)
            else
                logMsg(" [!] Failed: " .. file_path, colors.red)
            end
        else
            logMsg(" [=] Skipped: " .. file_path, colors.gray)
        end
    end

    drawProgressBar(totalFiles, totalFiles, colors.lime, "Organizing...")
    logMsg("\n Organizing files...", colors.cyan)

    for _, file in ipairs(move_files) do
        if fs.exists(file) then
            local dest = "/disk/" .. file
            if fs.exists(dest) then fs.delete(dest) end
            fs.move(file, dest)
            logMsg(" [~] Moved " .. file, colors.yellow)
        end
    end

    -- Depending on install type, behave differently at the end
    if isReinstall then
        logMsg("\n Reinstallation Complete!", colors.lime)
        os.sleep(1)
    else
        logMsg("\n Installation Complete! Booting setup...", colors.lime)
        os.sleep(1.5)
        resetTerm()
        if fs.exists("/disk/setup") then
            shell.run("/disk/setup")
        else
            print("Setup file not found in /disk/setup!")
        end
    end
end

-- ==========================================
-- MAIN EXECUTION LOGIC
-- ==========================================

local choice = showMenu()

if choice == "Exit to Shell" then
    resetTerm()
    return

elseif choice == "Uninstall OS" then
    doUninstall(false)
    if promptReboot() then 
        os.reboot() 
    else 
        resetTerm() 
    end

elseif choice == "Install Doggy-OS" then
    doInstall(false) 
    -- Standard install auto-launches setup, no reboot prompt needed.

elseif choice == "Reinstall OS" then
    doUninstall(true)  -- Live uninstall first
    doInstall(true)    -- Live install directly after
    if promptReboot() then 
        os.reboot() 
    else 
        resetTerm() 
    end
end
