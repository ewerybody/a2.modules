; PastePlain - paste_plain.ahk
; author: Eric Werner
; created: 2017 10 20

paste_plain_paste() {
    files := files_in_clipboard()
    if (files)
        paste_plain_build_filesmenu(files)
    else
        paste(Clipboard)
}

paste_plain_build_filesmenu(files) {
    global PastePlain_ShowFileMenuCheckBox
    has_links := _paste_plain_links_in_files(files)
    num_files := files.maxindex()
    if (PastePlain_ShowFileMenuCheckBox) {
        Menu, PastePlain_ShowFileMenu, Add, Paste Paths (%num_files%), paste_plain_files
        Menu, PastePlain_ShowFileMenu, Add, Basenames Only, paste_plain_basename
        Menu, PastePlain_ShowFileMenu, Add, /Forward/Slashes, paste_plain_forward
        Menu, PastePlain_ShowFileMenu, Add, \\Double\\Backslashes, paste_plain_double
        
        ; Create another menu destined to become a submenu of the above menu.
        Menu, PastePlain_ShowFileClipMenu, Add, Plain Paths, paste_plain_to_clipboard
        Menu, PastePlain_ShowFileClipMenu, Add, Basenames, paste_plain_to_clipboard_basenames
        Menu, PastePlain_ShowFileClipMenu, Add, /Forward/Slashes, paste_plain_to_clipboard_forward
        Menu, PastePlain_ShowFileClipMenu, Add, \\Double\\Backslashes, paste_plain_to_clipboard_double
        ; Create a submenu in the first menu (a right-arrow indicator). When the user selects it, the second menu is displayed.
        Menu, PastePlain_ShowFileMenu, Add, To Clipboard, :PastePlain_ShowFileClipMenu
        
        if has_links
            Menu, PastePlain_ShowFileMenu, Add, Paste Shortcut Target Paths, paste_plain_link_paths
        
        Menu, PastePlain_ShowFileMenu, Show
        Menu, PastePlain_ShowFileMenu, DeleteAll
    } else
        paste(Clipboard)
}

paste_plain_files() {
    paste(Clipboard)
}

paste_plain_basename() {
    paste(_paste_plain_basenames())
}

paste_plain_forward() {
    StringReplace, txt, clipboard, \, /, All
    paste(txt)
}

paste_plain_double() {
    StringReplace, txt, clipboard, \, \\, All
    paste(txt)
}

paste_plain_to_clipboard() {
    clipboard := clipboard
}

paste_plain_to_clipboard_basenames() {
    clipboard := _paste_plain_basenames()
}

paste_plain_to_clipboard_forward() {
    StringReplace, clipboard, clipboard, \, /, All
}

paste_plain_to_clipboard_double() {
    StringReplace, clipboard, clipboard, \, \\, All
}

paste_plain_link_paths() {
    txt := ""
    for i, file in files_in_clipboard()
    {
        FileGetShortcut, %file%, OutTarget
        if OutTarget
            txt := txt OutTarget "`n"
    }
    StringTrimRight, txt, txt, 1
    paste(txt)
}


; Helper functions ---------------------------------------------------------------------------------

_paste_plain_basenames() {
    txt := ""
    for i, item in files_in_clipboard()
        txt := txt basename(item) "`n"
    StringTrimRight, txt, txt, 1
    return txt
}

_paste_plain_links_in_files(files) {
    for i, item in files
    {
        FileGetShortcut, %item%, OutTarget
        if OutTarget
            return true
    }
    return false
}
