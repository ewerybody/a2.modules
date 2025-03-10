; getWinfo - window information tool
; gathers title, process Id, handle, class, size, positon and controls information
; in a menu that you can click to get the item in your clipboard
#include <jxon>
#include <window>


getWinfo() {
    module_data := jxon_read(path_neighbor(A_LineFile, "a2module.json"))
    title := "getWinfo " module_data[1]["version"]
    icon_copy := path_join(a2.paths.resources, "copy.ico")
    icon_folder := path_join(a2.paths.resources, "folder2.ico")
    a2tip(title . "...")

    global getWinfoID
    getWinfoID := WinGetID("A")
    ahkid := "ahk_id " . getWinfoID
    this_title := WinGetTitle(ahkid)
    this_class := WinGetClass(ahkid)
    thisPID := WinGetPID(ahkid)
    this_process := WinGetProcessName(ahkid)
    this_path := WinGetProcessPath(ahkid)
    try
        this_ver := FileGetVersion(this_path)
    catch
        this_ver := "- No Data -"

    wInfoMenu := Menu()
    wInfoMenu.Add(title, getWinfoMenuHandler)
    wInfoMenu.Disable(title)

    add_copy_action(title, to_menu := "") {
        if !to_menu
            to_menu := wInfoMenu
        to_menu.Add(title, getWinfoMenuHandler)
        to_menu.SetIcon(title, icon_copy,, 0)
    }

    add_copy_action("title: " . this_title)
    add_copy_action("class: " . this_class)
    add_copy_action("hwnd: " . getWinfoID)
    add_copy_action("pid: " . thisPID)
    add_copy_action("process: " . this_process)
    add_copy_action("version: " . this_ver)
    add_copy_action("path: " . this_path)

    wInfoMenu.Add("Explore to path", getWinfoGotoPath)
    wInfoMenu.SetIcon("Explore to path", icon_folder,, 0)

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

        wInfoMenu.Add("commandline: " . display_line, getWinfoCopyCmdLinePath)
        wInfoMenu.SetIcon("commandline: " . display_line, icon_copy,, 0)
        if FileExist(cmd_line)
            wInfoMenu.Add("Explore to Command line path", getWinfoGotoCmdLinePath)
    }

    ctrl_list := getWinfoCtrls()
    if (ctrl_list.Length) {
        wInfoMenu.Add("Controls: " . ctrl_list.Length . " ( click to show ... )", getWinfoCtrlsHandler)
        wInfoMenu.Add("Copy All Control Info", getWinfoCopyCtrlsHandler)
        wInfoMenu.SetIcon("Copy All Control Info", icon_copy,, 0)
    }
    else {
        wInfoMenu.Add("No Controls Here", getWinfoMenuHandler)
        wInfoMenu.Disable("No Controls Here")
    }

    window_get_rect(&X, &Y, &Width, &Height, getWinfoID)
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouseX, &mouseY
    wInfoPosMenu := Menu()
    add_copy_action("x: " . X, wInfoPosMenu)
    add_copy_action("y: " . Y, wInfoPosMenu)
    add_copy_action("w: " . Width, wInfoPosMenu)
    add_copy_action("h: " . Height, wInfoPosMenu)
    add_copy_action("x|y|w|h: " x "|" y "|" Width "|" Height, wInfoPosMenu)
    wInfoPosMenu.Add("SetToCursor", getWinfoSetToCursor)
    add_copy_action("MousePos: " . mouseX . "," . mouseY, wInfoPosMenu)
    minmax := WinGetMinMax("ahk_id " . getWinfoID)
    isfullscreen := window_is_fullscreen(getWinfoID)
    wInfoPosMenu.Add("minmax: " . minmax . " isfullscreen: " . isfullscreen, getWinfoSetToCursor)

    wInfoMenu.Add("Pos: " X " x " Y " Size: " Width " x " Height "...", wInfoPosMenu)

    wInfoMenu.Add()
    wInfoMenu.Add("Cancel", getWinfoMenuHandler)

    CoordMode "Menu", "Screen"
    a2tip()
    wInfoMenu.Show()
}

; standard handler gets the menu item, cuts away the name, puts it to the clipboard
getWinfoMenuHandler(menu_text, *) {
    if (menu_text == "Cancel")
        Return
    pos := InStr(menu_text, A_Space)
    menu_text := SubStr(menu_text, pos + 1)
    A_Clipboard := menu_text
    a2tip(menu_text, 0.5)
}

; to recover lost windows
getWinfoSetToCursor(*) {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mousex, &mousey
    a2tip(getWinfoID " to " mousex "x" mousey, 2)
    ;position the windowtitle under the cursor so one can move it instantly:
    WinActivate("ahk_id " . getWinfoID)
    WinWait("ahk_id " . getWinfoID)
    WinMove(mousex - 30, mousey - 10,,, "ahk_id " . getWinfoID)
}

; Get array of current windows control names.
getWinfoCtrls() {
    return WinGetControls("ahk_id " . getWinfoID)
}

; Display windows controls and details in menu.
getWinfoCtrlsHandler(*) {
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

getWinfoCopyCtrlsHandler(*) {
    ctrlList := getWinfoCtrls()

    texttmp := ""
    for i, ctrl in ctrlList {
        thisCtrlID := ControlGetHwnd(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := ControlGetText(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := SubStr(thisCtrlText, 1, 250)
        texttmp .= ctrl . " " . thisCtrlID . " " . thisCtrlText "`n"
    }
    A_Clipboard := texttmp
}

getWinfoGotoPath(*) {
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


getWinfoGotoCmdLinePath(*) {
    explorer_show(_getWinfo_get_cmdline_path_from_id())
}

getWinfoCopyCmdLinePath(*) {
    A_Clipboard := _getWinfo_get_cmdline_path_from_id()
}
