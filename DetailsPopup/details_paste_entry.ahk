#Persistent
SendMode, Input

entry := A_Args[1]
paste_or_send := A_Args[2]

a2tip("Left Mouse Button or Return/Enter ⮐ To Paste`nEscape To Cancel", 0)

Escape::Gosub, Details_Abort
~LButton::Gosub, Details_Paste
Return::Gosub, Details_Paste
Enter::Gosub, Details_Paste

return

Details_Paste:
    Sleep, 150
    if (paste_or_send)
        SendRaw, %entry%
    Else
    {
        a2tip("Waiting for Clipboard ...", 0)
        clipboard_paste(entry)
    }

    FileAppend, 0, *
    ExitApp
Return

Details_Abort:
    FileAppend, 1, *
    ExitApp
Return
