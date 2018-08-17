GetVirtualScreenCoordinates(_x, _y, vs_width, vs_height)
this_vs_size := vs_width "," vs_height

FileAppend, %this_vs_size%, *
ExitApp

Return ;-----------------------------------
#include ..\..\..\
#include lib\ahklib\ahk_functions.ahk
#include lib\ahklib\functions.ahk
;#include lib\ahklib\func_string.ahk
;#include lib\ahklib\func_file.ahk
