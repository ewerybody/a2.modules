; codeTools - slasher.ahk
; author: eric
; created: 2015 6 11

slasher() {
    slasher_menu := Menu()
    slasher_menu.Add("1 \ <> / toggle back/forward", slasher_menu_handler)
    slasher_menu.Add("2 \ > \\ double backslashes", slasher_menu_handler)
    slasher_menu.Add("3 \\ > \ single backslashes", slasher_menu_handler)
    slasher_menu.Show()
}

slasher_menu_handler:
    Selection := clipboard_get()
    if (A_ThisMenuItemPos == 1) {
        If InStr(Selection, "/")
            outstr := StrReplace(Selection, "/" , "\")
        else
        If InStr(Selection, "\")
            outstr := StrReplace(Selection, "\" , "/")
    }
    else if (A_ThisMenuItemPos == 2)
        outstr := StrReplace(Selection, "\" , "\\")
    else if (A_ThisMenuItemPos == 3)
        outstr := StrReplace(Selection, "\\" , "\")
    clipboard_paste(outstr)
Return
