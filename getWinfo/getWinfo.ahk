; getWinfo - window information tool
; gathers title, process Id, handle, class, size, positon and controls information
; in a menu that you can click to get the item in your clipboard

getWinfo() {
    a2tip("getting Winfo ...")
    Sleep 50
    global getWinfoID
    getWinfoID := WinGetID("A")
    ahkid := "ahk_id " . getWinfoID
    this_title := WinGetTitle(ahkid)
    this_class := WinGetClass(ahkid)
    thisPID := WinGetPID(ahkid)
    this_process := WinGetProcessName(ahkid)
    this_path := WinGetProcessPath(ahkid)
    this_ver := FileGetVersion(this_path)

    wInfoMenu := Menu()
    wInfoMenu.Add("title: " . this_title, getWinfoMenuHandler)
    wInfoMenu.Add("class: ". this_class, getWinfoMenuHandler)
    wInfoMenu.Add("hwnd: " . getWinfoID, getWinfoMenuHandler)
    wInfoMenu.Add("pid: " . thisPID, getWinfoMenuHandler)
    wInfoMenu.Add("process: " . this_process, getWinfoMenuHandler)
    wInfoMenu.Add("version: " . this_ver, getWinfoMenuHandler)
    wInfoMenu.Add("path: " . this_path, getWinfoMenuHandler)
    wInfoMenu.Add("Explore to path", getWinfoGotoPath)

    ; "The names of menus and menu items can be up to 260 characters long."
    ; https://www.autohotkey.com/docs/commands/Menu.htm#Remarks ...260 is a lot!
    max_menu_label_len := 64
    cmd_line := getWinfoCmdLine(thisPID, this_path)
    if (cmd_line) {
        if (StrLen(cmd_line) > max_menu_label_len) {
            display_line := SubStr(cmd_line, 1, max_menu_label_len) "..."
        }
        else
            display_line := cmd_line

        wInfoMenu.Add("commandline: ". display_line, getWinfoCopyCmdLinePath)
        if FileExist(cmd_line)
            wInfoMenu.Add("Explore to Command line path", getWinfoGotoCmdLinePath)
    }

    ctrl_list := getWinfoCtrls()
    if (ctrl_list.Length) {
        wInfoMenu.Add("Controls: ". ctrl_list.Length . " ( click to show ... )", getWinfoCtrlsHandler)
        wInfoMenu.Add("Copy All Control Info", getWinfoCopyCtrlsHandler)
    }
    else {
        wInfoMenu.Add("No Controls Here", getWinfoMenuHandler)
        wInfoMenu.Disable("No Controls Here")
    }

    window_get_rect(X, Y, Width, Height, getWinfoID)
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouseX, &mouseY
    wInfoPosMenu := Menu()
    wInfoPosMenu.Add("x: " . X, getWinfoMenuHandler)
    wInfoPosMenu.Add("y: " . Y, getWinfoMenuHandler)
    wInfoPosMenu.Add("w: " . Width, getWinfoMenuHandler)
    wInfoPosMenu.Add("h: " . Height, getWinfoMenuHandler)
    wInfoPosMenu.Add("x|y|w|h: " x "|" y "|" Width "|" Height, getWinfoMenuHandler)
    wInfoPosMenu.Add("SetToCursor", getWinfoSetToCursor)
    wInfoPosMenu.Add("MousePos: " . mouseX . "," . mouseY, getWinfoMenuHandler)

    wInfoMenu.Add("Pos: " X " x " Y " Size: " Width " x " Height "...", wInfoPosMenu)

    wInfoMenu.Add()
    wInfoMenu.Add("Cancel", getWinfoMenuHandler)

    CoordMode "Menu", "Screen"
    wInfoMenu.Show(mouseX + 15, mouseY + 47)
    a2tip()
}

; standard handler gets the menu item, cuts away the name, puts it to the clipboard
getWinfoMenuHandler:
    getWinfoID := A_ThisMenuItem
    if (getWinfoID == "Cancel")
        Return
    iTmp := InStr(getWinfoID, A_Space)
    getWinfoID := SubStr(getWinfoID, 1, iTmp + 1)
    Clipboard := getWinfoID
    a2tip(getWinfoID, 0.5)
