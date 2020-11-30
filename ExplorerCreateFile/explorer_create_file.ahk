explorer_create_file_popup() {
    ; Provide a menu popup to aid simple file creation.

    ; TODO: Embedd this into an a2 interface
    global explorer_create_file_data, a2data
    explorer_create_file_data := {Autohotkey: {ext: "ahk", file_name: "ahk_script", content: "", ask: true}
    , Python: {ext: "py", file_name: "__init__", content: "", ask: true}
    , JSON: {ext: "json", file_name: "some_data", content: "", ask: true}
    , Text: {ext: "txt", file_name: "text", content: "", ask: true}}

    ; add menu entries on demand...
    for name, data in explorer_create_file_data
    {
        Menu, MyMenu, Add, %name%, explorer_create_file_handler
        icon_path := a2data "modules\a2.modules\ExplorerCreateFile\icon_" name ".ico"
        if FileExist(icon_path)
            Menu, MyMenu, Icon, %name%, %icon_path%
    }
    Menu, MyMenu, Show
    Menu, MyMenu, DeleteAll
}

explorer_create_file_handler(menu_name)
{
    global explorer_create_file_data
    path := explorer_get_path()
    this := explorer_create_file_data[menu_name]
    file_name := this["file_name"]
    if (this["ask"]) {
        msg := "Please enter a name for the new file:"
        InputBox, file_name, %menu_name% File Name, %msg%,,, 130,,,,, %file_name%
        if ErrorLevel
            Return
    }

    file_base := file_name "." this["ext"]
    file_path := path "\" file_base

    if FileExist(file_path) {
        MsgBox, 48, File Already Exists, There is already a file with that name here!
    } else {
        content := this["content"]
        FileAppend , %content%, %file_path%

        Send, F5
        sleep 1000
        explorer_select(file_base)
    }
}
