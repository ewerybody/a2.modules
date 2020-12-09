; SessionRestore - sessionrestore.ahk
; author: Eric Werner
; created: 2017 1 31

sessionrestore_session_restore() {
    ; To avoid using the hidden windows list we need to restore all stored windows of the stored processes.
    ; That gives us the subwindows as well without the gazillions hidden ones.
    ; Then we we get another non hidden list again to have all the needed IDs.
    ; this way we find any misplacements, correct them and minimize the windows again like before.

    global SessionRestore_List
    global Sessionrestore_Restore_All_Windows

    if !IsObject(SessionRestore_List) {
        a2log_debug("Nothing stored yet!", "SessionRestore")
        return
    }

    screen_get_virtual_size(_x, _y, vs_width, vs_height)
    this_vs_size := vs_width "," vs_height
    this_vs_size_list := SessionRestore_List[this_vs_size]
    if !IsObject(this_vs_size_list) {
        ; nothing to do
        return
    }

    Progress, b h100 w500 c00, preparing ..., Restoring your session ...,

    ; first window list. Might NOT have our subwindows excluded
    window_list := sessionrestore_get_window_list()
    minimzed_windows := []
    for windex, win in window_list {

        ; update progress bar
        iprogress := (A_Index / window_list.MaxIndex()) * 100.0
        progress_text := "Preparing ...`n" A_Index "/" window_list.MaxIndex() " " win.proc_name
        Progress, %iprogress%, %progress_text%

        for sindex, swin in this_vs_size_list {
            if (swin[1] != win.proc_name)
                continue
            if (win.minmax 1= -1)
                continue
            minimzed_windows.push(win)
            this_id := win.id
            WinRestore, ahk_id %this_id%
        }
    }

    ; second window list. Will have our subwindows excluded!
    window_list := sessionrestore_get_window_list()
    for windex, win in window_list {

        ; update progress bar
        iprogress := (A_Index / window_list.MaxIndex()) * 100.0
        progress_text := "Arranging ...`n" A_Index "/" window_list.MaxIndex() " " win.proc_name
        ;sleep, 10
        Progress, %iprogress%, %progress_text%

        for sindex, swin in this_vs_size_list {
            if (swin[1] != win.proc_name)
                continue
            ; see if the class matches
            if !_sessionrestore_class_match(win.class, swin[2])
                continue
            ; see if the window title matches
            if !_sessionrestore_title_match(win.title, swin[3])
                continue
            ; see if the window geometry is off
            if (swin[4] == win.x && swin[5] == win.y && swin[6] == win.w && swin[7] == win.h)
                continue

            window_set_rect(swin[4], swin[5], swin[6], swin[7], win.id)
        }
    }

    ;nw := window_list.MaxIndex()
    ;ns := this_vs_size_list.MaxIndex()
    ;nm := minimzed_windows.MaxIndex()
    ;MsgBox nw: %nw%`nns: %ns%`nnm: %nm%

    ;loop % this_vs_size_list.MaxIndex() {
    ;    win := this_vs_size_list[A_Index]
    ;    p := win[1]
    ;    c := win[2]
    ;MsgBox %A_Index% proc: %p%`nclass: %c%
    ;}

    ; to make it look like it finished correctly
    Sleep, 250
    Progress, Off
}

_sessionrestore_class_match(win_class, match_string) {
    if ((match_string == "") || (match_string == "*") || (win_class == match_string))
        return true
    if InStr(match_string, "*") {
        if RegExMatch(win_class, match_string) {
            return true
        }
    }
    return false
}
_sessionrestore_title_match(win_title, match_string) {
    if ((match_string == "*") || (win_title == match_string))
        return true
    if InStr(match_string, "*") {
        if RegExMatch(win_title, match_string) {
            return true
        }
    }

    return false
}

sessionrestore_init() {
    hw_ahk := _sessionrestore_FindWindowEx(0, 0, "AutoHotkey", a_ScriptFullPath " - AutoHotkey v" a_AhkVersion)

    WM_WTSSESSION_CHANGE = 0x02B1
    OnMessage(WM_WTSSESSION_CHANGE, "sessionrestore_handle_session_change")

    NOTIFY_FOR_THIS_SESSION = 0
    result := DllCall("Wtsapi32.dll\WTSRegisterSessionNotification", "uint", hw_ahk, "uint", NOTIFY_FOR_ALL_SESSIONS)

    if (!result) {
        MsgBox, sessionrestore_init: WTSRegisterSessionNotification has failed!
    }
}

sessionrestore_handle_session_change(p_w, p_l, p_m, p_hw) {
    WTS_SESSION_LOCK = 0x7
    WTS_SESSION_UNLOCK = 0x8

    if ( p_w = WTS_SESSION_LOCK ) {
        ;sessionrestore_session_save()
    }
    else if ( p_w = WTS_SESSION_UNLOCK ) {
        sessionrestore_session_restore()
    }
}

;deprecated for now
sessionrestore_session_save() {
    ;global sessionrestore_dict

    WinGet, win_ids, list
    loop %win_ids% {
        this_id := win_ids%A_Index%
        WinGetPos, x, y, w, h, ahk_id %this_id%
        WinGetTitle, title, ahk_id %this_id%
        ;sessionrestore_dict[this_id] := new ...
    }
}

_sessionrestore_FindWindowEx(p_hw_parent, p_hw_child, p_class, p_title) {
    return, DllCall( "FindWindowEx", "uint", p_hw_parent, "uint", p_hw_child, "str", p_class, "str", p_title )
}

sessionrestore_get_window_list(hidden=false, process_name="") {
    current_detect_state := DetectHiddenWindows()
    if current_detect_state <> hidden
        DetectHiddenWindows(hidden)

    window_list := []

    WinGet, win_ids, list
    loop %win_ids% {
        this_id := win_ids%A_Index%
        WinGet, this_proc, ProcessName, ahk_id %this_id%
        if (process_name && this_proc != process_name)
            continue

        WinGetClass, this_class, ahk_id %this_id%
        WinGetPos, x, y, w, h, ahk_id %this_id%
        WinGetTitle, this_title, ahk_id %this_id%
        WinGet, this_minmax, MinMax, ahk_id %this_id%

        window_list.push(new _sessionrestore_window(this_proc, this_title, this_class, x, y, w, h, this_id, A_Index, this_minmax))
    }

    if current_detect_state <> hidden
        DetectHiddenWindows(current_detect_state)

    return window_list
}

class _sessionrestore_window {
    __New(proc_name, win_title, win_class, x, y, w, h, id, index, minmax) {
        this.proc_name := proc_name
        this.title := win_title
        this.class := win_class
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.id := id
        this.index := index
        this.minmax := minmax
    }
}
