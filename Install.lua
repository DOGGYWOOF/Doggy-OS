-- Function to create the directory if it doesn't exist
local function create_directory(file_path)
    local dir_path = file_path:match("(.*/)") -- Extract directory path
    if dir_path and not fs.exists(dir_path) then
        fs.makeDir(dir_path)
    end
end

-- List of files to download with URL
local files = {
    -- Files under /disk/os/
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

    -- Files under /disk/security/
    {"/disk/security/Unlock.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/security/Unlock.lua"},
    {"/disk/security/users.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/security/users.lua"},

    -- Files under /disk/acpi/
    {"/disk/ACPI/logoff", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/logoff"},
    {"/disk/ACPI/reboot", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/reboot"},
    {"/disk/ACPI/shutdown", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/shutdown"},
    {"/disk/ACPI/soft-reboot", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/soft-reboot"},
    {"/disk/ACPI/soft-reboot-load", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/ACPI/soft-reboot-load"},

    -- Files under /disk/bootloader/
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

    -- Root DIR
    {"no-os", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/no-os"},
    {"startup", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/startup"},

    -- /disk/.../

    
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
    {"startup", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/boot/error"},
    {"tesr", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/tesr"},

    -- Files under /disk/boot/
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

    -- Files under /disk/users/root
    {"/disk/users/root/admin.txt", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/users/root/admin.txt"},
    {"/disk/users/root/password.txt", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/users/root/password.txt"},
    {"/disk/users/root/user.txt", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/users/root/user.txt"},

    -- Files under /disk/pocket/
    {"/disk/pocket/emergency-firmware-recovery.lua", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/pocket/emergency-firmware-recovery.lua"},
    {"/disk/pocket/start", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/pocket/start"},

    -- Files under /disk/packages/
    {"/disk/packages/package-installer", "https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/v13-Standard/disk/packages/package-installer"},
}

-- Main loop to download files if they don't already exist
for _, file in ipairs(files) do
    local file_path = file[1]
    local file_url = file[2]
    
    create_directory(file_path) -- Ensure parent directory exists
    
    if not fs.exists(file_path) then
        print("Downloading: " .. file_path)
        local handle = http.get(file_url)
        if handle then
            local data = handle.readAll()
            handle.close()
            
            local file_handle = fs.open(file_path, "w")
            file_handle.write(data)
            file_handle.close()
            print("Downloaded: " .. file_path)
        else
            print("Failed to download: " .. file_path)
        end
    else
        print("Skipping: " .. file_path .. " (already exists)")
    end
end

-- Move necessary files to /disk/
local move_files = {"tesr", "startup", "setup", "server", "LST_STARTUP_DONOTDELETE", "INSTALLTEST", "install-old", "install-assist", "install.lua", "DOG_FS", "bk-setup", "bk-install"}
for _, file in ipairs(move_files) do
    if fs.exists(file) then
        fs.move(file, "/disk/" .. file)
    end
end

-- Run /disk/setup at the end
shell.run("/disk/setup")
