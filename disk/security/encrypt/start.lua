if fs.exists("/disk/security/Unlock.lua")
    then
    term.clear()
    term.setCursorPos(1,1)
    print("Doggy OS secure disk detected")
    sleep(3)
    shell.run("/disk/os/gui")    
    else
    term.clear()
    term.setCursorPos(1,1)
    print("Doggy OS secure disk failed to start")
    read()
    os.reboot()
end
    
