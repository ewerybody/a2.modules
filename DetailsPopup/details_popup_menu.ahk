details_popup_menu() {
    global _details_handled_entries
    _details_handled_entries := []

    DetailsMenu := Menu()
    count := 0
    for name, _data in details_popup_data {
        DetailsMenu.Add(name, details_popup_handler)
        count++
    }
    if (count == 0) {
        MsgBox_info("There is nothing to popup! Apparently there was no data added yet?")
        Return
    }

    DetailsMenu.Add()
    DetailsMenu.Add("Cancel", details_popup_handler)
    DetailsMenu.Show()
}

details_popup_handler(menu_name, *) {
    global _details_popup_menu_name, _details_handled_entries
    _details_popup_menu_name := menu_name
    these_entries := details_popup_data[menu_name]["data"]
    if details_popup_data[menu_name].has("single_item")
        single_item := details_popup_data[menu_name]["single_item"]
    else
        single_item := false

    if (menu_name == "Cancel" and !these_entries)
        Return

    if (single_item AND _details_handled_entries.Length) {
        _details_cleanup()
        return
    }

    if (these_entries.Count == _details_handled_entries.Length) {
        _details_cleanup()
        a2tip("All Pasted!")
        Return
    }

    DetailsSubMenu := Menu()
    for name, _data in these_entries {
        if (!string_is_in_array(name, _details_handled_entries))
            DetailsSubMenu.Add(name, details_entry_handler)
    }

    if (!_details_handled_entries.Length)
        DetailsSubMenu.Add()
    DetailsSubMenu.Add("Cancel", details_entry_handler)
    DetailsSubMenu.Show()
}

details_entry_handler(entry_name, entry_pos, *) {
    global _details_popup_menu_name
    these_entries := details_popup_data[_details_popup_menu_name]["data"]

    if (entry_name == "Cancel" and entry_pos > these_entries.Count)
        Return

    ; entry_name might be a simple number! Make sure this is a string pointing into the object:
    value := these_entries["" entry_name ""]
    cmd_path := path_neighbor(A_LineFile, "details_paste_entry.ahk")

    cmd := '"' . A_AhkPath . '" "' . cmd_path . '" "' . value . '"'
    shell := ComObject("WScript.Shell")
    exec := shell.Exec(cmd)

    errors := exec.StdErr.ReadAll()
    if (errors) {
        MsgBox_error(errors)
        Return
    }

    result := exec.StdOut.ReadAll()
    if (result == 0) {
        global _details_handled_entries
        _details_handled_entries.push(entry_name)
        details_popup_handler(_details_popup_menu_name)
    } else
        _details_cleanup()
}

_details_cleanup() {
    global _details_popup_menu_name, _details_handled_entries
    _details_popup_menu_name := ""
    _details_handled_entries := ""
}
