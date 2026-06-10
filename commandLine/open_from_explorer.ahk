open_from_explorer() {
    ; TODO make this variable for eg PowerShell or others
    ; for powershell this is:
    ; powershell.exe -noexit -command "cd %path%"
    ; cmd_exe := path_join(A_WinDir, "System32", "cmd.exe")
    ; this is in the ComSpec built-in variable!
    path := explorer_get_path()

    cmd_exe := A_ComSpec
    Run cmd_exe . " /k", path,, &pid

    Sleep 100

    win_id := WinExist("ahk_pid " pid)
    ; Probably due to new Terminal stuff the initial pid is no longer pointing
    ; to a valid window it's handed to the terminal multi-tab-window and the process is gone.
    if (win_id != 0) {
        a2tip("commandLine from Explorer: (pid: " pid " hwnd: " win_id ")`n" path)
        a2dlg_info("win_id: " . win_id)
        window_activate(win_id, 1)
        return
    }

    ; Usually the according console is auto-activated. We don't need to tell the user.
    ; a2tip("commandLine from Explorer: (Called console but win-id is ZERO!?`nA_ComSpec: " cmd_exe "`npath: " path "`npid: " pid)
}
