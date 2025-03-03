-- Function to trim any trailing slashes from a path
local function trimTrailingSlash(path)
  return path:match("^(.-)/?$") -- Ensure leading slash is maintained
end

-- Function to check if the current directory is within any protected path
local function checkDirectoryAgainstProtectedPaths(protectedPaths)
  -- Get the current working directory from the shell API
  local currentDirectory = trimTrailingSlash(shell.dir())
  
  -- Ensure the current directory has a leading slash
  if not currentDirectory:match("^/") then
    currentDirectory = "/" .. currentDirectory
  end

  -- Display the current directory
  print("You are currently in directory: " .. currentDirectory)

  -- Check if the current directory is within any protected paths
  for _, path in ipairs(protectedPaths) do
    -- Ensure path has a leading slash
    local protectedPath = trimTrailingSlash(path)
    if not protectedPath:match("^/") then
      protectedPath = "/" .. protectedPath
    end
    
    if currentDirectory == protectedPath or currentDirectory:find("^" .. protectedPath, 1, true) then
      return true
    end
  end

  return false
end

termutils = {}

-- Clears the terminal and resets the cursor position
termutils.clear = function()
  term.clear()
  term.setCursorPos(1, 1)
end

-- Resets text and background colors to default
termutils.clearColor = function()
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
end

-- Prompts the user for input and returns the entered value
function input()
  term.setTextColor(colors.blue)
  local dir = shell.dir() .. "/> "
  write(dir)
  termutils.clearColor()
  return io.read()
end

-- Checks if the command involves a protected path or its subdirectories
function isInProtectedPath(command, path)
  -- Ensure both path and command have leading slashes
  if not path:match("^/") then
    path = "/" .. path
  end
  if not command:match("^/") then
    command = "/" .. command
  end

  -- Check if the command starts with the protected path or if the protected path is found in the command
  return command:find(path, 1, true) ~= nil
end

-- Checks if the command involves protected paths or files and handles protection
function checkProtection(command)
  local blockedCommands = { "sh", "shell" }
  local protectedPaths = {
    "/disk/boot/",
    "/disk/os/",
    "/disk/bootloader/",
    "/disk/users/",
    "/recovery/",       -- Directory path
    "/disk/ACPI/",      -- Directory path
    "/disk/error/",     -- Directory path
    "/disk/startup",    -- Directory path
    "/disk/setup",      -- Directory path
    "/disk/install.lua", -- File path
    "/disk/install-assist", -- File path
    "startup",          -- File name
    "no-os",            -- File name
    "dev.cfg"           -- File name
  }

  -- Separate list for protected files and paths
  local protectedFiles = {
    "/disk/setup",
    "/disk/startup",
    "/disk/install.lua",
    "/disk/install-assist",
    "startup",
    "no-os"
  }

  -- Handle specific commands for reboot and shutdown
  if command:lower() == "reboot" then
    executeCommand("/disk/ACPI/reboot")
    return false -- Prevent further command processing
  elseif command:lower() == "shutdown" then
    executeCommand("/disk/ACPI/shutdown")
    return false -- Prevent further command processing
  elseif command:lower():match("^exit$") then
    executeCommand("/disk/os/gui")
    return false -- Prevent further command processing
  elseif command:lower():match("^reboot%s+/s$") then
    executeCommand("/disk/ACPI/soft-reboot")
    return false -- Prevent further command processing
  end

  -- Block specific commands
  for _, blocked in ipairs(blockedCommands) do
    if command:lower() == blocked then
      print("Error: The command '" .. blocked .. "' is not allowed.")
      return false
    end
  end

  -- Check for protected paths/files
  for _, path in ipairs(protectedPaths) do
    if isInProtectedPath(command, path) then
      -- Show the FS protection screen and request admin credentials
      if not requestAdminCredentials("This command may modify critical files. Proceed with caution.") then
        return false
      end
      return true
    end
  end

  -- Check for protected files directly
  for _, file in ipairs(protectedFiles) do
    if command:find(file, 1, true) then
      -- Show the FS protection screen and request admin credentials
      if not requestAdminCredentials("This command involves a protected file. Proceed with caution.") then
        return false
      end
      return true
    end
  end

  -- Check if the current directory is within any protected path
  if checkDirectoryAgainstProtectedPaths(protectedPaths) then
    -- Show the FS protection screen and request admin credentials
    if not requestAdminCredentials("You are in a protected directory. Proceed with caution.") then
      return false
    end
    return true
  end

  return true
end

-- Requests admin credentials from the user
function requestAdminCredentials(warningMessage)
  termutils.clear()
  
  local width, height = term.getSize()
  local boxWidth = 40
  local boxHeight = 12 -- Increased box height for error messages
  local startX = math.floor((width - boxWidth) / 2)
  local startY = math.floor((height - boxHeight) / 2)

  term.setBackgroundColor(colors.gray)
  term.setTextColor(colors.white)

  -- Draw the box
  term.setCursorPos(startX, startY)
  write("+" .. string.rep("-", boxWidth - 2) .. "+")
  
  for y = startY + 1, startY + boxHeight - 1 do
    term.setCursorPos(startX, y)
    write("|" .. string.rep(" ", boxWidth - 2) .. "|")
  end
  
  term.setCursorPos(startX, startY + boxHeight)
  write("+" .. string.rep("-", boxWidth - 2) .. "+")

  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)

  -- Display prompts inside the box
  local contentX = startX + 2
  local contentY = startY + 2
  
  term.setCursorPos(contentX, contentY)
  write("Doggy OS File System Protection")
  
  term.setCursorPos(contentX, contentY + 2)
  write("Enter Administrator login.")
  
  term.setCursorPos(contentX, contentY + 4)
  write("Username: ")
  local username = io.read()
  
  term.setCursorPos(contentX, contentY + 6)
  write("Password: ")
  term.setTextColor(colors.black) -- Change text color to black to hide the input
  local password = io.read()
  term.setTextColor(colors.white) -- Reset text color

  -- Verify credentials and handle access
  local isVerified = verifyPassword(username, password)
  if not isVerified then
    termutils.clear() -- Clear the screen if verification fails
    print("Error: Verification failed.")
    print(warningMessage)
  end
  return isVerified
end

-- Verifies the entered username and password
function verifyPassword(username, password)
  local passwordFilePath = "/disk/users/" .. username .. "/password.txt"
  local file = fs.open(passwordFilePath, "r")
  
  if file then
    local correctPassword = file.readAll()
    file.close()
    
    if password == correctPassword and userIsAdmin(username) then
      return true
    else
      return false
    end
  else
    return false
  end
end

-- Checks if the user has admin privileges
function userIsAdmin(username)
  local adminFilePath = "/disk/users/" .. username .. "/admin.txt"
  local file = fs.open(adminFilePath, "r")
  
  if file then
    file.close()
    return true
  else
    return false
  end
end

-- Executes the command with error handling
function executeCommand(command)
  local success, err = pcall(function() shell.run(command) end)
  if not success then
    print("Error executing command:", err)
  end
end

-- Checks if dev.cfg exists in the root directory
function checkDevConfig()
  local file = fs.open("/dev.cfg", "r")
  if file then
    file.close()
    return true
  else
    return false
  end
end

-- Main execution starts here
termutils.clear()
print("Doggy OS Terminal (13.0)")

while true do
  local command = input()
  
  if checkProtection(command) then
    executeCommand(command)
  else
    print("Command aborted.")
  end
end