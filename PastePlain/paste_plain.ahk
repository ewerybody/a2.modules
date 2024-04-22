; PastePlain - paste_plain.ahk
; author: Eric Werner
; created: 2017 10 20

paste_plain_paste() {
    files := clipboard_get_files()
    if (files)
        paste_plain_build_filesmenu(files)

    else {
        ; It looks Ridiculous! But that's fixes it most of the time.
        ; See our issue here: https://github.com/ewerybody/a2/issues/193
        tmp := ClipboardAll
        Clipboard := Clipboard
        clipboard_paste(Clipboard)
        Clipboard := tmp
        tmp := ""
    }
}

paste_plain_build_filesmenu(files) {
    global PastePlain_ShowFileMenuCheckBox
    has_links := _paste_plain_links_in_files(files)
    num_files := files.maxindex()
    if (!PastePlain_ShowFileMenuCheckBox) {
        clipboard_paste(Clipboard)
        Return
    }
    PastePlainMenu := Menu()
    PastePlainMenu.Add("Paste Paths (" . num_files . ")", paste_plain_files)
    PastePlainMenu.Add("Basenames Only", paste_plain_basename)
    PastePlainMenu.Add("/Forward/Slashes", paste_plain_forward)
    PastePlainMenu.Add("\\Double\\Backslashes", paste_plain_double)

    ; Create another menu destined to become a submenu of the above menu.
    PastePlainClipMenu.Add("Paste Paths (" . num_files . ")", paste_plain_to_clipboard)
    PastePlainClipMenu.Add("Basenames Only", paste_plain_to_clipboard_basenames)
    PastePlainClipMenu.Add("/Forward/Slashes", paste_plain_to_clipboard_forward)
    PastePlainClipMenu.Add("\\Double\\Backslashes", paste_plain_to_clipboard_double)

    PastePlainMenu.Add("To Clipboard", PastePlainClipMenu)

    if has_links
        PastePlainMenu.Add("Paste Shortcut Target Paths", paste_plain_link_paths)

    PastePlainMenu.Show()
}

paste_plain_files() {
    clipboard_paste(Clipboard)
}

paste_plain_basename() {
    clipboard_paste(_paste_plain_basenames())
}

paste_plain_forward() {
    txt := StrReplace(clipboard, "\", "/")
    clipboard_paste(txt)
}

paste_plain_double() {
    txt := StrReplace(clipboard, "\", "\\")
    clipboard_paste(txt)
}

paste_plain_to_clipboard() {
    ; looks weird but it actually converts to a string! ClipboardAll is the non-string one!
    clipboard := clipboard
}

paste_plain_to_clipboard_basenames() {
    clipboard := _paste_plain_basenames()
}

paste_plain_to_clipboard_forward() {
    clipboard := StrReplace(clipboard, "\", "/")
}

paste_plain_to_clipboard_double() {
    clipboard := StrReplace(clipboard, "\", "\\")
}

paste_plain_link_paths() {
    txt := ""
    for i, file_path in clipboard_get_files()
    {
        FileGetShortcut(file_path, &OutTarget)
        if OutTarget
            txt := txt . OutTarget . "`n"
    }
    ; cut the last linebreak and paste
    clipboard_paste(SubStr(txt, 1, -1))
}


; Helper functions ---------------------------------------------------------------------------------

_paste_plain_basenames() {
    txt := ""
    for i, item in clipboard_get_files()
        txt := txt path_basename(item) "`n"
    ; cut the last linebreak and return
    return SubStr(txt, 1, -1)
}

_paste_plain_links_in_files(files) {
    for i, file_path in files
    {
        FileGetShortcut(file_path, &OutTarget)
        if OutTarget
            return true
    }
    return false
}
