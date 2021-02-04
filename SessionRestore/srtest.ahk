;rearrange_array := []
;rearrange_session_save()
;rearrange_session_restore()

icons := new _DesktopIcons
MsgBox % icons.list_all()
icons._test_iconmove()

;rearrange_list := []
;rearrange_restore_all_windows := false
;rearrange_list.push(new _rearrange_procwin("notepad++.exe", "", "", 1563, -6, 1605, 1457))
;rearrange_list.push(new _rearrange_procwin("KeePass.exe", "", "", 0, 0, 0, 0, true))
;rearrange_session_restore()
ExitApp

Return ;-----------------------------------
;#include sessionrestore.ahk
;#include <a2functions>
;#include <ahk_functions>

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

        this.x := bytes_get_integer(rect, 0), this.y := bytes_get_integer(rect, 4)
    }
}