return

; to recover lost windows
getWinfoSetToCursor:
    CoordMode "Mouse", "Screen"
    MouseGetPos &mousex, &mousey
    a2tip(getWinfoID " to " mousex "x" mousey, 2)
    ;position the windowtitle under the cursor so one can move it instantly:
    WinActivate("ahk_id " . getWinfoID)
    WinWait("ahk_id " . getWinfoID)
    WinMove(mousex - 30, mousey - 10,,, "ahk_id " . getWinfoID)
return

; Get array of current windows control names.
getWinfoCtrls() {
    return WinGetControls("ahk_id " . getWinfoID)
}

; Display windows controls and details in menu.
getWinfoCtrlsHandler() {
    global getWinfoID

    ctrlList := getWinfoCtrls()
    ; menuList := []

    ctrlSubmenu := Menu()
    startTime := A_TickCount
    for i, ctrl in ctrlList {
        tookTime := A_TickCount - startTime
        if ( tookTime > 500 ) {
            if ( mod(i, 10) == 10 )
                a2tip("gathering controls... " tookTime "`n" ctrl)
        }

        menuName := Menu()
        ; menuName := "getWinfoCtrlMenu" i
        ; menuList.push(menuName)
        thisCtrlID := ControlGetHwnd(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := ControlGetText(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := SubStr(thisCtrlText, 1, 250)

        menuName.Add("name: " . ctrl, getWinfoMenuHandler)
        menuName.Add("hwnd: " . thisCtrlID, getWinfoMenuHandler)
        menuName.Add("text: " . thisCtrlText, getWinfoMenuHandler)

        ctrlSubmenu.Add(i . ": " . ctrl, menuName)
    }

    ; Menu, wInfoMenu, Add, controls: %numCtrls%, :ctrlSubmenu
    ctrlSubmenu.Show()
}

getWinfoCopyCtrlsHandler:
    getWinfoCopyCtrlsHandler(getWinfoID)
Return

getWinfoCopyCtrlsHandler(getWinfoID) {
    ctrlList := getWinfoCtrls()

    texttmp := ""
    for i, ctrl in ctrlList {
        thisCtrlID := ControlGetHwnd(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := ControlGetText(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := SubStr(thisCtrlText, 1, 250)
        texttmp .= ctrl . " " . thisCtrlID . " " . thisCtrlText "`n"
    }
    Clipboard := texttmp
}

getWinfoGotoPath() {
    global getWinfoID
    this_path := WinGetProcessPath("ahk_id " . getWinfoID)
    explorer_show(this_path)
}

getWinfoCmdLine(pid, this_path) {
    for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process WHERE ProcessID = '" . pid . "'") {
        this_cmdline := string_strip(proc.CommandLine)
        if this_cmdline = this_path
            Continue

        if string_unquote(this_cmdline) = this_path
            Continue

        if string_startswith(this_cmdline, '"') {
            ; try to strip quoted executable path
            qpos := InStr(this_cmdline, '"', false, 2, 1)
            sub := SubStr(this_cmdline, 2, qpos - 2)
            rest := string_unquote(string_strip(SubStr(this_cmdline, qpos + 2)))
            if rest
                Return rest

        } else if string_startswith(this_cmdline, this_path) {
            rest := SubStr(this_cmdline, strlen(this_path) + 2)
            rest := string_strip(rest)
            if rest
                Return rest
        }
        Return this_cmdline
    }
}

_getWinfo_get_cmdline_path_from_id() {
    global getWinfoID
    thisPID := WinGetPID("ahk_id " . getWinfoID)
    this_path := WinGetProcessPath("ahk_id " . getWinfoID)
    return getWinfoCmdLine(thisPID, this_path)
}


getWinfoGotoCmdLinePath() {
    explorer_show(_getWinfo_get_cmdline_path_from_id())
}

getWinfoCopyCmdLinePath() {
    Clipboard := _getWinfo_get_cmdline_path_from_id()
}
