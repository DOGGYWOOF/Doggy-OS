-- Pre-existing imports/libraries assumed: fs, shell, term, os, io, colors, textutils

-- Function to trim any trailing slashes from a path
local function trimTrailingSlash(path)
  -- Ensure leading slash is maintained, and remove trailing slash if present
  -- This handles cases like "/path/" becoming "/path" and "/" remaining "/"
  if path == "/" then
    return "/"
  end
  return path:match("^(.-)/?$")
end

-- Function to check if the current directory is within any protected path
local function checkDirectoryAgainstProtectedPaths(protectedPaths)
  -- Get the current working directory from the shell API
  local currentDirectory = trimTrailingSlash(shell.dir())
  
  -- Ensure the current directory has a leading slash if it's not the root
  if not currentDirectory:match("^/") then
    currentDirectory = "/" .. currentDirectory
  end

  -- Check if the current directory is within any protected paths
  for _, path in ipairs(protectedPaths) do
    -- Ensure path has a leading slash and no trailing slash for consistent comparison
    local protectedPath = trimTrailingSlash(path)
    if not protectedPath:match("^/") then
      protectedPath = "/" .. protectedPath
    end
    
    -- Check if the current directory is exactly the protected path or a subdirectory
    -- The `.. "/"` part ensures that "/disk/boot" doesn't match "/disk/bootloader"
    if currentDirectory == protectedPath or currentDirectory:find("^" .. protectedPath .. "/", 1, true) then
      return true
    end
  end

  return false
end

termutils = {}

-- NEW: Variable to hold the system hostname
local systemHostname = "localhost"

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
  
  -- Display Hostname:
  term.setTextColor(colors.blue) -- Changed from yellow to BLUE for the hostname
  io.write(systemHostname)
  io.write(":")

  -- Display Path:
  term.setTextColor(colors.lightBlue) -- Changed from lime to LIGHT BLUE for the path
  io.write(shell.dir()) -- Print current directory

  -- Use blue for the prompt symbol
  term.setTextColor(colors.blue) -- Changed from white to BLUE for the prompt symbol
  io.write(" $ ") -- Linux-style prompt symbol

  -- Reset color for the user's input text
  termutils.clearColor()
  
  -- Read the command
  return io.read()
end

-- Global variable for the security log file path
local SECURITY_LOG_FILE = "/disk/logs/security.log"
-- Global variable for the authentication configuration file path
local AUTH_CONFIG_FILE = "/disk/config/auth_settings.cfg"
-- Global variable for the current user file path
local CURRENT_USER_FILE = "/disk/users/.currentusr"
-- NEW: Global variable for the system hostname file path
local HOSTNAME_FILE = "/.firmware/hostname.cfg"


-- NEW: Function to read or set the system hostname
local function getHostname()
  local hostname = "localhost" -- Default hostname

  -- 1. Try to read from the file
  if fs.exists(HOSTNAME_FILE) then
    local file = fs.open(HOSTNAME_FILE, "r")
    if file then
      hostname = file.readAll()
      file.close()
      -- Trim whitespace and ensure it's not empty after trimming
      local trimmed = hostname:match("^%s*(.-)%s*$")
      return trimmed ~= "" and trimmed or "localhost"
    end
  end

  -- 2. If file not found or read failed, prompt user and save
  termutils.clear()
  term.setTextColor(colors.white)
  print("--- Doggy OS Setup: Hostname Configuration ---")
  print("It seems this is the first boot, or the hostname configuration is missing.")
  print("Please enter a hostname for this computer (e.g., 'DoggyServer' or 'Base-PC').")
  print("This name will appear in your command prompt.")
  print("")
  
  io.write("New Hostname: ")
  term.setTextColor(colors.lime)
  local newHostname = io.read()
  termutils.clearColor()

  local trimmedHostname = newHostname and newHostname:match("^%s*(.-)%s*$") or ""

  if trimmedHostname ~= "" then
    hostname = trimmedHostname
    
    -- Save the new hostname
    local configDir = fs.getDir(HOSTNAME_FILE)
    if not fs.exists(configDir) then
      -- Create the /.firmware directory if it doesn't exist
      fs.makeDir(configDir)
    end

    local file, err = fs.open(HOSTNAME_FILE, "w")
    if file then
      file.write(hostname)
      file.close()
      print("")
      print("Hostname saved as: " .. hostname)
      os.sleep(1) -- Pause briefly
    else
      term.setTextColor(colors.red)
      print("")
      print("[Warning]: Failed to save hostname to " .. HOSTNAME_FILE .. ": " .. tostring(err))
      termutils.clearColor()
      os.sleep(2)
    end
  else
    term.setTextColor(colors.orange)
    print("")
    print("[Warning]: Invalid hostname entered. Using default 'localhost'.")
    termutils.clearColor()
    os.sleep(2)
  end

  termutils.clear() -- Clear screen after setup prompt
  return hostname
