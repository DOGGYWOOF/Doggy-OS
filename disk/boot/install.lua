term.clear()
term.setCursorPos(1,1)
print("Do you want to install Doggy OS, to confirm press Enter")
read()
sleep(3)
term.clear()
term.setCursorPos(1,1)
print("Installing")
shell.run("cp","/disk/","Root")
disk.eject("top")
disk.eject("bottom")
fs.move("Root","disk")
sleep(2)
print("installed")
shell.run("/disk/bootloader/recovery")


