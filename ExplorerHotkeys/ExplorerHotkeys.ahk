; ExplorerHotkeys
#include <processes>
#include <window>
#include <windows>

ExplorerHotkeys_CallExplorer() {
    global ExplorerHotkeys_CallExplorerPath
    If FileExist(ExplorerHotkeys_CallExplorerPath)
    {
        Run ExplorerHotkeys_CallExplorerPath
        Return
    }

    msg := "The call Explorer-path set in ExplorerHotkeys is inexistent!`n`n"
    msg .= ExplorerHotkeys_CallExplorerPath . "`n`nMaybe the directory was deleted? "
    msg .= "Please make sure the path exists or choose an existing one in the dialog!"
    MsgBox_error(msg, "ExplorerHotkeys Error")
    Run "C:\\"
}

ExplorerHotkeys_ToggleHidden() {
    EH_REG_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    value_name := "Hidden"
    If (RegRead(EH_REG_KEY, value_name) == 2) {
        new_value := 1
        a2tip("Hidden Items: ON")
    } Else {
        new_value := 2
        a2tip("Hidden Items: OFF")
    }
    RegWrite(new_value, "REG_DWORD", EH_REG_KEY, value_name)
    Sleep 100 ; Whow this did only work every second time without this delay

    ExplorerHotkeys_Refresh()
}

ExplorerHotkeys_ToggleExtensions() {
    EH_REG_KEY := "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    value_name := "HideFileExt"
    If (RegRead(EH_REG_KEY, value_name) == 1) {
        new_value := 0
        a2tip("Extensions: ON")
    } Else {
        new_value := 1
        a2tip("Extensions: OFF")
    }
    RegWrite(new_value, "REG_DWORD", EH_REG_KEY, value_name)
    Sleep 100 ; Whow this did only work every second time without this delay

    ExplorerHotkeys_Refresh()
}

ExplorerHotkeys_Refresh() {
    win_class := WinGetClass("A")
    win_ver := windows_get_version()
    If (win_class = "#32770" OR (win_ver >= WIN_VISTA)) {
        Send "{F5}"
    } Else {
        PostMessage 0x111, 28931,,, "A"
    }
}

ExplorerHotkeys_DuplicateWindow() {
    this_id := WinGetID("A")
    geo := window_get_geometry(this_id)
    path := explorer_get_path()
    explorer_show(path)

    WinWaitNotActive "ahk_id " . this_id
    WinWaitActive "ahk_class CabinetWClass"
    new_id := WinGetID("A")

    window_set_rect(geo.x + 20, geo.y + 20, geo.w, geo.h, new_id)
}


ExplorerHotkeys_ShowHideSeleced() {
    items := explorer_get_selected()
    if (!items.Length) {
        a2tip("Nothing Selected!", 1)
        Return
    }

    for i, path in items
        FileSetAttrib "^H", path

    a2tip("Toggled Visibility of " items.Length " items.")
}

ExplorerHotkeys_Props() {
    items := explorer_get_selected()
    path := explorer_get_path()

    if items.Length {
        Send("!{Enter}")
        Return
    }
    cmd := 'properties "' . path . '"'
    try
        Run cmd
    catch
        msgbox_error('Could not open Properties with command:`n  ' . cmd)
}
