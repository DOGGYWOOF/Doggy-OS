os.pullEvent = os.pullEventRaw

if not multishell then
    term.clear()
    term.setCursorPos(1, 1)
    print("Doggy OS Install error: Unsupported System")
    read()
    disk.eject("back")
    disk.eject("bottom")
    disk.eject("left")
    disk.eject("right")
    disk.eject("top")
    disk.eject("front")
    os.reboot()
    return
else
    -- Center the text within the given width
    function centerText(text, width)
        local padding = math.max(0, math.floor((width - #text) / 2))
        return string.rep(" ", padding) .. text
    end

    -- Draw a border with specified width and height
    function drawBorder(width, height)
        term.setCursorPos(1, 1)
        term.write("+" .. string.rep("-", width - 2) .. "+")
        for i = 2, height - 1 do
            term.setCursorPos(1, i)
            term.write("|")
            term.setCursorPos(width, i)
            term.write("|")
        end
        term.setCursorPos(1, height)
        term.write("+" .. string.rep("-", width - 2) .. "+")
    end

    -- Draw the centered text with more spacing
    function drawCenteredText(width, height)
        term.setCursorPos(2, 2)
        drawBorder(width, height)

        local y = 4
        term.setCursorPos(3, y)
        print(centerText("Doggy OS v13 Online Installer", width - 4))

        y = y + 2
        term.setCursorPos(3, y)
        print(centerText("OS VERSION: Doggy OS 13.0", width - 4))

        y = y + 1
        term.setCursorPos(3, y)
        print(centerText("UEFI: DOGGY OS UEFI CONFIG (N3K0)", width - 4))

        y = y + 1
        term.setCursorPos(3, y)
        print(centerText("BOOTLOADER: VA11-ILLA 13.0", width - 4))

        y = y + 3
        term.setCursorPos(3, y)
        print(centerText("Confirm Install", width - 4))

        y = y + 1
        term.setCursorPos(3, y)
        print(centerText("Y: Install OS", width - 4))

        y = y + 1
        term.setCursorPos(3, y)
        print(centerText("N: Cancel Install", width - 4))

        y = y + 3
        term.setCursorPos(3, y)
        print(centerText("===================================", width - 4))
    end

    function main()
        term.clear()
        local w, h = term.getSize()
        local contentHeight = 16
        local borderPadding = 2  -- Padding between border and content

        -- Adjust height for border padding
        local heightWithBorders = contentHeight + borderPadding * 2

        -- Make sure the height fits within the screen
        local displayHeight = math.min(h, heightWithBorders)
        drawCenteredText(w, displayHeight)

        -- Read user input
        term.setCursorPos(3, displayHeight - 1)
        local user_input = read()

        if user_input:lower() == 'y' then
            -- Fetch and run the online installation script
            local installer = http.get("https://raw.githubusercontent.com/DOGGYWOOF/Doggy-OS/refs/heads/v13-Standard/installer/installgui")
            if installer then
                local installerScript = installer.readAll()
                installer.close()
                loadstring(installerScript)()  -- Run the installer script
            else
                term.clear()
                term.setCursorPos(1, 1)
                print("Error: Unable to download installation script.")
                sleep(2)
                return
            end
        elseif user_input:lower() == 'n' then
            term.clear()
            term.setCursorPos(1, 1)
            drawBorder(w, 7)
            term.setCursorPos(3, 2)
            print(centerText("The Installation Was Cancelled!", w - 4))
            sleep(2)  -- A short delay before exiting
            return  -- Exit the installation process without doing anything further
        else
            shell.run("/disk/startup")
            main()
        end
    end

    function runProgram()
        -- Replace the following line with the code to run your desired program
        shell.run("/disk/install")  -- Replace with your actual program name
        
        term.clear()
        term.setCursorPos(1, 1)
        print("Doggy OS Install error")
        print("====================================")
        print("Unable to load installation program")
        print("Press enter to retry")
        read()
        os.reboot()
    end

    main()
end
