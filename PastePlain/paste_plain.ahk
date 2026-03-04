; PastePlain - paste_plain.ahk
; author: Eric Werner
; created: 2017 10 20
#include <clipboard>

paste_plain_paste() {
    files := clipboard_get_files()
    if (files)
        paste_plain_build_files_menu(files)

    else {
        ; It looks Ridiculous! But that's fixes it most of the time.
        ; See our issue here: https://github.com/ewerybody/a2/issues/193
        tmp := ClipboardAll()
        A_Clipboard := A_Clipboard
        clipboard_paste(A_Clipboard)
        A_Clipboard := tmp
        tmp := ""
    }
}

paste_plain_build_files_menu(files) {
    global PastePlain_ShowFileMenuCheckBox
    if (!PastePlain_ShowFileMenuCheckBox) {
        clipboard_paste(A_Clipboard)
        Return
    }
    PastePlainMenu := Menu()
    PastePlainMenu.Add("Paste Paths (" . files.Length . ")", paste_plain_files)
    PastePlainMenu.Add("Base Names Only", paste_plain_basename)
    PastePlainMenu.Add("/Forward/Slashes", paste_plain_forward)
    PastePlainMenu.Add("\\Double\\Backslashes", paste_plain_double)

    ; Create another menu destined to become a submenu of the above menu.
    PastePlainClipMenu := Menu()
    PastePlainClipMenu.Add("Paste Paths (" . files.Length . ")", paste_plain_to_clipboard)
    PastePlainClipMenu.Add("Base Names Only", paste_plain_to_clipboard_base_names)
    PastePlainClipMenu.Add("/Forward/Slashes", paste_plain_to_clipboard_forward)
    PastePlainClipMenu.Add("\\Double\\Backslashes", paste_plain_to_clipboard_double)

    PastePlainMenu.Add("To Clipboard", PastePlainClipMenu)

    if _paste_plain_links_in_files(files)
        PastePlainMenu.Add("Paste Shortcut Target Paths", paste_plain_link_paths)

    PastePlainMenu.Show()
}

paste_plain_files(*) {
    clipboard_paste(A_Clipboard)
}

paste_plain_basename(*) {
    clipboard_paste(_paste_plain_base_names())
}

paste_plain_forward(*) {
    txt := StrReplace(A_Clipboard, "\", "/")
    clipboard_paste(txt)
}

paste_plain_double(*) {
    txt := StrReplace(A_Clipboard, "\", "\\")
    clipboard_paste(txt)
}

paste_plain_to_clipboard(*) {
    ; looks weird but it actually converts to a string! ClipboardAll is the non-string one!
    A_Clipboard := A_Clipboard
}

paste_plain_to_clipboard_base_names(*) {
    A_Clipboard := _paste_plain_base_names()
}

paste_plain_to_clipboard_forward(*) {
    A_Clipboard := StrReplace(A_Clipboard, "\", "/")
}

paste_plain_to_clipboard_double(*) {
    A_Clipboard := StrReplace(A_Clipboard, "\", "\\")
}

paste_plain_link_paths(*) {
    txt := ""
    for i, file_path in clipboard_get_files()
    {
        try {
            FileGetShortcut(file_path, &OutTarget)
            if OutTarget
                txt .= OutTarget . "`n"
        }
    }
    ; cut the last linebreak and paste
    clipboard_paste(SubStr(txt, 1, -1))
}


_paste_plain_base_names() {
    txt := ""
    for i, item in clipboard_get_files()
        txt := txt path_basename(item) "`n"
    ; cut the last linebreak and return
    return SubStr(txt, 1, -1)
}

_paste_plain_links_in_files(files) {
    for i, file_path in files
    {
        try {
            FileGetShortcut(file_path, &OutTarget)
            if OutTarget
                return true
        }

    }
    return false
}
