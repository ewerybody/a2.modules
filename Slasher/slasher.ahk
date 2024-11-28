; codeTools - slasher.ahk
; author: eric
; created: 2015 6 11
#include <clipboard>


slasher() {
    slasher_menu := Menu()
    slasher_menu.Add("1 \ <> / toggle back/forward", _slasher_toggle)
    slasher_menu.Add("2 \ > \\ double backslashes", _slasher_to_double_backslash)
    slasher_menu.Add("3 \\ > \ single backslashes", _slasher_to_single_backslash)
    slasher_menu.Show()
}

_slasher_toggle(*) {
    Selection := clipboard_get()
    If InStr(Selection, "/")
        outstr := StrReplace(Selection, "/" , "\")
    else If InStr(Selection, "\") {
        ; in this case cleanup double backslashes up-front
        If InStr(Selection, "\\")
            Selection := StrReplace(Selection, "\\" , "\")
        outstr := StrReplace(Selection, "\" , "/")
    } else
        return

    clipboard_paste(outstr)
}

_slasher_to_double_backslash(*) {
    Selection := clipboard_get()
    outstr := StrReplace(Selection, "\" , "\\")
    clipboard_paste(outstr)
}


_slasher_to_single_backslash(*) {
    Selection := clipboard_get()
    outstr := StrReplace(Selection, "\\" , "\")
    clipboard_paste(outstr)
}