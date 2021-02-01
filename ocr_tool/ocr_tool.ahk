; ocr_tool - ocr_tool.ahk
; author: eric
; created: 2021 1 31

ocr_tool() {
    tt("OCR Tool: Draw a rectangle to read from!", 2)
    work_area := screen_get_work_area()
    dimmer := dimmer_create(work_area)
    data := {area: work_area, dimmer: dimmer}
    data := dragtangle("_ocr_tool_dragging", "_ocr_tool_start", "_ocr_tool_read",,, data)
    _ocr_tool_end(data)
}

_ocr_tool_dragging(data) {
    window_cut_hole(data.dimmer, data, data.area)
    ; Tooltip while dragging? We would first need to make sure that the
    ; tool is not reading itself! :D ie when you drag to the top left
    ; text := teadrinker_ocr(data)
    ; tt(StringLen(text) ": " text, 1)
}

_ocr_tool_end(data) {
    dimmer_off()
}

_ocr_tool_read(data) {
    text := teadrinker_ocr(data)
    if (text) {
        Clipboard := text
        tt("OCR Tool: put " StringLen(text) " characters to Clipboard`n" SubStr(text, 1, 100), 2)
    } else
        tt("OCR Tool: Nothing recognized! :/", 2)
}

_ocr_tool_start(data) {
    ; Just turn off the tooltip to not read yourself.
    tt()
}
