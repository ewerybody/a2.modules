; texTools - texTools.ahk
; author: eric
; created: 2021 6 24

texTools_upper() {
    sel := _texTools_selection()
    if (!sel)
        Return

    sel := StrUpper(sel)
    clipboard_paste(sel)
    _texTools_reselect(sel)
}

texTools_lower() {
    sel := _texTools_selection()
    if (!sel)
        Return

    sel := StrLower(sel)
    clipboard_paste(sel)
    _texTools_reselect(sel)
}

texTools_random_case() {
    sel := _texTools_selection()
    if (!sel)
        Return

    new := ""
    Loop(StrLen(sel))
    {
        letter := SubStr(sel, A_Index , 1)
        if (Random(0, 1))
            letter := StrLower(letter)
        else
            letter := StrUpper(letter)
        new .= letter
    }
    clipboard_paste(new)
    _texTools_reselect(sel)
}

_texTools_selection() {
    sel := clipboard_get()
    if (!sel) {
        a2tip("TexTools: Nothing selected!")
        Return 0
    }
    Return sel
}

_textools_reselect(string) {
    len := StrLen(string)
    SendInput("+{Left " . len . "}")
}
