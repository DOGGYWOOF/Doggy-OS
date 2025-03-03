if fs.exists("startup")
    
then
    print("Bootloader File exists")
    
else
    print("Bootloader File does not exist")
sleep(4)
shell.run("/disk/bootloader/verify-bootloader")
end

