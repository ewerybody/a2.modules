; getWinfo - window information tool
; gathers title, process Id, handle, class, size, position and controls information
; in a menu that you can click to get the item in your clipboard
#include <jxon>
#include <i18n>
#include <window>


getWinfo() {
    module_data := jxon_read(path_neighbor(A_LineFile, "a2module.json"))
    title := "getWinfo " module_data[1]["version"]
    t := i18n_locale(A_LineFile)
    a2tip(title . "...")

    global getWinfoID
    getWinfoID := WinExist("A")
    ahk_id := "ahk_id " . getWinfoID
    this_title := WinGetTitle(ahk_id)
    this_class := WinGetClass(ahk_id)
    thisPID := WinGetPID(ahk_id)
    this_process := WinGetProcessName(ahk_id)
    this_path := WinGetProcessPath(ahk_id)
    try
        this_ver := FileGetVersion(this_path)
    catch
        this_ver := t["no_data"]

    wInfoMenu := Menu()
    wInfoMenu.Add(title, getWinfoMenuHandler)
    wInfoMenu.SetIcon(title, A2Icons.a2)
    wInfoMenu.Disable(title)

    add_action(title, icon := "", to_menu := "", handler := "") {
        to_menu := to_menu ? to_menu : wInfoMenu
        handler := handler ? handler : getWinfoMenuHandler
        icon := icon ? icon : A2Icons.to_clipboard
        to_menu.Add(title, handler)
        to_menu.SetIcon(title, icon)
    }

    add_action("title: " this_title)
    add_action("class: " this_class)
    add_action("hwnd: " getWinfoID)
    add_action("pid: " thisPID)
    add_action("process: " this_process)
    add_action("version: " this_ver)
    add_action("path: " this_path)
    add_action(t["explore_path"], A2Icons.folder,, getWinfoGotoPath)

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

        add_action("commandline: " display_line,,, getWinfoCopyCmdLinePath)
        if FileExist(cmd_line)
            add_action(t["explore_cmd_line"], A2Icons.folder,, getWinfoGotoCmdLinePath)
    }

    ctrl_list := getWinfoControls()
    if (ctrl_list.Length) {
        wInfoMenu.Add("Controls: " ctrl_list.Length " ( " t["click_to_show"] " ... )", getWinfoControlsHandler)
        add_action(t["copy_ctrl_info"],,, getWinfoCopyControlsHandler)
    }
    else {
        wInfoMenu.Add(t['no_ctrl'], getWinfoMenuHandler)
        wInfoMenu.Disable(t['no_ctrl'])
    }

    geo := window_get_geometry(getWinfoID)
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouseX, &mouseY
    wInfoPosMenu := Menu()
    add_action("x: " . geo.x,, wInfoPosMenu)
    add_action("y: " . geo.y,, wInfoPosMenu)
    add_action("w: " . geo.w,, wInfoPosMenu)
    add_action("h: " . geo.h,, wInfoPosMenu)
    add_action("x|y|w|h: " geo.x "|" geo.y "|" geo.w "|" geo.h,, wInfoPosMenu)
    add_action("frame: " geo.frame.left "|" geo.frame.right "|" geo.frame.top "|" geo.frame.bottom,, wInfoPosMenu)
    wInfoPosMenu.Add("SetToCursor", getWinfoSetToCursor)
    add_action("MousePos: " . mouseX . "," . mouseY,, wInfoPosMenu)
    min_max := WinGetMinMax("ahk_id " . getWinfoID)
    is_fullscreen := window_is_fullscreen(getWinfoID)
    wInfoPosMenu.Add("min max: " . min_max . " is fullscreen: " . is_fullscreen, getWinfoSetToCursor)

    wInfoMenu.Add("Pos: " geo.x " x " geo.y " Size: " geo.w " x " geo.h "...", wInfoPosMenu)
    wInfoMenu.Add()
    add_action(t["cancel"], A2Icons.clear,, (*) => 0)

    CoordMode "Menu", "Screen"
    a2tip()
    wInfoMenu.Show()
}

