; In-place sessionrestore starter

; 1st we need the variables: (FIXME: this breaks if a2 path != a2 data path)
#include ..\..\..\
#include includes\variables.ahk

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
#include <ahk_functions>
