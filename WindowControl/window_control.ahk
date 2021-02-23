; WindowControl - window_control.ahk
; author: Wolfgang Reszel, Jack Tissen
; created: 2021 2 23

window_control_minimize() {
    ; Minimize the active window.
    window_control_check_MouseHotkey()
    ; TODO: What was this for?
    ; If func_IsWindowInIgnoreList?()
    ;     Return
    WinGet, win_id, ID, A
    WinSet, Bottom,, ahk_id %win_id%

    ; WinMinimize, ahk_id %wc_ID%
    ; TODO: Why is this better?
    PostMessage, 0x0112, 0x0000f020, 0x00f40390,, ahk_id %win_id%
}

window_control_maximize() {
    ; Toggle maximize/restore for the active window.
    window_control_check_MouseHotkey()

    WinGet, this_id, ID, A
    window_toggle_maximize(win_id)
}

window_control_toggle_always_on_top() {
    ; Toggle always-on-top aka AOT for the active window.
    window_control_check_MouseHotkey()

    WinGet, wc_ExStyle, ExStyle, A
    WinGetClass, win_class, A
    If win_class in Shell_TrayWnd,Progman
        Return

    if (wc_ExStyle & 0x8) {
        WinSet, AlwaysOnTop, Off, A
        tt("AlwaysOnTop: OFF", 1)
    } Else {
        WinSet, AlwaysOnTop, On, A
        tt("AlwaysOnTop: ON", 1)
    }
}

window_control_check_MouseHotkey() {
    ; If action is triggered via mouse key,
    ; make sure the window under the cursor is activated!
    If A_ThisHotkey contains MButton,LButton,RButton,XButton1,XButton2
    {
        MouseGetPos,,,win_id
        window_activate(win_id)
    }
}
