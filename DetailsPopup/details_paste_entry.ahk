#Persistent

entry := A_Args[1]

a2tip("Left Mouse Button or Return/Enter ⮐ To Paste`nEscape To Cancel", 0)

Escape::Gosub, Details_Abort
~LButton::Gosub, Details_Paste
Return::Gosub, Details_Paste
Enter::Gosub, Details_Paste

return

Details_Paste:
    Sleep, 150
    a2tip("Waiting for Clipboard ...", 0)
    clipboard_paste(entry)
    FileAppend, 0, *
    ExitApp
Return

Details_Abort:
    FileAppend, 1, *
    ExitApp
Return
