; Rearrange - rearrange.ahk
; author: Eric Werner
; created: 2017 1 31

rearrange_init() {
    hw_ahk := _rearrange_FindWindowEx(0, 0, "AutoHotkey", a_ScriptFullPath " - AutoHotkey v" a_AhkVersion)

    WM_WTSSESSION_CHANGE = 0x02B1
    OnMessage(WM_WTSSESSION_CHANGE, "rearrange_handle_session_change")

    NOTIFY_FOR_THIS_SESSION = 0
    result := DllCall("Wtsapi32.dll\WTSRegisterSessionNotification", "uint", hw_ahk, "uint", NOTIFY_FOR_ALL_SESSIONS)

    if (!result)
    {
        MsgBox, rearrange_init: WTSRegisterSessionNotification has failed!
    }
}


rearrange_handle_session_change(p_w, p_l, p_m, p_hw) {
    WTS_SESSION_LOCK    = 0x7
    WTS_SESSION_UNLOCK  = 0x8

    if ( p_w = WTS_SESSION_LOCK )
    {
        rearrange_session_save()
    }
    else if ( p_w = WTS_SESSION_UNLOCK )
    {
        rearrange_session_restore()
    }
}


rearrange_session_save() {
    global rearrange_dict
    
    WinGet, win_ids, list
    loop %win_ids% {
        this_id := win_ids%A_Index%
        WinGetPos, x, y, w, h, ahk_id %this_id%
        WinGetTitle, title, ahk_id %this_id%
        rearrange_dict[this_id] := new _rearrange_win(x, y, w, h, title)
    }
}


rearrange_session_restore() {
    global rearrange_list
    global rearrange_restore_all_windows
    
    WinGet, win_ids, list
    
    Progress, b w500, My SubText, Restoring your session ..., My Title
    
    loop %win_ids% {
        ; get current window stats
        this_id := win_ids%A_Index%
        WinGet, this_proc, ProcessName, ahk_id %this_id%
        WinGetClass, this_class, ahk_id %this_id%
        WinGetTitle, this_name, ahk_id %this_id%
        WinGet, this_minmax, MinMax, ahk_id %this_id%
        
        ; update progress bar
        iprogress := (A_Index / win_ids) * 100.0
        progress_text := A_Index "/" win_ids " " this_proc
        Progress, %iprogress%, %progress_text%
        
        ; loop through saved windows
        Loop % rearrange_list.MaxIndex()
        {
            window := rearrange_list[A_Index]
            if window.proc_name == this_proc
            {
                if  (window.ignore)
                    Goto continue_outer
                
                if (this_minmax == -1)
                    WinRestore, ahk_id %this_id%
                WinGetPos, x, y, w, h, ahk_id %this_id%

                if (x != window.x || y != window.y || w != window.w || h != window.h)
                {
                    ;text := window.proc_name " - saved geo vs current:`n" window.x " " window.y " " window.w " " window.h "`n" x " " y " " w " " h
                    ;msgbox %text%
                    this_x := window.x
                    this_y := window.y
                    this_w := window.w
                    this_h := window.h
                    WinMove, ahk_id %this_id%,, this_x, this_y, this_w, this_h
                } else {
                    ;text := window.proc_name " window still on saved pos!"
                    ;msgbox, %text%
                }
                
                if (this_minmax == -1)
                    WinMinimize, ahk_id %this_id%
                Goto continue_outer
            }
        }
        continue_outer:

        if rearrange_restore_all_windows and this_minmax = -1
        {
            WinRestore, ahk_id %this_id%
            WinMinimize, ahk_id %this_id%
            ;rearrange_dict[this_id] := new _rearrange_win(x, y, w, h, title)
        }
    }
    Progress, Off
}


_rearrange_FindWindowEx(p_hw_parent, p_hw_child, p_class, p_title) {
    return, DllCall( "FindWindowEx", "uint", p_hw_parent, "uint", p_hw_child, "str", p_class, "str", p_title )
}


class _rearrange_procwin
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
