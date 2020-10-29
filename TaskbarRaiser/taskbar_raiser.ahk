; TaskbarRaiser - taskbar_raiser.ahk
; author: eric
; created: 2020 7 30

taskbar_raiser_init() {
    global TaskbarRaiser_Interval
    SetTimer, taskbar_raiser_check, %TaskbarRaiser_Interval%
}


taskbar_raiser_check() {
    global TaskbarRaiser_Distance, TaskbarRaiser_CheckRDC
    static workarea
    if (!workarea)
        workarea := new screen_Workarea()
    CoordMode, Mouse, Screen
	MouseGetPos,, mousey
    dist := workarea.bottom - mousey
    if (dist > TaskbarRaiser_Distance)
        Return

    WinGet, taskbar_id, ID, ahk_class Shell_TrayWnd ahk_exe Explorer.EXE
    MouseGetPos, , , id_under_cursor, control

    if TaskbarRaiser_CheckRDC {
	    WinGetClass, this_class, ahk_id %id_under_cursor%
	    WinGet, this_process, ProcessName, ahk_id %id_under_cursor%
        if (this_class == "TscShellContainerClass" AND this_process == "mstsc.exe")
            Return
    }

    if (id_under_cursor != taskbar_id)
        WinActivate, ahk_id %taskbar_id%
}
