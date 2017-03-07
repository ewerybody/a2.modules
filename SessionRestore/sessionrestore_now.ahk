; In-place sessionrestore starter ;;;;;;;;;;;;;;;;;;;;;;;;;

; 1st we need the variables:
#include ..\..\..\
#include settings\variables.ahk

If !IsObject(SessionRestore_List) {
    MsgBox, 16, SessionRestore Disabled?, There are no settings for SessionRestore! Make sure its enabled!
    ExitApp
}

;this_id := "0x10ae4"
;c := "SWT_Window0"
;this_x := 3432
;this_y := -393
;this_w := 1103
;this_h := 1932
;MsgBox this_id: %this_id%
;WinMove, ahk_id %this_id%,, %this_x%, %this_y%, %this_w%, %this_h%

sessionrestore_session_restore()
ExitApp

Return ;-----------------------------------
#include %A_ScriptDir%
#include sessionrestore.ahk
#include ..\..\..\
#include lib\ahklib\functions.ahk
#include lib\ahklib\ahk_functions.ahk
