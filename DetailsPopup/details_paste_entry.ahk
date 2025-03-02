Persistent
SendMode "Input"
#include <a2tip>
#include <string>
#include <msgbox>
#include <clipboard>

entry := A_Args[1]

a2tip("Left Mouse Button or Return/Enter ⮐ To Paste`nEscape To Cancel", 100)

Escape::Details_Abort
~LButton::Details_Paste
; Return::Details_Paste
Enter::Details_Paste

return

Details_Paste() {
    a2tip("DetailsPopup: Waiting for Clipboard ...", 0)
    clipboard_paste(entry)

    FileAppend(0, "*")
    ExitApp
}

Details_Abort() {
    FileAppend(1, "*")
    ExitApp
}