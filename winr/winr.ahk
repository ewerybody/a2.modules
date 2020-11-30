winr() {
    global winr_paths
    selection := clipboard_get()
    selection := trim(selection, " `n`t`r")

    if string_startswith(selection, "u'") OR string_startswith(selection, "u""")
        selection := substr(selection, 2)
    selection := string_unquote(selection)
    selection := string_unquote(selection, "'")

    if (selection == "") {
        winr_CallDialog()
    }
    else if FileExist(selection) {
        tt("path exists...",0.5)
        winr_CatchedCallRun(selection)
    }
    else if (string_is_web_address(selection)) {
        tt("web address...",0.5)
        if (!string_startswith(selection, "http"))
            selection := "https://" selection
        winr_CatchedCallRun(selection)
    }
    else {
        ; loop set up project paths, if combination with selection fits: run it
        StringReplace, slashed, selection, /, \, All
        for i, ppath in winr_paths {
            ppath = %ppath%\%slashed%
            if FileExist(ppath) {
                tt("Found relative path ...",0.5)
                winr_CatchedCallRun(ppath)
                Return
            }
        }

        tt("Does not exist!`nI don't know what todo with your selection...", 1)
        winr_CallDialog()
        sleep, 300
        SendInput, %selection%
    }
}

winr_CallDialog() {
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

winr_CatchedCallRun(path) {
    global winr_explore_check
    if winr_explore_check
        explorer_show(path)
    else {
        Run, %path%,, UseErrorLevel
        if ErrorLevel {
            explorer_show(path)
            tt("but I cound not 'Run' it!`nExploring to ...:", 1.5, 1)
        }
    }
}
