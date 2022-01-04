; texTools - texTools.ahk
; author: eric
; created: 2021 6 24

texTools_upper() {
    sel := clipboard_get()
    if (!sel) {
        a2tip("TexTools: Nothing selected!")
        Return
    }

    StringUpper, OutputVar, sel
    clipboard_paste(OutputVar)
    _texTools_reselect(sel)
}

texTools_lower() {
    sel := clipboard_get()
    if (!sel) {
        a2tip("TexTools: Nothing selected!")
        Return
    }

    StringLower, OutputVar, sel
    clipboard_paste(OutputVar)
    _texTools_reselect(sel)
}

_textools_reselect(ByRef string) {
    len := StringLen(string)
    SendInput, +{Left %len%}
}
