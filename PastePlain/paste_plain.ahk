; PastePlain - paste_plain.ahk
; author: Eric Werner
; created: 2017 10 20

paste_plain_paste() {
    files := files_in_clipboard()
    if (files)
        paste_plain_build_filesmenu()
    else
        paste(Clipboard)
}

paste_plain_build_filesmenu() {
    global PastePlain_ShowFileMenuCheckBox
    if (PastePlain_ShowFileMenuCheckBox) {
        Menu, PastePlain_ShowFileMenu, Add, Paste Paths, paste_plain_files
        Menu, PastePlain_ShowFileMenu, Add, Basenames Only, paste_plain_basename
        Menu, PastePlain_ShowFileMenu, Add, /Forward/Slashes, paste_plain_forward
        Menu, PastePlain_ShowFileMenu, Add, \\Double\\Backspashes, paste_plain_double
        Menu, PastePlain_ShowFileMenu, Show
        Menu, PastePlain_ShowFileMenu, DeleteAll
    } else
        paste(Clipboard)
}

paste_plain_files() {
    paste(Clipboard)
}

paste_plain_basename() {
    txt := ""
    for i, item in files_in_clipboard()
        txt := txt basename(item) "`n"
    StringTrimRight, txt, txt, 1
    paste(txt)
}

paste_plain_forward() {
    StringReplace, txt, clipboard, \, /, All
    paste(txt)
}

paste_plain_double() {
    StringReplace, txt, clipboard, \, \\, All
    paste(txt)
}