end


-- Function to log security events
-- eventType: A string describing the type of event (e.g., "BLOCKED_COMMAND", "ADMIN_AUTH_FAIL")
-- details: A string with additional details about the event
function logSecurityEvent(eventType, details)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local logEntry = string.format("[%s] [%s] %s\n", timestamp, eventType, details)

  -- Ensure the log directory exists
  local logDir = fs.getDir(SECURITY_LOG_FILE)
  if not fs.exists(logDir) then
    fs.makeDir(logDir)
  end

  local file = fs.open(SECURITY_LOG_FILE, "a") -- Open in append mode
  if file then
    file.write(logEntry)
    file.close()
  else
    -- Fallback: print to console if logging to file fails
    print("WARNING: Could not write to security log file: " .. logEntry)
  end
end

-- Displays an error message with a clear red, Linux-like prefix
function displayErrorMessage(message)
  term.setTextColor(colors.red) -- Set color to red for errors
  print("[Error]: " .. message)
  termutils.clearColor() -- Reset colors
end

-- Reads the authentication configuration from AUTH_CONFIG_FILE
-- Returns a table with settings, or default settings if file doesn't exist or is invalid.
function readAuthConfig()
  local settings = {
    autoGetUser = false -- Default: do not automatically get username
  }
  if fs.exists(AUTH_CONFIG_FILE) then
    local file, err = fs.open(AUTH_CONFIG_FILE, "r")
    if file then
      local content = file.readAll()
      file.close()
      local success, loadedSettings = pcall(function() return textutils.unserialize(content) end)
      if success and type(loadedSettings) == "table" then
        if type(loadedSettings.autoGetUser) == "boolean" then
          settings.autoGetUser = loadedSettings.autoGetUser
        end
      else
        logSecurityEvent("CONFIG_ERROR", "Failed to deserialize auth config or invalid format: " .. (err or "N/A"))
      end
    else
      logSecurityEvent("FILE_READ_ERROR", "Could not open auth config file for reading: " .. AUTH_CONFIG_FILE .. " - " .. tostring(err))
    end
  end
  return settings
end

-- Writes the authentication configuration to AUTH_CONFIG_FILE
function writeAuthConfig(settings)
  local configDir = fs.getDir(AUTH_CONFIG_FILE)
  if not fs.exists(configDir) then
    fs.makeDir(configDir)
  end

  local file, err = fs.open(AUTH_CONFIG_FILE, "w") -- Open in write mode (overwrites)
  if file then
    file.write(textutils.serialize(settings))
    file.close()
    logSecurityEvent("CONFIG_UPDATE", "Auth settings updated: autoGetUser = " .. tostring(settings.autoGetUser))
  else
    logSecurityEvent("FILE_WRITE_ERROR", "Could not write to auth config file: " .. AUTH_CONFIG_FILE .. " - " .. tostring(err))
    displayErrorMessage("Failed to save authentication settings.")
  end
end

-- NEW: Function to check for network access APIs (rednet or http) in a given file
-- Returns true if network APIs are found, false otherwise.
function checkNetworkAccess(filePath)
  local file = fs.open(filePath, "r")
  if file then
    local content = file.readAll()
    file.close()
    -- Check for "rednet" or "http" (case-insensitive for robustness)
    if content:lower():find("rednet", 1, true) or content:lower():find("http", 1, true) then
      return true
    end
  end
  return false
end

-- Checks if the command involves a specific path or its subdirectories or a specific file.
-- This function is used for both admin-protected and absolutely blocked items.
-- It attempts to match the protected item against various parts of the command.
function isInPath(command, protectedItem)
  -- Normalize the protected item to ensure a leading slash for consistency
  -- unless it's a bare file name (e.g., "startup")
  local normalizedProtectedItem = protectedItem
  if protectedItem:match("^/") then
    normalizedProtectedItem = trimTrailingSlash(protectedItem)
  else
    -- For bare file names, we don't add a leading slash here,
    -- as we'll compare against command parts directly.
  end

  -- Split the command into individual parts (command name and arguments)
  local commandParts = {}
  for part in command:gmatch("%S+") do -- Split by any whitespace
    table.insert(commandParts, part)
  end

  -- Iterate through each part of the command to check for matches
  for _, part in ipairs(commandParts) do
    local normalizedPart = part
    -- Normalize the command part if it looks like a path
    if part:match("^/") then
      normalizedPart = trimTrailingSlash(part)
    end

    -- Case 1: Exact match of the command part with the protected item (normalized)
    -- This handles cases like "edit /firmware" or "startup"
    if normalizedPart == normalizedProtectedItem then
      return true
    end

    -- Case 2: The command part is a path that starts with the protected item (normalized)
    -- This handles directories and files within them (e.g., "edit /firmware/foo.lua")
    -- We append a '/' to the protected item to ensure it matches a directory boundary,
    -- preventing partial matches like "/firmware" matching "/firmware_backup".
    if normalizedPart:find("^" .. normalizedProtectedItem .. "/", 1, true) then
      return true
    end

    -- Case 3: The protected item is a bare file name (e.g., "startup"), and the command part is that bare file name
    -- This handles cases like "startup" or "run startup" where the file name is not a full path.
    if protectedItem == part then
      return true
    end
  end

  return false
