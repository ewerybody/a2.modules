;rearrange_array := []
;rearrange_session_save()
;rearrange_session_restore()

LVM_SETITEMPOSITION := 0x1000+15
LVM_GETITEMPOSITION := 0x1000+16

ControlGet, IconList, List, , SysListView321, Program Manager ahk_class Progman
MsgBox IconList: %IconList%

icon_idx := 3

pos := get_desktop_icon_pos(icon_idx)
x := pos[1]
y := pos[2]
MsgBox x: %x% y: %y%

loop 20
{
    x := x + 10
    set_desktop_icon_pos(icon_idx, x, y)
    sleep, 10
}

Return ;-----------------------------------


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


ExtractInteger( ByRef pSource, pOffset = 0, pIsSigned = false, pSize = 4 )
{
	; pSource is a string (buffer) whose memory area contains a raw/binary integer at pOffset.
	; The caller should pass true for pSigned to interpret the result as signed vs. unsigned.
	; pSize is the size of PSource's integer in bytes (e.g. 4 bytes for a DWORD or Int).
	; pSource must be ByRef to avoid corruption during the formal-to-actual copying process
	; (since pSource might contain valid data beyond its first binary zero).
	Loop %pSize%  ; Build the integer by adding up its bytes.
		result += *(&pSource + pOffset + A_Index-1) << 8*(A_Index-1)
	if (!pIsSigned OR pSize > 4 OR result < 0x80000000)
		return result  ; Signed vs. unsigned doesn't matter in these cases.
	; Otherwise, convert the value (now known to be 32-bit) to its signed counterpart:
	return -(0xFFFFFFFF - result + 1)
}


get_desktop_icon_pos(icon_index) {
    ; get the position of an icon in virtual desktop space
    global LVM_GETITEMPOSITION

    WinGet, progman_pid, PID, Program Manager ahk_class Progman
    hp_explorer := DllCall("OpenProcess", "uint", 0x18, "int", false, "uint", progman_pid)
    remote_buffer := DllCall("VirtualAllocEx", "uint", hp_explorer, "uint", 0, "uint", 0x1000, "uint", 0x1000, "uint", 0x4)
    
    SendMessage, LVM_GETITEMPOSITION, % icon_index, remote_buffer, SysListView321, Program Manager ahk_class Progman
    
    VarSetCapacity(rect, 16, 0)
    DllCall("ReadProcessMemory", "uint", hp_explorer, "uint", remote_buffer, "uint", &rect, "uint", 16, "uint",0)
    DllCall("VirtualFreeEx", "uint", hp_explorer, "uint", remote_buffer, "uint", 0, "uint", 0x8000)
    DllCall("CloseHandle", "uint", hp_explorer)
    
    pos := Array(ExtractInteger(rect, 0), ExtractInteger(rect, 4))
    Return pos
}


set_desktop_icon_pos(icon_index, x_pos, y_pos) {
    ; set the position of an icon in virtual desktop space
    global LVM_SETITEMPOSITION
    SendMessage, LVM_SETITEMPOSITION, icon_index, (y_pos << 16) + x_pos, SysListView321, Program Manager ahk_class Progman
}
