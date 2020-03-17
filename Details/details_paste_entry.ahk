#Persistent

entry := A_Args[1]

tt("Left Mouse Button To Paste`nEscape To Cancel")
Escape::Gosub, Details_Abort
~LButton::Gosub, Details_Paste

return

Details_Paste:
    Sleep, 150
    clipboard_paste(entry)
    FileAppend, 0, *
    ExitApp
Return

Details_Abort:
    FileAppend, 1, *
    ExitApp
Return
