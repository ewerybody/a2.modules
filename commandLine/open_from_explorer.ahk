open_from_explorer() {
    ; TODO make this variable for eg PowerShell or others
    ; for powershell this is:
    ; powershell.exe -noexit -command "cd %path%"
    ; cmd_exe := path_join(A_WinDir, "System32", "cmd.exe")
    ; this is in the ComSpec built-in variable!
    path := explorer_get_path()

    cmd_exe := ComSpec
    Run, %cmd_exe% /k, %path%,, pid

    Sleep, 100
    win_id := WinExist("ahk_pid " pid)
    a2tip("commandLine from Explorer: (pid: " pid " hwnd: " win_id ")`n" path)

    window_activate(win_id, 1)
}