end


-- Checks if the command involves protected paths or files and handles protection
function checkProtection(command)
  local blockedCommands = { "sh", "shell", "lua" }
  
  -- NEW: Absolutely blocked items (paths and files) - no modification allowed, no admin prompt
  -- These items are completely off-limits.
  local absoluteBlockedItems = {
    "/firmware/",       -- Entire firmware directory and its contents
    ".firmware",         -- Specific firmware file (e.g., for direct execution)
    "startup",           -- The bare file name "startup"
    "no-os",             -- The bare file name "no-os"
    ".currentusr"        -- The current user file
  }

  -- Admin-protected items (paths and files) - require admin credentials to proceed
  -- These items can be modified if admin credentials are provided.
  local protectedItems = {
    "/disk/",             -- All files and subdirectories within /disk/
    "/disk/boot/",
    "/disk/os/",
    "/disk/bootloader/",
    "/disk/users/",
    "/recovery/",
    "/disk/ACPI/",
    "/disk/error/",
    "/disk/startup",    -- Directory path (e.g., for startup scripts)
    "/disk/setup",      -- Directory path (e.g., for setup scripts)
    "/disk/install.lua", -- Specific file path
    "/disk/install-assist", -- Specific file path
    "pastebin",   -- Network command
    "network",    -- Network command
    "wget"        -- Network command
  }

  -- Handle specific commands for reboot and shutdown that bypass general protection
  if command:lower() == "reboot" then
    executeCommand("/disk/ACPI/reboot")
    return false -- Prevent further command processing
  elseif command:lower() == "shutdown" then
    executeCommand("/disk/ACPI/shutdown")
    return false -- Prevent further command processing
  elseif command:lower():match("^exit$") then
    executeCommand("/disk/os/gui") -- Assuming this is the GUI entry point
    return false -- Prevent further command processing
  elseif command:lower():match("^reboot%s+/s$") then
    executeCommand("/disk/ACPI/soft-reboot")
    return false -- Prevent further command processing
  end

  -- Handle 'auth admingetuser' command
  local authGetUserMatch = command:lower():match("^auth%s+admingetuser%s+(true|false)$")
  if authGetUserMatch then
    local enableAutoGetUser = (authGetUserMatch == "true")
    local reason = "Attempting to change 'auto get username' setting to " .. tostring(enableAutoGetUser) .. ". This requires administrator privileges."
    
    -- Request admin credentials to change this setting
    if not requestAdminCredentials(reason, command) then
      logSecurityEvent("AUTH_SETTING_CHANGE_DENIED", "Attempt to change autoGetUser setting denied: " .. command)
      return false -- Prevent setting change if credentials fail
    end

    -- If credentials pass, update the setting
    local currentSettings = readAuthConfig()
    currentSettings.autoGetUser = enableAutoGetUser
    writeAuthConfig(currentSettings)
    print("Auto-get username setting updated to: " .. tostring(enableAutoGetUser))
    logSecurityEvent("AUTH_SETTING_CHANGE_SUCCESS", "Auto-get username setting changed to " .. tostring(enableAutoGetUser) .. " by admin.")
    return false -- Prevent this command from being executed by shell.run
  end

  -- Block specific commands that are never allowed
  for _, blocked in ipairs(blockedCommands) do
    if command:lower() == blocked then
      displayErrorMessage("The command '" .. blocked .. "' is not allowed.")
      logSecurityEvent("BLOCKED_COMMAND", "Attempted to execute blocked command: " .. command)
      return false
    end
  end

  -- Check for absolutely blocked items first. If found, block immediately.
  for _, item in ipairs(absoluteBlockedItems) do
    if isInPath(command, item) then
      displayErrorMessage("This command involves a critical system file and cannot be executed.")
      logSecurityEvent("CRITICAL_FILE_ACCESS_DENIED", "Attempted to access critical file/path: " .. command .. " (Item: " .. item .. ")")
      return false
    end
  end

  -- NEW: Check for network access in executable files
  local commandPath = command:match("^%S+") -- Get the first word of the command
  
  -- FIX: Only attempt to resolve path and check network if a command was actually entered.
  if commandPath then
    -- Resolve the path to handle relative paths (e.g., 'script.lua' vs '/path/to/script.lua')
    local resolvedCommandPath = shell.resolve(commandPath) or commandPath

    if fs.exists(resolvedCommandPath) and not fs.isDir(resolvedCommandPath) then
      if checkNetworkAccess(resolvedCommandPath) then
        termutils.clear() -- Clear screen for the warning
        print("Warning: The file '" .. resolvedCommandPath .. "' appears to have network access (rednet/http APIs).")
        print("It could potentially download malicious content or send data over the network.")
        print("Press any key to proceed with execution, or Ctrl+T to abort.")
        os.pullEvent("key") -- Wait for user acknowledgment
        termutils.clear() -- Clear screen after acknowledgment
        logSecurityEvent("NETWORK_ACCESS_WARNING", "File '" .. resolvedCommandPath .. "' detected with network access APIs. Command: " .. command)
      end
    end
  end

  -- Handle 'cd' command specifically for protected directories
  local cdMatch = command:lower():match("^cd%s*(.*)$")
  if cdMatch then
    local targetPath = cdMatch
    if targetPath == "" then -- `cd` without arguments, typically goes to home, which is fine.
      return true
    end

    -- Attempt to resolve the target path to an absolute path.
    local resolvedTargetPath = shell.resolve(targetPath) or targetPath 

    -- Normalize the resolved path for consistent comparison
    resolvedTargetPath = trimTrailingSlash(resolvedTargetPath)
    if not resolvedTargetPath:match("^/") then
      resolvedTargetPath = "/" .. resolvedTargetPath
    end

    for _, item in ipairs(protectedItems) do
      local normalizedItem = trimTrailingSlash(item)
      if not normalizedItem:match("^/") then
        normalizedItem = "/" .. normalizedItem
      end

      if resolvedTargetPath == normalizedItem or resolvedTargetPath:find("^" .. normalizedItem .. "/", 1, true) then
        local reason = "**Protected Directory Access:** Attempting to change directory into " .. targetPath .. ". This area contains sensitive system files. Proceed with caution."
        if not requestAdminCredentials(reason, command) then -- Pass command for logging
          logSecurityEvent("CD_BLOCKED_ADMIN_REQUIRED", "CD attempt to protected directory denied: " .. command)
          return false -- Prevent 'cd' if credentials fail
        end
        logSecurityEvent("CD_ALLOWED_ADMIN_AUTH", "CD attempt to protected directory allowed: " .. command)
        return true -- Allow 'cd' if credentials pass
      end
    end
  end


  -- Check for admin-protected items. If found, request admin credentials.
  -- This applies to commands other than `cd` or if `cd` didn't trigger a specific protection.
  for _, item in ipairs(protectedItems) do
    if isInPath(command, item) then
      -- Show the FS protection screen and request admin credentials
      local reason = "**Protected Command/File:** This command involves " .. item .. ". This item is a sensitive system component or a network operation. Proceed with caution."
      if not requestAdminCredentials(reason, command) then -- Pass command for logging
        logSecurityEvent("COMMAND_BLOCKED_ADMIN_REQUIRED", "Command involving protected item denied: " .. command .. " (Item: " .. item .. ")")
        return false -- Command aborted if verification fails
      end
      logSecurityEvent("COMMAND_ALLOWED_ADMIN_AUTH", "Command involving protected item allowed: " .. command .. " (Item: " .. item .. ")")
      return true -- Command allowed after successful verification
    end
  end

  -- Finally, check if the current directory is within any protected path.
  -- This acts as a general safeguard when navigating into sensitive areas.
  -- This check is mostly for commands executed *after* cd'ing into a protected dir.
  if checkDirectoryAgainstProtectedPaths(protectedItems) then -- Using protectedItems for directory check
    -- Show the FS protection screen and request admin credentials
    local reason = "**Protected Directory:** You are currently in a protected directory. Any command here may require elevated privileges to prevent system instability or security breaches. Proceed with caution."
    if not requestAdminCredentials(reason, command) then -- Pass command for logging
      logSecurityEvent("CWD_PROTECTED_COMMAND_BLOCKED", "Command in protected CWD denied: " .. command .. " (CWD: " .. shell.dir() .. ")")
      return false -- Command aborted if verification fails
    end
    logSecurityEvent("CWD_PROTECTED_COMMAND_ALLOWED", "Command in protected CWD allowed: " .. command .. " (CWD: " .. shell.dir() .. ")")
    return true -- Command allowed after successful verification
  end

  return true -- If no protection rules are triggered, the command is allowed to execute
