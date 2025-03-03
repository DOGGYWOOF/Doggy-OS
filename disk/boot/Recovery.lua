-- Doggy OS Recovery

local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function fullSystemRecovery()
    clearScreen()
    shell.run("delete /disk")
    shell.run("copy /recovery /disk")
    print("Full System Recovery completed.")
    sleep(2)  -- Adding a delay for visibility
end

local function refreshRecoveryPartition()
    clearScreen()
    print("Please insert Doggy OS disk!")

    while not fs.exists("/disk2/") do
        sleep(1)
    end

    shell.run("delete /recovery")
    shell.run("copy /disk2 /recovery")
    print("Recovery partition refreshed.")
    sleep(2)  -- Adding a delay for visibility
end

local function installUpdateFromDisk()
    clearScreen()
    print("Please insert Doggy OS disk!")

    while not fs.exists("/disk2/") do
        sleep(1)
    end

    shell.run("delete /disk")
    shell.run("copy /disk2 /disk")
    print("Update installed from disk.")
    sleep(2)  -- Adding a delay for visibility
end

local function overrideBootloader()
    clearScreen()
    print("Override Bootloader:")
    print("Enter the location of the OS kernel:")
    
    local kernelLocation = io.read()
    
    if fs.exists(kernelLocation) then
        shell.run("delete /startup")
        shell.run("copy " .. kernelLocation .. " /startup")
        print("Bootloader overridden successfully.")
    else
        print("Error: Specified file not found.")
    end

    sleep(2)  -- Adding a delay for visibility
end

-- Main loop
while true do
    clearScreen()
    print("Doggy OS DEV Recovery GUI:")
    print("1. Recovery Options")
    print("2. Power Options")

    local choice = tonumber(io.read())

    if choice == 1 then
        while true do
            clearScreen()
            term.setCursorPos(1, 1)
            print("Recovery Options:")
            print("1. Full System Recovery")
            print("2. Refresh Recovery Partition")
            print("3. Install Update from Disk")
            print("4. Override Bootloader")
            print("5. Back")

            local recoveryChoice = tonumber(io.read())

            if recoveryChoice == 1 then
                fullSystemRecovery()
            elseif recoveryChoice == 2 then
                refreshRecoveryPartition()
            elseif recoveryChoice == 3 then
                installUpdateFromDisk()
            elseif recoveryChoice == 4 then
                overrideBootloader()
            elseif recoveryChoice == 5 then
                break  -- Go back to the main menu
            else
                print("Invalid choice.")
                sleep(2)  -- Adding a delay for visibility
            end
        end
    elseif choice == 2 then
        clearScreen()
        term.setCursorPos(1, 1)
        print("Power Options:")
        print("1. Reboot system")
        print("2. Shutdown system")

        local powerChoice = tonumber(io.read())

        if powerChoice == 1 then
            os.reboot()
        elseif powerChoice == 2 then
            os.shutdown()
        else
            print("Invalid choice.")
            sleep(2)  -- Adding a delay for visibility
        end
    else
        print("Invalid choice. Please try again.")
        sleep(2)  -- Adding a delay for visibility
    end
end
