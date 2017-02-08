;rearrange_array := []
;rearrange_session_save()
;rearrange_session_restore()


icons := new _DesktopIcons
;MsgBox % icons.list_all()
;icons._test_iconmove()

Progress, b w200, My SubText, Restoring your session ..., My Title
for i, icon in icons.list
{
    iprogress := (i / icons.list.maxIndex()) * 100.0
    text := i "/" icons.list.maxIndex() ": " icon.name " " iprogress "%"
    Progress, %iprogress%, %text%
    Sleep, 50
}
Sleep, 1000
Progress, Off


Return ;-----------------------------------
#include ..\..\..\
#include lib\ahklib\functions.ahk
#include lib\ahklib\ahk_functions.ahk


rearrange_session_save() {
    global rearrange_array
    
    WinGet, win_ids, list
    loop %win_ids% {
        this_id := win_ids%A_Index%
        WinGet, minmax, MinMax, ahk_id %this_id%
        if (minmax == -1)
            WinRestore, ahk_id %this_id%
        
        WinGetPos, x, y, w, h, ahk_id %this_id%
        WinGetTitle, title, ahk_id %this_id%
        rearrange_array.push(new _rearrange_win(this_id, x, y, w, h, title, minmax))
    }
}


rearrange_session_restore() {
    msgbox rearrange_session_restore ...
    ;WinMinimizeAll
    global rearrange_array
    len := rearrange_array.MaxIndex()
    For idx, win_obj in rearrange_array
    {
        this_id := win_obj.id
        ;WinRestore, ahk_id %this_id%
        desc := "name: " win_obj.name " x,y: " win_obj.x "," win_obj.y " w,h: " win_obj.w "," win_obj.h
        MsgBox %idx%/%len%: %desc%
        ;WinMinimize, ahk_id %this_id%
    }
    
    ;WinMinimizeAllUndo
}

class _rearrange_win
{
    __New(id, x, y, w, h, name, minmax)
    {
        this.id := id
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.name := name
        this.minmax := minmax
    }
}


class _DesktopIcons
{
    __New()
    {
        this.list := {}
        ControlGet, IconList, List, , SysListView321, Program Manager ahk_class Progman
        Loop, parse, IconList, `n
        {
            parts := StrSplit(A_LoopField, A_Tab)
            this.list.push(new _DesktopIcon(A_Index - 1, parts[1]))
        }
    }
    
    _test_iconmove()
    {
        icon_idx := 3
        icon := this.list[icon_idx]

        loop 20
        {
            x := icon.x + 10
            icon.set_pos(x, icon.y)
            sleep, 10
        }
    }
    
    list_all()
    {
        text := ""
        for i, icon in this.list
        {
            text := text icon.index ":" A_Tab icon.name " - " icon.x "," icon.y "`n"
        }
        return text
    }
}


class _DesktopIcon
{
    static LVM_SETITEMPOSITION := 0x1000+15
    static LVM_GETITEMPOSITION := 0x1000+16

    __new(index, name)
    {
        this.index := index
        this.name := name
        this.get_pos()
    }
    
    ; set the position of an icon in virtual desktop space
    set_pos(x, y)
    {
        SendMessage, this.LVM_SETITEMPOSITION, this.index, (y << 16) + x, SysListView321, Program Manager ahk_class Progman
        this.x := x
        this.y := y
    }
    
    get_pos()
    {
        WinGet, progman_pid, PID, Program Manager ahk_class Progman
        hp_explorer := DllCall("OpenProcess", "uint", 0x18, "int", false, "uint", progman_pid)
        remote_buffer := DllCall("VirtualAllocEx", "uint", hp_explorer, "uint", 0, "uint", 0x1000, "uint", 0x1000, "uint", 0x4)
        
        SendMessage, this.LVM_GETITEMPOSITION, % this.index, remote_buffer, SysListView321, Program Manager ahk_class Progman
        
        VarSetCapacity(rect, 16, 0)
        DllCall("ReadProcessMemory", "uint", hp_explorer, "uint", remote_buffer, "uint", &rect, "uint", 16, "uint",0)
        DllCall("VirtualFreeEx", "uint", hp_explorer, "uint", remote_buffer, "uint", 0, "uint", 0x8000)
        DllCall("CloseHandle", "uint", hp_explorer)
        
        this.x := extract_integer(rect, 0)
        this.y := extract_integer(rect, 4)
    }
}
