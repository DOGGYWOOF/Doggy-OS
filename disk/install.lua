-- Clear the screen and set up colors
term.clear()
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

-- Define the width and height of the screen
local width, height = term.getSize()

-- Helper function to center text on the screen
local function centerText(y, text, textColor)
    local x = math.floor((width - #text) / 2)
    term.setCursorPos(x, y)
    term.setTextColor(textColor)
    term.write(text)
end

-- Helper function to draw a loading bar
local function drawLoadingBar(y, percent)
    local barWidth = math.floor(width * 0.6)  -- Loading bar is 60% of the screen width
    local barX = math.floor((width - barWidth) / 2)
    
    term.setCursorPos(barX, y)
    term.write("[")
    for i = 1, barWidth - 2 do
        if i <= (barWidth - 2) * (percent / 100) then
            term.write("=")
        else
            term.write(" ")
        end
    end
    term.write("]")
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

-- Display the "Please Wait..." message in white
centerText(startLine + #dogArt + 2, "Please wait...", colors.white)

-- Wait for 4 seconds to simulate initialization
sleep(4)

-- Clear the "Please Wait..." message
term.clearLine()
centerText(startLine + #dogArt + 2, "", colors.white)

-- Display the "Installation in Progress..." message in white
centerText(startLine + #dogArt + 2, "Doggy OS System Installation...", colors.white)

-- Simulate a loading bar for the installation process
for i = 1, 100, 5 do
    drawLoadingBar(startLine + #dogArt + 4, i)
    sleep(0.75)  -- Simulate installation process with each increment
end

-- Clear the loading bar and "Installing Doggy OS..." message
term.clearLine()
centerText(startLine + #dogArt + 2, "", colors.white)

-- Execute the installation commands
fs.copy("/disk/", "/root")
sleep(0.1)
disk.eject("top")
disk.eject("bottom")
disk.eject("left")
disk.eject("right")
sleep(0.1)
shell.run("rename", "/root", "/disk")
sleep(0.1)
fs.copy("/disk/.settings",".settings")
fs.copy("/disk/", "/recovery")
sleep(0.1)

-- Display the "Installation Complete!" message in white
centerText(startLine + #dogArt + 2, "Doggy OS Installation Complete!", colors.white)

-- Display the countdown message
for i = 5, 0, -1 do
    centerText(startLine + #dogArt + 4, "Rebooting in " .. i .. "...", colors.white)
    sleep(1)
end

-- Wait for 3 seconds before rebooting
sleep(0.5)

-- Reboot the system
shell.run("/disk/install-assist")
