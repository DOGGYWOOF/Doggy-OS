if fs.exists("/disk2")
    then
    term.clear()
    term.setCursorPos(1,1)
    print("Securing Disk")
    sleep(3)
    fs.copy("/disk/security/encrypt/start.lua","/disk2/startup")
    term.clear()
    term.setCursorPos(1,1)
    print("Secured")
    sleep(3)
    shell.run("/disk/os/gui")
    
    else
    term.clear()
    term.setCursorPos(1,1)
    print("Disk not found")
    read()
    shell.run("/disk/os/gui")
end
