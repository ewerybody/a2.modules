uniformat_main() {
    global _uniformat_selection
    _uniformat_selection := clipboard_get()
    if !_uniformat_selection {
        a2tip("UniFormat: Nothing selected!")
        return
    }
    ; Display the menu sorted by filename,
    menu_list := Map()
    for name, file_name in _uniformat_get_set_names()
        menu_list[file_name] := name
    ; menu_list is automatically sorted now
    UniFormatMenu := Menu()
    for i, name in menu_list
        UniFormatMenu.Add(name, _uniformat_handler)

    UniFormatMenu.Add()
    UniFormatMenu.Add("Cancel", _uniformat_handler)
    UniFormatMenu.Show()
}

_uniformat_handler(menu_name, *) {
    uniformat_replace(_uniformat_get_set_names()[menu_name])
}

uniformat_replace(set_name) {
    if set_name == "Cancel"
        Return
    global _uniformat_selection
    data := uniformat_get_letters(set_name)
    if !data
        Return

    if (_uniformat_selection)
        new_string := _uniformat_selection
    else
        new_string := clipboard_get()

    sel_length_before := StrLen(_uniformat_selection)
    _uniformat_selection :=
    count := 0

    ; To prevent double replacements we look up the replacing chars to see
    ; if they appear in the trigger ones to replace these by position later.
    replace_by_pos := []
    Loop(data.num_letters)
        if (string_is_in_array(data.replacements[A_Index], data.letters, A_Index))
            replace_by_pos.push(data.letters[A_Index])

    ; Perform StrReplace for all matching characters
    placeholders := Map()
    case_sense := data.settings.get("case", 0)
    Loop(data.num_letters)
    {
        if InStr(new_string, data.letters[A_Index], !case_sense) {
            count++
            if (string_is_in_array(data.letters[A_Index], replace_by_pos)) {
                Loop(42)
                {
                    placeholder := "<$$" string_random(10) "%%>"
                    if (!InStr(new_string, placeholder))
                        Break
                }
                placeholders[placeholder] := data.replacements[A_Index]
                new_string := StrReplace(new_string, data.letters[A_Index], placeholder, !case_sense)
            }
            else
                new_string := StrReplace(new_string, data.letters[A_Index], data.replacements[A_Index], !case_sense)
        }
    }

    ; Replace again any placeholders we assigned
    for placeholder, replacement in placeholders
        new_string := StrReplace(new_string, placeholder, replacement)

    if data.settings.get("reverse", 0)
        new_string := string_reverse(new_string)

    if !count
        a2tip("UniFormat: Nothing replaced")
    else {
        msg := "UniFormat: Found " count " items to replace."
        if data.settings.get("shrink", 0)
            msg .= "`nCharacters before/now:" sel_length_before "/" StrLen(new_string)
        a2tip(msg, 2)
    }

    clipboard_paste(new_string)
}

uniformat_get_letters(set_name) {
    ; Get data from a sets txt by spliting by spaces and
    ; getting 1st as key and 2nd as value.
    data := {}
    ; `letters` is now a LIST instead of object! lower and upper-case keys would
    ; collide otherwise and if we flip chars and replacements we could NOT have
    ; multiple things being replaced with the same text. Pcheew.
    data.letters := []
    data.replacements := []
    data.num_letters := 0
    data.settings := Map()
    header_done := False

    letters_file := path_neighbor(A_LineFile, "sets\" string_suffix(set_name, ".txt"))
    args := ["case", "reverse", "shrink", "onebyone"]
    trim_chars := ["#", " "]

    FileEncoding "UTF-8"
    Loop Read, letters_file
    {
        line := Trim(A_LoopReadLine)
        if !line
            Continue

        ;Gather settings and put them on the data object
        if (!header_done and string_startswith(line, "#")) {
            line := string_trimLeft(line, trim_chars)
            if !InStr(line, "=")
                Continue
            parts := StrSplit(line, "=",,2)
            if string_is_in_array(parts[1], args)
                data.settings[parts[1]] := parts[2]
            Continue
        }
        header_done := 1

        chars := StrSplit(line, " ")
        data.letters.Push(chars[1])
        data.replacements.Push(chars[2])
        data.num_letters++
    }

    Return data
}

_uniformat_get_set_names() {
    static _uniformat_names := Map()
    if (!_uniformat_names.Count) {
        sets_pattern := path_join(path_neighbor(A_LineFile, "sets"), "*.txt")
        Loop Files, sets_pattern
        {
            if string_startswith(A_LoopFileName, "_ ") ; and !uniformat_show_wip
                Continue
            FileObj := FileOpen(A_LoopFileFullPath, "r", "UTF-8")
            line := FileObj.ReadLine()
            FileObj.Close()
            if string_startswith(line, "# name=")
                name := SubStr(line, 8)
            else
                name := path_split_ext(A_LoopFileName)[1]
            _uniformat_names[name] := A_LoopFileName
        }
    }

    Return _uniformat_names
}