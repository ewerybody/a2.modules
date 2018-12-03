winr() {
    global winr_paths
	selection := clipboard_get()
	selection := trim(selection, " `n`t`r")
	
	if (selection == "") {
		winrCallDialog()
	}
	else if FileExist(selection) {
        tt("path exists...",0.5)
		winrCatchedCallRun(selection)
	}
	; has http:// in the front
	else if (string_is_web_adress(selection)) {
		tt("web address...",0.5)
        if (SubStr(selection, 1, 4) != "http")
            selection := "https://" selection
        winrCatchedCallRun(selection)
	}
	else {
        ; loop set up project paths, if combination with selection fits: run it
        StringReplace, slashed, selection, /, \, All
        for i, ppath in winr_paths {
            ppath = %ppath%\%slashed%
            if FileExist(ppath) {
                tt("Found relative path ...",0.5)
                winrCatchedCallRun(ppath)
                Return
            }
        }

        tt("Does not exist!`nI don't know what todo with your selection...", 1)
        winrCallDialog()
        sleep, 300
        SendInput, %selection%
    }
}

winrCallDialog() {
	runWindow = Run ahk_class #32770
	Send #r
	WinWaitActive, %runWindow%
    global winr_move_to_cursor
    if (winr_move_to_cursor) {
        CoordMode, Mouse, Screen
        MouseGetPos, clq_mousex, clq_mousey
        WinMove, %runWindow%, ,(clq_mousex - 30), (clq_mousey - 10)
    }
}

winrCatchedCallRun(ppath) {
    Run, %ppath%,, UseErrorLevel
    if ErrorLevel {
        cmd = explorer.exe /select,"%ppath%"
        Run, %cmd%
        tt("but I cound not 'Run' it!`nExploring to ...:", 1.5, 1)
    }
}