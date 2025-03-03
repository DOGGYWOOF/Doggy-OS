-- Function to create a new user
function createUser()
    term.clear()
    term.setCursorPos(1, 1)
    print("Enter new username:")
    local username = read()

    -- Check if the username already exists
    if fs.exists("/disk/users/" .. username) then
        print("Username already exists. Try again.")
        sleep(2)
        return
    end

    -- Create a directory for the new user
    fs.makeDir("/disk/users/" .. username)

    -- Prompt for password
    local password
    repeat
        term.clear()
        term.setCursorPos(1, 1)
        print("Enter password:")
        password = read("*")
        
        print("Confirm password:")
        local confirmPassword = read("*")

        if password ~= confirmPassword then
            print("Passwords do not match. Try again.")
            sleep(2)
        end
    until password == confirmPassword

    -- Store the password in a text file
    local file = fs.open("/disk/users/" .. username .. "/password.txt", "w")
    file.write(password)
    file.close()

    print("User created successfully.")
    sleep(2)
end

-- Function to delete a user
function deleteUser()
    term.clear()
    term.setCursorPos(1, 1)
    print("Enter username to delete:")
    local username = read()

    -- Check if the username exists
    if not fs.exists("/disk/users/" .. username) then
        print("User not found. Try again.")
        sleep(2)
        return
    end

    -- Check for the presence of block.txt
    if fs.exists("/disk/users/" .. username .. "/block.txt") then
        -- Display content of block.txt as an error message
        local file = fs.open("/disk/users/" .. username .. "/block.txt", "r")
        local errorMessage = file.readAll()
        file.close()
        print(errorMessage)
        sleep(2)
        return
    end

    -- Prompt for password to confirm deletion
    print("Enter password to confirm deletion:")
    local inputPassword = read("*")
    
    -- Read stored password from the file
    local file = fs.open("/disk/users/" .. username .. "/password.txt", "r")
    local storedPassword = file.readAll()
    file.close()

    -- Compare entered password with stored password
    if inputPassword == storedPassword then
        -- Delete the user directory
        fs.delete("/disk/users/" .. username)
        print("User deleted successfully.")
    else
        print("Incorrect password. Deletion failed.")
    end

    sleep(2)
end

-- Function to view all users
function viewAllUsers()
    term.clear()
    term.setCursorPos(1, 1)
    print("All Users:")
    local users = fs.list("/disk/users")
    for _, user in ipairs(users) do
        if user ~= "root" then
            print(user)
        end
    end
    print("Press any key to continue...")
    read()
end

-- Function for password recovery by admin
function passwordRecovery()
    term.clear()
    term.setCursorPos(1, 1)
    print("Enter admin username:")
    local adminUsername = read()
    
    -- Check if the entered user has admin privileges
    if not fs.exists("/disk/users/" .. adminUsername .. "/admin.txt") then
        print("Permission denied. Admin access required.")
        sleep(2)
        return
    end

    -- Prompt for admin password
    print("Enter admin password:")
    local adminPassword = read("*")

    -- Read stored admin password from the file
    local adminFile = fs.open("/disk/users/" .. adminUsername .. "/password.txt", "r")
    local storedAdminPassword = adminFile.readAll()
    adminFile.close()

    -- Compare entered admin password with stored admin password
    if adminPassword == storedAdminPassword then
        print("Enter username for password reset:")
        local username = read()

        -- Check if the username exists
        if not fs.exists("/disk/users/" .. username) then
            print("User not found. Try again.")
            sleep(2)
            return
        end

        -- Confirm password reset
        print("Are you sure you want to reset the password for " .. username .. "? (y/n)")
        local confirm = read()
        if confirm:lower() ~= "y" then
            print("Password reset canceled.")
            sleep(2)
            return
        end

        -- Prompt for new password
        term.clear()
        term.setCursorPos(1, 1)
        print("Enter new password for " .. username .. ":")
        local newPassword = read("*")

        -- Store the new password in the text file
        local file = fs.open("/disk/users/" .. username .. "/password.txt", "w")
        file.write(newPassword)
        file.close()

        print("Password reset successfully.")
    else
        print("Incorrect admin password. Password reset failed.")
    end

    sleep(2)
end

-- Function to exit and run /disk/os/gui
function exitProgram()
    term.clear()
    term.setCursorPos(1, 1)
    print("Exiting program...")
    sleep(1)
    shell.run("/disk/os/gui")
    error("Exiting program.")
end

-- Function for Security Card Login (insert or enter ID)
function securityCardLogin(username)
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("Security Card Manager")
        print("1. Add Card")
        print("2. Remove Cards")
        print("3. Show All Security Cards")
        print("4. Disable Security Card Login")
        print("5. Back to Main Menu")

        local choice = read()

        if choice == "1" then
            addCardMenu(username)
        elseif choice == "2" then
            removeCardsMenu(username)
        elseif choice == "3" then
            showAllSecurityCards(username)
        elseif choice == "4" then
            disableSecurityCardLogin(username)
        elseif choice == "5" then
            return  -- Back to main menu
        else
            print("Invalid choice. Try again.")
            sleep(2)
        end
    end
end

-- Function for Add Card submenu
function addCardMenu(username)
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("Add Card")
        print("1. Insert Security Card")
        print("2. Enter Security Card ID")
        print("3. Back to Security Card Manager")

        local choice = read()

        if choice == "1" then
            grabAndSaveDiskID(username)
        elseif choice == "2" then
            saveDiskID(username)
        elseif choice == "3" then
            return  -- Back to Security Card Manager
        else
            print("Invalid choice. Try again.")
            sleep(2)
        end
    end
