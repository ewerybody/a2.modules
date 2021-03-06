; ExplorerHotkeys

ExplorerHotkeys_CallExplorer() {
    global ExplorerHotkeys_CallExplorerPath
    IfExist, %ExplorerHotkeys_CallExplorerPath%
    {
        Run, %ExplorerHotkeys_CallExplorerPath%
        Return
    }

    msg = The call Explorer-path set in ExplorerHotkeys is inexistent!`n`n
    msg = %msg% %ExplorerHotkeys_CallExplorerPath%`n`n
    msg = %msg%Maybe the directory was deleted? Please make sure the path exists or choose an existing one in the dialog!
    MsgBox, 16, ExplorerHotkeys Error, %msg%

    Run, "C:\\"
}

ExplorerHotkeys_ToggleHidden() {
    EH_REG_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    value_name := "Hidden"
    RegRead, value, %EH_REG_KEY%, %value_name%

    If (value == 2) {
        new_value := 1
        tt("Hidden Items: ON", 1)
    } Else {
        new_value := 2
        tt("Hidden Items: OFF", 1)
    }
    RegWrite, REG_DWORD, %EH_REG_KEY%, %value_name%, %new_value%
    Sleep, 100 ; Whow this did only work every second time without this delaay

    ExplorerHotkeys_Refresh()
}

ExplorerHotkeys_ToggleExtensions() {
    EH_REG_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    value_name := "HideFileExt"
    RegRead, value, %EH_REG_KEY%, %value_name%

    If (value == 1) {
        new_value := 0
        tt("Extensions: ON", 1)
    } Else {
        new_value := 1
        tt("Extensions: OFF", 1)
    }
    RegWrite, REG_DWORD, %EH_REG_KEY%, %value_name%, %new_value%
    Sleep, 100 ; Whow this did only work every second time without this delaay

    ExplorerHotkeys_Refresh()
}

ExplorerHotkeys_Refresh() {
    WinGetClass, win_class, A
    If (win_class = "#32770" OR (WinVer >= WIN_VISTA)) {
        send, {F5}
    } Else {
        PostMessage, 0x111, 28931,,, A
    }
}

ExplorerHotkeys_DuplicateWindow() {
    WinGet, this_id, ID, A
    geo := window_get_geometry(this_id)
    path := explorer_get_path()
    explorer_show(path)

    WinWaitNotActive, ahk_id %this_id%
    WinWaitActive, ahk_class CabinetWClass
    WinGet, new_id, ID, A

    window_set_rect(geo.x + 20, geo.y + 20, geo.w, geo.h, new_id)
}
