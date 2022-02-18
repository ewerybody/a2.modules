uniformat_main() {
    global _uniformat_selection, _uniformat_names
    _uniformat_selection := clipboard_get()
    if !_uniformat_selection {
        a2tip("UniFormat: Nothing selected!")
        return
    }

    _uniformat_names := {}
    menu_names := {}
    sets_pattern := path_join(path_neighbor(A_LineFile, "sets"), "*.txt")
    FileEncoding, UTF-8
    Loop, Files, % sets_pattern
    {
        if (string_startswith(A_LoopFileName, "_ ") and !uniformat_show_wip)
            Continue
        line := FileReadLine(A_LoopFileFullPath, 1)
        if string_startswith(line, "# name=")
            name := SubStr(line, 8)
        else
            name := path_split_ext(A_LoopFileName)[1]
        _uniformat_names[name] := A_LoopFileName
        menu_names[A_LoopFileName] := name
    }

    ; Display the menu sorted by filename
    for file_name, name in menu_names
        Menu, UniFormatMenu, Add, %name%, uniformat_replace

    Menu, UniFormatMenu, Add
    Menu, UniFormatMenu, Add, Cancel, uniformat_replace
    Menu, UniFormatMenu, Show
    Menu, UniFormatMenu, DeleteAll
}

uniformat_replace(set_name) {
    ; static all_letters
    global _uniformat_selection, _uniformat_names
    data := uniformat_get_letters(_uniformat_names[set_name])
    if (set_name == "Cancel" and !data)
        Return

    if (_uniformat_selection)
        new_string := _uniformat_selection
    else
        new_string := clipboard_get()
    _uniformat_selection :=

    current_case := A_StringCaseSense
    count := 0
    if !data.case
        StringCaseSense, On
    for replacement, chars in data.letters {
        if InStr(new_string, chars, !data.case) {
            new_string := StrReplace(new_string, chars, replacement)
            count++
        }
    }
    if !data.case
        StringCaseSense, %current_case%

    if data.reverse
        new_string := string_reverse(new_string)

    clipboard_paste(new_string)

    if !count
        a2tip("UniFormat: Nothing replaced")
    else {
        msg := "UniFormat: Found " count " items to replace."
        if data.shrink
            msg .= "`nCharacters before/now:" StrLen(_uniformat_selection) "/" StrLen(new_string)
        a2tip(msg, 3)
    }
}


uniformat_get_letters(set_name) {
    ; Get data from a sets txt by spliting by spaces and
    ; getting 1st as key and 2nd as value.
    data := {}
    letters := {}
    header_done := False

    letters_file := path_neighbor(A_LineFile, "sets\" string_suffix(set_name, ".txt"))
    args := ["case", "reverse", "shrink"]
    trim_chars := ["#", " "]
    tst := ""

    FileEncoding, UTF-8
    Loop, Read, %letters_file%
    {
        line := Trim(A_LoopReadLine)
        if !line
            Continue

        if (!header_done and string_startswith(line, "#")) {
            line := string_trimLeft(line, trim_chars)
            parts := StrSplit(line, "=",,2)
            if string_is_in_array(parts[1], args)
                data[parts[1]] := parts[2]
            Continue
        }
        header_done := 1

        chars := StrSplit(line, " ")
        tst .= chars[2]
        letters[chars[2]] := chars[1]
    }
    data["letters"] := letters
    Return data
}
