explorer_create_on_paste() {
    ; Ensure default Explorer behaviour with files in clipboard.
    if WinClip.GetFiles()
    {
        Send, %A_ThisHotkey%
        return
    }

    current_path := explorer_get_path()

    for i, image_type in ["png", "jpeg"]
    {
        base64_id := "<img src=""data:image/" image_type ";base64,"
        if string_startswith(Clipboard, base64_id) AND string_endswith(Clipboard, """>")
        {
            _explorer_create_from_base64(current_path, base64_id, image_type)
            Return
        }
    }

    token := gdip_startup()
    bitmap := gdipbitmap_from_clipboard()
    if _is_bitmap(bitmap) {
        _explorer_create_from_clip_bitmap(current_path, bitmap)
        Return
    }

    gdip_shutdown(token)

    ; The Clipboard would already appear empty with a bitmap in it!
    if !Clipboard
    {
        Send, %A_ThisHotkey%
        Return
    }

    ; Disabling Clipboard text to file for now since it's way to easy to mess up
    ; Renaming and writing into Address bar is hard to detext.
    ; _explorer_create_from_text(currcurrent_path)
}


_explorer_create_from_base64(current_path, base64_id, image_type) {
    baselen := StrLen(base64_id)
    base64 := Substr(Clipboard, baselen + 1, StrLen(Clipboard) - baselen - 2)
    default_ext := "." image_type
    file_name := path_get_free_name(current_path, ExplorerCreateFile_DefaultImageName, default_ext)
    title := "ExplorerCreateFile: Image from Clipboard base64 " image_type " data"
    subtitle := "The extension can only be ." image_type "."
    if !explorer_create_file_dialog(file_name, current_path, "." image_type, "Image file", title, subtitle)
        Return

    ext := path_split_ext(file_name)[2]
    if !ext
        file_name := file_name default_ext
    file_path := path_join(current_path, file_name)

    File := FileOpen(file_path, "w")
    File.Write("")
    File.Close()

    nBytes := LC_Str2Bin(bitmap, base64, 0x1)
    File := FileOpen(file_path, "w")
    File.RawWrite(bitmap, nBytes)
    File.Close()

    _explorer_create_finish(file_name)
}

_explorer_create_from_clip_bitmap(current_path, bitmap) {
    if (ExplorerCreateFile_DefaultImageExt)
        default_ext := ExplorerCreateFile_DefaultImageExt

    default_ext := ".png"
    file_name := path_get_free_name(current_path, ExplorerCreateFile_DefaultImageName, default_ext)

    title := "ExplorerCreateFile: Image from Clipboard"
    subtitle := "The extension might be .png, .jpg, .gif, .bmp or .tif..."
    if !explorer_create_file_dialog(file_name, current_path, ".png", "Image file", title, subtitle)
    {
        gdip_shutdown(token)
        Return
    }

    ext := path_split_ext(file_name)[2]
    if !ext
        file_name := file_name default_ext
    file_path := path_join(current_path, file_name)

    a2tip("Creating image from clipboard ...")
    gdipbitmap_to_file(bitmap, file_path)
    gdip_shutdown(token)

    _explorer_create_finish(file_name)
}


_explorer_create_from_text(current_path) {
    default_ext := ".txt"
    file_name := path_get_free_name(current_path, ExplorerCreateFile_DefaultFileName, default_ext)
    title := "ExplorerCreateFile: File from Clipboard contents (" StrLen(ClipBoard) " bytes)"
    subtitle := "The extension might be anything. By default it'll be .txt."
    if !explorer_create_file_dialog(file_name, current_path, default_ext, "Text file", title, subtitle)
        Return

    ext := path_split_ext(file_name)[2]
    if !ext
        file_name := file_name default_ext
    file_path := _append_default_ext(current_path, file_name, default_ext)

    File := FileOpen(file_path, "w")
    File.Write(Clipboard)

    _explorer_create_finish(file_name)
}


_explorer_create_finish(file_name) {
    Loop, 10
    {
        if explorer_select(basename)
            Return
        Sleep, 400
    }

    ; TODO: Use the lib func in future
    ; if explorer_try_select(file_name)
    ;     Return

    msgbox_error("Could not create file """ file_name """!", "ExplorerCreateFile: ERROR")
}


_is_bitmap(bitmap) {
    for _, error_code in [-1, -2, -3, -4] {
        if (error_code == bitmap)
            Return false
    }
    Return true
}

_append_default_ext(current_path, ByRef file_name, default_ext) {
    ext := path_split_ext(file_name)[2]
    if !ext
        file_name := file_name default_ext
    return path_join(current_path, file_name)
}

