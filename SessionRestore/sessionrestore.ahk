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
    
    ; first window list. Might NOT have our subwindows excluded
    window_list := sessionrestore_get_window_list()
    minimzed_windows := []
    for windex, win in window_list {
        for sindex, swin in SessionRestore_List {
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
        for sindex, swin in SessionRestore_List {
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
            
            text := win.proc_name " - " win.id " saved geo vs current:`n" win.x " " win.y " " win.w " " win.h "`n" swin[4] " " swin[5] " " swin[6] " " swin[7]
            msgbox %text%
            this_id := win.id
            this_x := swin[4]
            this_y := swin[5]
            this_w := swin[6]
            this_h := swin[7]
            WinMove, ahk_id %this_id%,, this_x, this_y, this_w, this_h
        }
    }

    nw := window_list.MaxIndex()
    ns := SessionRestore_List.MaxIndex()
    nm := minimzed_windows.MaxIndex()
    ;MsgBox nw: %nw%`nns: %ns%`nnm: %nm%
    
    loop % SessionRestore_List.MaxIndex() {
        win := SessionRestore_List[A_Index]
        p := win[1]
        c := win[2]
        ;MsgBox %A_Index% proc: %p%`nclass: %c%
    }

}


_sessionrestore_class_match(win_class, match_string) {
    if ((match_string == "") || (match_string == "*") || (win_class == match_string))
        return true
    if InStr(match_string, "*")
        if RegExMatch(win_class, match_string)
            return true

    return false
}
_sessionrestore_title_match(win_title, match_string) {
    if ((match_string == "*") || (win_title == match_string))
        return true
    if InStr(match_string, "*")
        if RegExMatch(win_title, match_string)
            return true

    return false
}


sessionrestore_init() {
    hw_ahk := _sessionrestore_FindWindowEx(0, 0, "AutoHotkey", a_ScriptFullPath " - AutoHotkey v" a_AhkVersion)

    WM_WTSSESSION_CHANGE = 0x02B1
    OnMessage(WM_WTSSESSION_CHANGE, "sessionrestore_handle_session_change")

    NOTIFY_FOR_THIS_SESSION = 0
    result := DllCall("Wtsapi32.dll\WTSRegisterSessionNotification", "uint", hw_ahk, "uint", NOTIFY_FOR_ALL_SESSIONS)

    if (!result)
    {
        MsgBox, sessionrestore_init: WTSRegisterSessionNotification has failed!
    }
}


sessionrestore_handle_session_change(p_w, p_l, p_m, p_hw) {
    WTS_SESSION_LOCK    = 0x7
    WTS_SESSION_UNLOCK  = 0x8

    if ( p_w = WTS_SESSION_LOCK )
    {
        ;sessionrestore_session_save()
    }
    else if ( p_w = WTS_SESSION_UNLOCK )
    {
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


class _sessionrestore_procwin
{
    __New(proc_name, win_name="", win_class="", pos_x=0, pos_y=0, size_w=0, size_h=0, ignore=false)
    {
        this.proc_name := proc_name
        this.win_name := win_name
        this.win_class := win_class
        this.ignore := ignore
        this.x := pos_x
        this.y := pos_y
        this.w := size_w
        this.h := size_h
    }
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


class _sessionrestore_window
{
    __New(proc_name, win_title, win_class, x, y, w, h, id, index, minmax)
    {
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