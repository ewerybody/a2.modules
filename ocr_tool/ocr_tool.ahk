; ocr_tool - ocr_tool.ahk
; author: eric
; created: 2021 1 31

ocr_tool() {
    global ocr_tool_Language
    lang_list := teadrinkerocr_get_available_languages()
    tt("OCR Tool: Draw a rectangle to read from!`nLanguage: " ocr_tool_Language "`navailable: " string_join(lang_list, ", "), 2)
    work_area := screen_get_work_area()
    dimmer := dimmer_create(work_area)
    data := {area: work_area, dimmer: dimmer}
    data := dragtangle("_ocr_tool_dragging", "_ocr_tool_start", "_ocr_tool_read", "tt",, data)
    _ocr_tool_end(data)
}

_ocr_tool_dragging(data) {
    window_cut_hole(data.dimmer, data, data.area)
    ; Tooltip while dragging? We would first need to make sure that the
    ; tool is not reading itself! :D ie when you drag to the top left
    ; text := teadrinkerocr(data)
    ; tt(StringLen(text) ": " text, 1)
}

_ocr_tool_end(data) {
    dimmer_off()
}

_ocr_tool_read(data) {
    ; data-object was amended with .x .y .w. .h from dragtangle
    global ocr_tool_Language
    text := teadrinkerocr(data, ocr_tool_Language)
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
