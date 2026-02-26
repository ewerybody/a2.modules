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
    if menu_name == "Cancel"
        Return
    uniformat_replace(_uniformat_get_set_names()[menu_name])
}

uniformat_replace(set_name) {
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

    ; Two-pass replacement using Unicode Private Use Area (U+E000+) chars as
    ; placeholders. PUA chars never appear in normal text, so they can't be
    ; source letters and won't corrupt placeholders mid-loop.
    placeholders := Map()
    pua_idx := 0
    case_sense := data.settings.get("case", 0)

    ; Pass 1: replace all source letters with unique PUA placeholders
    Loop(data.num_letters)
    {
        if InStr(new_string, data.letters[A_Index], !case_sense) {
            count++
            placeholder := Chr(0xE000 + pua_idx++)
            placeholders[placeholder] := data.replacements[A_Index]
            new_string := StrReplace(new_string, data.letters[A_Index], placeholder, !case_sense)
        }
    }

    ; Pass 2: swap all placeholders for the actual replacements
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
    ; Get data from a sets txt by splitting by spaces and
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
    trim_chars := "# "

    FileEncoding "UTF-8"
    Loop Read, letters_file
    {
        line := Trim(A_LoopReadLine)
        if !line
            Continue

        ;Gather settings and put them on the data object
        if (!header_done and string_startswith(line, "#")) {
            line := string_strip_left(line, trim_chars)
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