; texTools - texTools.ahk
; author: teric
; created: 2021 6 24

texTools_upper() {
    sel := clipboard_get()
    StringUpper, OutputVar, sel
    clipboard_paste(OutputVar)
}

texTools_lower() {
    sel := clipboard_get()
    StringLower, OutputVar, sel
    clipboard_paste(OutputVar)
}