end

-- Requests admin credentials from the user, displaying a warning message.
-- Also takes the command that triggered the prompt for logging purposes.
function requestAdminCredentials(warningMessage, triggeredCommand)
  termutils.clear() -- Clear the screen for the prompt
  
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)

  print("Doggy OS File System Protection")
  print(warningMessage) -- Display the dynamic warning message
  print("") -- Empty line for spacing
  print("Enter Administrator login.")
  
  local username = ""
  local authSettings = readAuthConfig()

  if authSettings.autoGetUser and fs.exists(CURRENT_USER_FILE) then
    local file = fs.open(CURRENT_USER_FILE, "r")
    if file then
      username = file.readAll()
      file.close()
      print("Username: " .. username .. " (from " .. CURRENT_USER_FILE .. ")")
      logSecurityEvent("AUTO_GET_USERNAME", "Username automatically retrieved from " .. CURRENT_USER_FILE .. ": " .. username)
    else
      print("Username: ")
      username = io.read()
      logSecurityEvent("AUTO_GET_USERNAME_FAIL", "Failed to read " .. CURRENT_USER_FILE .. ", prompting for username.")
    end
  else
    io.write("Username: ")
    username = io.read()
  end
  
  io.write("Password: ")
  term.setTextColor(colors.black) -- Change text color to black to hide the input
  local password = io.read()
  term.setTextColor(colors.white) -- Reset text color

  -- Verify credentials and handle access
  local isVerified = verifyPassword(username, password)
  if not isVerified then
    termutils.clear() -- Clear the screen if verification fails
    displayErrorMessage("Verification failed. " .. warningMessage) -- Show failure in a simple message
    logSecurityEvent("ADMIN_AUTH_FAIL", "Failed admin login for user: " .. username .. " (Command: " .. (triggeredCommand or "N/A") .. ")")
  else
    logSecurityEvent("ADMIN_AUTH_SUCCESS", "Successful admin login for user: " .. username .. " (Command: " .. (triggeredCommand or "N/A") .. ")")
  end
  return isVerified
