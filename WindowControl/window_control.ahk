; WindowControl - window_control.ahk
; author: Wolfgang Reszel, Jack Tissen
; created: 2021 2 23

window_control_minimize() {
    ; Minimize the active window.
    window_control_check_MouseHotkey()
    ; TODO: What was this for?
    ; If func_IsWindowInIgnoreList?()
    ;     Return
    ahkid := "ahk_id " . WinGetID("A")
    WinMoveBottom(ahkid)

    ; WinMinimize, ahk_id %wc_ID%
    ; TODO: Why is this better?
    PostMessage 0x0112, 0x0000f020, 0x00f40390,, ahkid
}

window_control_maximize() {
    ; Toggle maximize/restore for the active window.
    win_id := window_control_check_MouseHotkey()
    window_toggle_maximize(win_id)
}

window_control_toggle_always_on_top() {
    ; Toggle always-on-top aka AOT for the active window.
    win_id := window_control_check_MouseHotkey()
    win_class := WinGetClass("ahk_id " win_id)
    title := WinGetTitle("ahk_id " win_id)
    If string_is_in_array(win_class, ["Shell_TrayWnd", "Progman"])
        Return

    aot_state := window_is_aot(win_id)

    if (window_is_aot(win_id)) {
        window_set_aot(0, win_id)

        state := window_is_aot(win_id)
        if (!state)
            a2tip("AlwaysOnTop: OFF")
        Else
            msgbox_error("Setting AOT OFF didn't work!!!`nstate: " state)
    } Else {
        window_set_aot(1, win_id)

        state := window_is_aot(win_id)
        if (state)
            a2tip("AlwaysOnTop: ON")
        Else
            msgbox_error("Setting AOT OFF didn't work!!!`nstate: " state)
    }
}

window_control_check_MouseHotkey() {
    ; If action is triggered via mouse key,
    ; make sure the window under the cursor is activated!
    If string_is_in_array(A_ThisHotkey, ["MButton","LButton","RButton","XButton1","XButton2"])
    {
        MouseGetPos ,,&win_id
        window_activate(win_id)
    }
    Else
        win_id := WinGetID("A")

    return win_id
}
