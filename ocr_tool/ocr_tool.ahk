; ocr_tool - ocr_tool.ahk
; author: eric
; created: 2021 1 31
; #include <teadrinkerocr>
#include <a2dlg>
#include <OCR>
#include <dimmer>
#include <dragtangle>

ocr_tool() {
    ; lang_list := teadrinkerocr_get_available_languages()
    ; a2tip("OCR Tool: Draw a rectangle to read from!`nLanguage: " ocr_tool_Language "`navailable: " string_join(lang_list, ", "), 2)
    a2tip("OCR Tool: Draw a rectangle to read from!`nLanguage: " ocr_tool_Language, 2)
    work_area := screen_get_work_area()
    dimmer := dimmer_create(work_area)
    data := {area: work_area, dimmer: dimmer}
    data := dragtangle(_ocr_tool_dragging, _ocr_tool_start, _ocr_tool_read, a2tip,, data)
    _ocr_tool_end(data)
}

_ocr_tool_dragging(data) {
    window_cut_hole(data.dimmer, data, data.area)
    ; Tooltip while dragging? We would first need to make sure that the
    ; tool is not reading itself! :D ie when you drag to the top left
    ; text := _ocr_text_from_rect(data)
    ; a2tip(StrLen(text) ": " text, 1)
}

_ocr_tool_end(data) {
    dimmer_off()
}

_ocr_text_from_rect(rect_obj) {
    return OCR.FromRect(rect_obj.x, rect_obj.y, rect_obj.w, rect_obj.h, lang?, scale:=1).text
}

_ocr_tool_read(data) {
    ; data.gdip_token := gdip_startup()
    ; data-object was amended with .x .y .w. .h from dragtangle
    if ocr_tool_use_backup {
        text := _orc_tool_call(data, ocr_tool_Language)
        source := "backup"
    } else {
        text := _ocr_text_from_rect(data)
        source := "lib"
    }

    if (text) {
        A_Clipboard := text
        a2tip("OCR Tool (" source "): put " StrLen(text) " characters to Clipboard`n" SubStr(text, 1, 100))
    } else
        a2tip("OCR Tool (" source "): Nothing recognized! :/")
}

_ocr_tool_start(data) {
    ; Just turn off the tooltip to not read yourself.
    a2tip()
}

_orc_tool_call(rect, lang) {
    script_path := path_join(a2.paths.ahklib, "teadrinkerocr.ahk")
    shell := ComObject("WScript.Shell")
    cmd := '"' . A_AhkPath . '" "' . script_path . '"'
    cmd .= " " rect.x " " rect.y " " rect.w " " rect.h " " lang
    exec := shell.Exec(cmd)
    sleep 200
    stderr := exec.StdErr.ReadAll()
    if stderr
        a2dlg_error(stderr)
    return exec.StdOut.ReadAll()
}
