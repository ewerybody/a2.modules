get_virtual_screen_size(_x, _y, vs_width, vs_height)
this_vs_size := vs_width "," vs_height

MsgBox this_vs_size: %this_vs_size%

FileAppend, %this_vs_size%, *
ExitApp

Return ;-----------------------------------
;#include ..\..\..\
;#include lib\ahklib\func_string.ahk
;#include lib\ahklib\func_file.ahk
;#include lib\ahklib\functions.ahk
;#include lib\ahklib\ahk_functions.ahk
