; ExplorerCreateFile - create_file.ahk
; author: eric
; created: 2019 5 1

explorer_create_file_popup() {
    ; TODO: Embedd this into an a2 interface
    global explorer_create_file_data, a2data
    explorer_create_file_data := {Autohotkey: {ext: "ahk", file_name: "ahk_script", content: "", ask: true}, Python: {ext: "py", file_name: "__init__", content: "", ask: true}}

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

explorer_create_file_handler(menu_name) {
    global explorer_create_file_data
    path := explorer_get_path()
    this := explorer_create_file_data[menu_name]
    file_name := this["file_name"]
    if (this["ask"]) {
        InputBox, file_name, %menu_name% File Name, Please enter a name for the new file:,,, 130,,,,, %file_name%
        if ErrorLevel
            Return
    }
    file_path := path "\" file_name "." this["ext"]
    
    if FileExist(file_path) {
        MsgBox, 48, File Already Exists!, There is already a file with that name here!
        return
    }
    content := this["content"]
    FileAppend , %content%, %file_path%
    ; TODO: Find a way to select the new file?
}
