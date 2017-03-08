proc_name = %1%
window_list := sessionrestore_get_window_list(false, proc_name)
; format it already json style
data = {"num_windows": 
data := data " " window_list.maxIndex() ", "
data = %data%"window_list": [
for i, win in window_list {
    data := data "{ "
    data = %data%"x"
    data := data ": " win.x "},"
}
StringTrimRight, data, data, 1
data := data "]}"

FileAppend, %data%, *
ExitApp


Return ;-----------------------------------
#include sessionrestore.ahk
#include ..\..\..\
#include lib\ahklib\functions.ahk
#include lib\ahklib\ahk_functions.ahk
