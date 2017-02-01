; Rearrange - rearrange.ahk
; author: Eric Werner
; created: 2017 1 31
rearrange_dict := Object()


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
    msgbox rearrange_session_restore ...
    global rearrange_dict
    For id, win_obj in rearrange_dict
    {
        name := win_obj.name
        MsgBox %id%: %name%
    }
}


_rearrange_FindWindowEx(p_hw_parent, p_hw_child, p_class, p_title) {
    return, DllCall( "FindWindowEx", "uint", p_hw_parent, "uint", p_hw_child, "str", p_class, "str", p_title )
}


class _rearrange_win
{
    __New(x, y, w, h, name)
    {
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.name := name
    }
}