; ExplorerHotkeys

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
    If (win_class = "#32770" OR (WinVer >= WIN_VISTA)) {
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

ExplorerHotkeys_ReloadAll() {
    a2tip("Getting Explorers ...")
    explorers := window_list(,,"CabinetWClass")
    pids := processes_list_ids("explorer.exe")
    paths := []
    if (explorers.Length) {
        txt := "Found " explorers.Length " Explorer windows "
        for i, win in explorers
        {
            path := explorer_get_path(win.id)
            if (string_is_in_array(path, paths))
                Continue
            paths.Push(path)
        }
        if (paths.Length == 1)
            txt .= "with 1 path:`n " paths[1]
        else
            txt .= "with " paths.Length " different paths:`n " string_join(paths, "`n ")
    } else
        txt := "Found no Explorer windows but " pids.Length " processes."

    a2tip()
    txt .= "`n`nDo you want to shut down & reload now?"
    if !msgbox_accepted(txt, "ExplorerHotkeys ReloadAll")
        return

    for i, pid in pids
    {
        a2tip_add("Closing PID: " pid)
        ProcessClose(pid)
    }

    Sleep 100
    if !(paths)
        explorer_show("")
    else {
        for i, path in paths
            explorer_show(path)
    }

    pids := processes_list_ids("explorer.exe")
    a2tip(pids.Length " procs after: " string_join(pids))
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