end

-- Verifies the entered username and password against stored credentials.
function verifyPassword(username, password)
  local passwordFilePath = "/disk/users/" .. username .. "/password.txt"
  local file = fs.open(passwordFilePath, "r")
  
  if file then
    local correctPassword = file.readAll()
    file.close()
    
    -- Check if the password matches AND the user has admin privileges
    if password == correctPassword and userIsAdmin(username) then
      return true
    else
      return false
    end
  else
    return false -- User or password file not found, so credentials cannot be verified
  end
end

-- Checks if the user has admin privileges by looking for an "admin.txt" file.
function userIsAdmin(username)
  local adminFilePath = "/disk/users/" .. username .. "/admin.txt"
  local file = fs.open(adminFilePath, "r")
  
  if file then
    file.close()
    return true -- Admin file exists, so the user is an admin
  else
    return false -- Admin file not found, so not an admin
  end
end

-- Executes the command using shell.run with error handling.
function executeCommand(command)
  local success, err = pcall(function() shell.run(command) end)
  if not success then
    displayErrorMessage("Error executing command: " .. tostring(err))
    logSecurityEvent("COMMAND_EXECUTION_ERROR", "Error executing command: " .. command .. " (Error: " .. tostring(err) .. ")")
  else
    logSecurityEvent("COMMAND_EXECUTED", "Command executed successfully: " .. command)
  end
end

-- Checks if dev.cfg exists in the root directory (original function, kept as is)
function checkDevConfig()
  local file = fs.open("/dev.cfg", "r")
  if file then
    file.close()
    return true
  else
    return false
  end
end

-- Main execution loop for the terminal.
termutils.clear()

-- --- NEW: Get and set the hostname before the welcome message ---
systemHostname = getHostname()

-- Updated welcome message to be more Linux-like
print("DoggyOS 13.0 (ComputerCraft) Kernel.")
print("Host: " .. systemHostname) -- Display the determined hostname
print("Type 'help' for assistance.")
print("")

while true do
  local command = input()
  
  -- Check if the command is allowed based on protection rules
  if checkProtection(command) then
    executeCommand(command) -- Execute if allowed
  end
end
