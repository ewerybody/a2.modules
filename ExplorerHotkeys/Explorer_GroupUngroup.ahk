ExplorerHotkeys_Group() {
    xpath := explorer_get_path()
    items := explorer_get_selected()
    if (!items.length) {
        SendInput("^+n")
        Return
    }

    title := "ExplorerHotkeys_Group"
    msg := "Group " items.length " selected items into folder:"
    ibx := InputBox(msg, title, "w420 h110", "New Folder")
    if ibx.Result = "Cancel" or ibx.value = ""
        Return false

    dir_path := path_join(xpath, ibx.value)
    if DirExist(dir_path) {
        msgbox_error(dir_path "`nalready exists!", "Group Error")
        ExplorerHotkeys_Group()
        return
    }
    DirCreate(dir_path)
    for item_path in items {
        if path_is_file(item_path)
            FileMove(item_path, dir_path . "\" A_LoopFileName)
        else if path_is_dir(item_path)
            DirMove(item_path, dir_path . "\" A_LoopFileName)
    }

    Send("{F5}")
    Sleep 500
    explorer_try_select(dir_path)
}

ExplorerHotkeys_UnGroup() {
    xpath := explorer_get_path()
    items := explorer_get_selected()
    ;ask := false
    if (!items.length) {
        items := explorer_get_all()
        ask := true
    }

    folders := []
    filesFound := false
    for x in items {
        if path_is_dir(x)
            folders.push(x)
        else if path_is_file(x)
            filesFound := true
    }

    if (!folders.length) {
        a2tip("nothing to UnGroup...", 1.5)
        Return
    }

    ; msgbox("Folders: " folders.length "`n " string_join(folders) "`nfilesFound:" filesFound)
;     x := folders.length
;     if ((ask == true) && (filesFound)) || (filesFound){
;         if !msgbox("Would you like to unpack all the " x " folders here continue?", "unpackFolder", 33)
;             Return
;     }

    files_moved := 0
    notempty := []
    for folder_path in folders {
        items_exist := []
        Loop Files, folder_path . "\*.*"
        {
            new_path := xpath "\" A_LoopFileName
            if FileExist(new_path)
                items_exist.push(new_path)
        }
        if items_exist.length {
            msgbox_error('Alreay existing!`n' string_join(items_exist, '`n'), 'Ungroup Error')
            return
        }

        Loop Files, folder_path . "\*.*"
        {
            FileMove(A_LoopFileFullPath, xpath . "\" A_LoopFileName)
            files_moved++
        }

        empty := true
        ; checking if all went right
        Loop Files, folder_path "\*.*"
        {
            empty := false
            break
        }
        if empty
            DirDelete(folder_path)
        else
            notempty.push(folder_path)
    }

    if (notempty.length) {
        msgbox_error("not emptied: " string_join(notempty, "`n"))
    }

    if files_moved {
        a2tip("files_moved: " files_moved, 2)
        Send("{F5}")
        Sleep 500
        Send("{Space}")
    }
}
