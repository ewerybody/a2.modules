; In-place sessionrestore starter

; 1st we need the variables:
#include ..\..\..\
#include settings\variables.ahk

; escape if nothing is set:
If !IsObject(SessionRestore_List) {
    MsgBox, 16, SessionRestore Disabled?, There are no settings for SessionRestore! Make sure its enabled!
    ExitApp
}

sessionrestore_session_restore()
ExitApp

Return ;-----------------------------------
#include %A_ScriptDir%
#include sessionrestore.ahk
#include ..\..\..\
#include lib\ahklib\func_string.ahk
#include lib\ahklib\func_file.ahk
#include lib\ahklib\functions.ahk
#include lib\ahklib\ahk_functions.ahk
