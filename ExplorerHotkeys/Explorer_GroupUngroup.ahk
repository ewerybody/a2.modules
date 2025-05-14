ExplorerHotkeys_Group() {
    root_path := explorer_get_path()
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

    dir_path := path_join(root_path, ibx.value)
    if DirExist(dir_path) {
        msgbox_error(dir_path "`nalready exists!", "Group Error")
        ExplorerHotkeys_Group()
        return
    }
    DirCreate(dir_path)
    for item_path in items {
        base_name := path_join(dir_path, path_basename(item_path))
        if path_is_file(item_path)
            FileMove(item_path, base_name)
        else if path_is_dir(item_path)
            DirMove(item_path, base_name)
    }

    Send("{F5}")
    Sleep 500
    explorer_try_select(dir_path)
}

ExplorerHotkeys_UnGroup() {
    root_path := explorer_get_path()
    items := explorer_get_selected()
    ask := false
    if (!items.length) {
        items := explorer_get_all()
        ask := true
    }

    folders := []
    files_found := false
    for x in items {
        if path_is_dir(x)
            folders.push(x)
        else if path_is_file(x)
            files_found := true
    }

    if (!folders.length) {
        a2tip("nothing to UnGroup...", 1.5)
        Return
    }

    if ((ask == true) && (files_found)) || (files_found){
        if !msgbox("Would you like to unpack all the " folders.length " folders here continue?", "unpackFolder", 33)
            Return
    }

    files_moved := []
    not_empty := []
    for folder_path in folders {
        items_exist := []
        Loop Files, folder_path . "\*.*"
        {
            new_path := root_path "\" A_LoopFileName
            if FileExist(new_path)
                items_exist.push(new_path)
        }
        if items_exist.length {
            msgbox_error('Already existing!`n' string_join(items_exist, '`n'), 'Ungroup Error')
            return
        }

        a2tip("Ungrouping " . folder_path . " ...")

        Loop Files, folder_path . "\*.*", "FD"
        {
            target_path := root_path . "\" A_LoopFileName
            if path_is_file(A_LoopFileFullPath)
                FileMove(A_LoopFileFullPath, target_path)
            else
                DirMove(A_LoopFileFullPath, target_path)
            files_moved.push(target_path)
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
            not_empty.push(folder_path)
    }

    if (not_empty.length) {
        msgbox_error("not emptied: " string_join(not_empty, "`n"))
    }

    if files_moved.length {
        a2tip("Items moved: " files_moved.length, 2)
        Send("{F5}")
        Sleep 500
        explorer_select(files_moved)
    }
}