; standard handler gets the menu item, cuts away the name, puts it to the clipboard
getWinfoMenuHandler(menu_text, *) {
    menu_text := SubStr(menu_text, InStr(menu_text, A_Space) + 1)
    A_Clipboard := menu_text
    a2tip(menu_text, 0.5)
}

; to recover lost windows
getWinfoSetToCursor(*) {
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouse_x, &mouse_y
    a2tip(getWinfoID " to " mouse_x "x" mouse_y, 2)
    ;position the window-title under the cursor so one can move it instantly:
    WinActivate("ahk_id " . getWinfoID)
    WinWait("ahk_id " . getWinfoID)
    WinMove(mouse_x - 30, mouse_y - 10,,, "ahk_id " . getWinfoID)
}

; Get array of current windows control names.
getWinfoControls() {
    return WinGetControls("ahk_id " . getWinfoID)
}

; Display windows controls and details in menu.
getWinfoControlsHandler(*) {
    ctrlList := getWinfoControls()
    ctrlSubmenu := Menu()
    startTime := A_TickCount
    for i, ctrl in ctrlList {
        tookTime := A_TickCount - startTime
        if ( tookTime > 500 ) {
            if ( mod(i, 10) == 10 )
                a2tip("gathering controls... " tookTime "`n" ctrl)
        }
        ctrl_menu := Menu()
        thisCtrlID := ControlGetHwnd(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := ControlGetText(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := SubStr(thisCtrlText, 1, 250)
        for label in ["name: " ctrl, "hwnd: " thisCtrlID, "text: " thisCtrlText] {
            ctrl_menu.Add(label, getWinfoMenuHandler)
            ctrl_menu.SetIcon(label, A2Icons.to_clipboard)
        }
        ctrlSubmenu.Add(i ": " ctrl, ctrl_menu)
    }
    ctrlSubmenu.Show()
}

getWinfoCopyControlsHandler(*) {
    ctrlList := getWinfoControls()
    text_tmp := ""
    for i, ctrl in ctrlList {
        thisCtrlID := ControlGetHwnd(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := ControlGetText(ctrl, "ahk_id " . getWinfoID)
        thisCtrlText := SubStr(thisCtrlText, 1, 250)
        text_tmp .= ctrl . " " . thisCtrlID . " " . thisCtrlText "`n"
    }
    A_Clipboard := text_tmp
}

getWinfoGotoPath(*) {
    this_path := WinGetProcessPath("ahk_id " . getWinfoID)
    explorer_show(this_path)
}

getWinfoCmdLine(pid, this_path) {
    for proc in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process WHERE ProcessID = '" pid "'") {
        cmd_line := string_strip(proc.CommandLine)
        if cmd_line = this_path
            Continue

        if string_unquote(cmd_line) = this_path
            Continue

        if string_startswith(cmd_line, '"') {
            ; try to strip quoted executable path
            pos := InStr(cmd_line, '"', false, 2, 1)
            sub := SubStr(cmd_line, 2, pos - 2)
            rest := string_unquote(string_strip(SubStr(cmd_line, pos + 2)))
            if rest
                Return rest

        } else if string_startswith(cmd_line, this_path) {
            rest := SubStr(cmd_line, StrLen(this_path) + 2)
            rest := string_strip(rest)
            if rest
                Return rest
        }
        Return cmd_line
    }
}

_getWinfo_get_cmd_line_path_from_id() {
    thisPID := WinGetPID("ahk_id " . getWinfoID)
    this_path := WinGetProcessPath("ahk_id " . getWinfoID)
    return getWinfoCmdLine(thisPID, this_path)
}


getWinfoGotoCmdLinePath(*) {
    explorer_show(_getWinfo_get_cmd_line_path_from_id())
}

getWinfoCopyCmdLinePath(*) {
    A_Clipboard := _getWinfo_get_cmd_line_path_from_id()
}
