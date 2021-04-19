details_popup_menu() {
    global details_popup_data, _details_handled_entries, a2data
    _details_handled_entries := []

    count := 0
    for name, _data in details_popup_data {
        Menu, DetailsMenu, Add, %name%, details_popup_handler
        count++
    }
    if (count == 0) {
        MsgBox, There is nothing to popup! Apparently there was no data added yet?
        Return
    }

    Menu, DetailsMenu, Add
    Menu, DetailsMenu, Add, Cancel, details_popup_handler
    Menu, DetailsMenu, Show
    Menu, DetailsMenu, DeleteAll
}

details_popup_handler(menu_name) {

    global details_popup_data, _details_popup_menu_name, _details_handled_entries
    _details_popup_menu_name := menu_name
    these_entries := details_popup_data[menu_name]

    if (menu_name == "Cancel" and !these_entries)
        Return

    if (these_entries.Count() == _details_handled_entries.Length()) {
        _details_cleanup()
        tt("All Pasted! Nothing more to add! :)", 1)
        Return
    }

    for name, _data in these_entries {
        if (!string_is_in_array(name, _details_handled_entries))
            Menu, DetailsSubMenu, Add, %name%, details_entry_handler
    }

    Menu, DetailsSubMenu, Add
    Menu, DetailsSubMenu, Add, Cancel, details_entry_handlerD
    Menu, DetailsSubMenu, Show
    Menu, DetailsSubMenu, DeleteAll
}

details_entry_handler(entry_name) {
    global details_popup_data, _details_popup_menu_name, a2data
    these_entries := details_popup_data[_details_popup_menu_name]

    if (entry_name == "Cancel" and A_ThisMenuItemPos > these_entries.Length())
        Return

    ; entry_name might be a simple number! Make sure this is a string pointing into the object:
    value := details_popup_data[_details_popup_menu_name]["" entry_name ""]
    cmd_path := a2data "modules\a2.modules\DetailsPopup\details_paste_entry.ahk"

    cmd = "%A_AhkPath%" "%cmd_path%" "%value%"
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(cmd)

    errors := exec.StdErr.ReadAll()
    if (errors)
        MsgBox %errors%
    else {
        result := exec.StdOut.ReadAll()
        if (result == 0) {
            global _details_handled_entries
            _details_handled_entries.push(entry_name)
            Menu, DetailsSubMenu, Delete, %entry_name%
            details_popup_handler(_details_popup_menu_name)
        } else
        _details_cleanup()
    }
}

_details_cleanup() {
    global details_popup_data, _details_popup_menu_name, _details_handled_entries
    _details_popup_menu_name :=
    _details_handled_entries :=
}
