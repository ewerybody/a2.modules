proc_name = %1%
window_list := sessionrestore_get_window_list(false, proc_name)

; format it already json style
plain_list := []
for i, win in window_list
    plain_list.push([win.class, win.title, win.x, win.y, win.w, win.h])

win_json := Jxon_Dump(plain_list)

FileAppend, %win_json%, *
ExitApp

Return ;-----------------------------------
#include sessionrestore.ahk
#include ..\..\..\
#include lib\ahklib\jxon.ahk
#include lib\ahklib\functions.ahk
#include lib\ahklib\ahk_functions.ahk
