explorer_create_file_popup() {
    ; Provide a menu popup to aid simple file creation.

    ; TODO: before throwing this away, make a default?
    ; explorer_create_file_data := {Autohotkey: {ext: "ahk", file_name: "ahk_script", content: "", ask: true}
    ; , Python: {ext: "py", file_name: "__init__", content: "", ask: true}
    ; , JSON: {ext: "json", file_name: "some_data", content: "", ask: true}
    ; , Text: {ext: "txt", file_name: "text", content: "", ask: true}}

    if !explorer_create_file_data
    {
        MsgBox, No files set up!, Please open the user interface of "ExplorerCreateFile" and add at least one file type.
        Return
    }

    for name, data in explorer_create_file_data
    {
        Menu, ExplorerCreateFileMenu, Add, %name%, explorer_create_file_handler
        _explorer_create_file_add_menu_icon(name, data)
    }
    Menu, ExplorerCreateFileMenu, Show
    Menu, ExplorerCreateFileMenu, DeleteAll
}


explorer_create_file_handler(menu_name) {
    data := explorer_create_file_data[menu_name]
    file_name := data["file_name"]
    ext := string_prefix(data["ext"], ".")
    dir_path := explorer_get_path()

    if (data["ask"])
    {
        title := "ExplorerCreateFile: New """ menu_name """ file ..."
        if !explorer_create_file_dialog(file_name, dir_path, ext, """" menu_name """ file", title)
            Return
        ; InputBox, file_name, %menu_name% File Name, %msg%,,, 130,,,,, %file_name%
        ; if ErrorLevel
        ;     Return
    }
    if !file_name
        file_name := menu_name

    if string_endswith(file_name, ext)
        file_path := path_join(dir_path, file_name)
    Else
        file_path := path_join(dir_path, file_name ext)


    if !string_endswith(file_name, ext)
        file_name := file_name . ext

    encoding := data["encoding"]
    content := data["content"]
    try {
        FileAppend, %content%, %file_path%, %encoding%
    } catch err {
        MsgBox err: %err%`nErrorLevel: %ErrorLevel%`nA_LastError: %A_LastError%
    }

    Send, F5
    sleep 1000

    explorer_select(file_name)
}

_explorer_create_file_get_icon_path(name, data) {
    icon_name := data["icon"]
    if (!icon_name) {
        if data["ext"] {
            default_icon := icon_from_type(data["ext"])
            if default_icon
                Return default_icon
        }
        ; Try a backup icon name
        icon_name := "icon_" name ".ico"
    }
    ; We used to have icons shipped with this module..
    ; TODO: maybe a backup from ui/resources?
    icon_path := path_neighbor(A_LineFile, icon_name)
    if FileExist(icon_path)
        return icon_path
}

_explorer_create_file_add_menu_icon(name, data) {
    icon_path := _explorer_create_file_get_icon_path(name, data)
    if !icon_path
        Return

    icon_nr := ""
    if ("," in icon_path) {
        parts := StrSplit(icon_path, ",")
        icon_path := parts[1]
        icon_nr := parts[2]
    }

    if (!FileExist(icon_path)) {
        path := path_expand_env(icon_path)
        ; We don't need to bend icon_path to the found path
        ; Setting icons with %envvars% works right away!
        if (!FileExist(path)) {
            a2log_debug("No icon path:" path, "ExplorerCreateFile")
            Return
        }
    }

    if (icon_nr != "")
        Menu, ExplorerCreateFileMenu, Icon, %name%, %icon_path%, %icon_nr%
    else
        Menu, ExplorerCreateFileMenu, Icon, %name%, %icon_path%
}