end

-- Function for Remove Cards submenu
function removeCardsMenu(username)
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        print("Remove Cards")
        print("1. Insert Security Card to delete")
        print("2. Enter Security Card ID to delete")
        print("3. Back to Security Card Manager")

        local choice = read()

        if choice == "1" then
            grabAndDeleteDiskID(username)
        elseif choice == "2" then
            deleteSpecificCard(username)
        elseif choice == "3" then
            return  -- Back to Security Card Manager
        else
            print("Invalid choice. Try again.")
            sleep(2)
        end
    end
end

-- Function to delete a specific security card by ID
function deleteSpecificCard(username)
    term.clear()
    term.setCursorPos(1, 1)
    print("Enter Card ID to delete:")
    local cardID = read()

    local filePath = "/disk/users/" .. username .. "/ID/" .. cardID .. ".file"

    if fs.exists(filePath) then
        fs.delete(filePath)
        print("Security Card deleted successfully.")
    else
        print("Security Card not found.")
    end

    sleep(2)
end

-- Function to grab disk ID and delete it for a user
function grabAndDeleteDiskID(username)
    term.clear()
    term.setCursorPos(1, 1)
    print("Insert Security Card to delete ID...")

    while true do
        local peripherals = peripheral.getNames()

        for _, name in ipairs(peripherals) do
            if peripheral.getType(name) == "drive" then
                local diskID = disk.getID(name)
                if diskID then
                    local filePath = "/disk/users/" .. username .. "/ID/" .. diskID .. ".file"

                    if fs.exists(filePath) then
                        fs.delete(filePath)
                        print("Security Card ID deleted successfully.")
                    else
                        print("Security Card ID not found.")
                    end

                    return  -- Exit function after deleting ID
                end
            end
        end

        sleep(1)  -- Check every second
    end
end

-- Function to save disk ID for a user
function saveDiskID(username)
    term.clear()
    term.setCursorPos(1, 1)
    print("Enter Card ID:")
    local cardID = read()

    -- Create directory if it doesn't exist
    local idDir = "/disk/users/" .. username .. "/ID"
    if not fs.exists(idDir) then
        fs.makeDir(idDir)
    end

    -- Save disk ID as a file
    local filePath = idDir .. "/" .. cardID .. ".file"
    local file = fs.open(filePath, "w")
    file.writeLine("Disk ID: " .. cardID)
    file.close()

    print("Disk ID saved successfully.")
    sleep(2)
end

-- Function to grab disk ID and save it for a user
function grabAndSaveDiskID(username)
    term.clear()
    term.setCursorPos(1, 1)
    print("Insert Security Card to grab ID...")

    while true do
        local peripherals = peripheral.getNames()

        for _, name in ipairs(peripherals) do
            if peripheral.getType(name) == "drive" then
                local diskID = disk.getID(name)
                if diskID then
                    -- Create directory if it doesn't exist
                    local idDir = "/disk/users/" .. username .. "/ID"
                    if not fs.exists(idDir) then
                        fs.makeDir(idDir)
                    end

                    -- Save disk ID as a file
                    local filePath = idDir .. "/" .. diskID .. ".file"
                    local file = fs.open(filePath, "w")
                    file.writeLine("Disk ID: " .. diskID)
                    file.close()

                    print("Disk ID grabbed and saved successfully.")
                    return  -- Exit function after saving
                end
            end
        end

        sleep(1)  -- Check every second
    end
end

-- Function to disable Security Card Login (delete all IDs)
function disableSecurityCardLogin(username)
    term.clear()
    term.setCursorPos(1, 1)
    print("Are you sure you want to disable Security Card Login? (y/n)")
    local confirm = read()
    if confirm:lower() == "y" then
        local idDir = "/disk/users/" .. username .. "/ID"
        if fs.exists(idDir) then
            fs.delete(idDir)
            print("Security Card Login disabled successfully.")
        else
            print("No security cards found to delete.")
        end
    else
        print("Operation canceled.")
    end

    sleep(2)
end

-- Function to show all security cards for a user
function showAllSecurityCards(username)
    term.clear()
    term.setCursorPos(1, 1)
    print("Security Cards for User: " .. username)

    local idDir = "/disk/users/" .. username .. "/ID"
    if fs.exists(idDir) then
        local files = fs.list(idDir)
        for _, file in ipairs(files) do
            if fs.isDir(idDir .. "/" .. file) == false then
                print(file)
            end
        end
    else
        print("No security cards found.")
    end

    print("Press any key to continue...")
    read()
end

-- Main program
while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("1. Create User")
    print("2. Delete User")
    print("3. View All Users")
    print("4. Password Recovery (Admin Only)")
    print("5. Security Card Login")
    print("6. Exit")

    local choice = read()

    if choice == "1" then
        createUser()
    elseif choice == "2" then
        deleteUser()
    elseif choice == "3" then
        viewAllUsers()
    elseif choice == "4" then
        passwordRecovery()
    elseif choice == "5" then
        print("Enter username:")
        local username = read()
        -- Validate username
        if fs.exists("/disk/users/" .. username) then
            print("Enter password:")
            local password = read("*")
            -- Verify password before proceeding to security card login
            local file = fs.open("/disk/users/" .. username .. "/password.txt", "r")
            local storedPassword = file.readAll()
            file.close()
            if password == storedPassword then
                securityCardLogin(username)
            else
                print("Incorrect password.")
                sleep(2)
            end
        else
            print("User not found.")
            sleep(2)
        end
    elseif choice == "6" then
        exitProgram()
    else
        print("Invalid choice. Try again.")
        sleep(2)
    end
end