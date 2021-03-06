explorer_create_file_popup() {
    ; Provide a menu popup to aid simple file creation.

    global explorer_create_file_data, a2data
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
        Menu, MyMenu, Add, %name%, explorer_create_file_handler
        icon_path := _explorer_create_file_get_icon_path(name, data)
        if (icon_path) {
            if ("," in icon_path) {
                parts := StrSplit(icon_path, ",")
                icon_path := parts[1]
                icon_nr := parts[2]
                Menu, MyMenu, Icon, %name%, %icon_path%, %icon_nr%
            } else {
                Menu, MyMenu, Icon, %name%, %icon_path%
            }
        }
    }
    Menu, MyMenu, Show
    Menu, MyMenu, DeleteAll
}

explorer_create_file_handler(menu_name) {
    global explorer_create_file_data

    data := explorer_create_file_data[menu_name]
    file_name := data["file_name"]
    if (data["ask"]) {
        msg := "Please enter a name for the new file:"
        InputBox, file_name, %menu_name% File Name, %msg%,,, 130,,,,, %file_name%
        if ErrorLevel
            Return
    }

    if !file_name
        file_name := menu_name
    if string_startswith(data["ext"], ".")
        file_base := file_name . data["ext"]
    else
        file_base := file_name "." data["ext"]
    file_path := path_join(explorer_get_path(), file_base)

    if FileExist(file_path) {
        MsgBox, 48, File Already Exists, There is already a file with that name here!
    } else {
        content := data["content"]
        FileAppend , %content%, %file_path%

        Send, F5
        sleep 1000
    }

    explorer_select(file_base)
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
    icon_path := a2data "modules\a2.modules\ExplorerCreateFile\" icon_name
    if FileExist(icon_path)
        return icon_path
}
