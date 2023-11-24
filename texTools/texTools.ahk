; texTools - texTools.ahk
; author: eric
; created: 2021 6 24

texTools_upper() {
    sel := _texTools_selection()
    if (!sel)
        Return

    StringUpper, sel, sel
    clipboard_paste(sel)
    _texTools_reselect(sel)
}

texTools_lower() {
    sel := _texTools_selection()
    if (!sel)
        Return

    StringLower, sel, sel
    clipboard_paste(sel)
    _texTools_reselect(sel)
}

texTools_random_case() {
    sel := _texTools_selection()
    if (!sel)
        Return

    new := ""
    Loop, % StrLen(sel)
    {
        letter := SubStr(sel, A_Index , 1)
        Random, rand, 0, 1
        if (rand)
            StringLower, letter, letter
        else
            StringUpper, letter, letter
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

_textools_reselect(ByRef string) {
    len := StringLen(string)
    SendInput, +{Left %len%}
}
