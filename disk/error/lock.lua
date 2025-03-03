term.clear()
print("Type Y to emergency restart")
term.setCursorPos(1,4)
local input = read("*")
if input == "y" then
os.reboot()

else
term.clear()
print("Not attempting restart")
end
