explorer_create_on_paste() {
    token := gdip_startup()
    bitmap := gdipbitmap_from_clipboard()
    if !_is_bitmap(bitmap) {
        gdip_shutdown(token)
        Send, %A_ThisHotkey%
        return
    }

    current_path := explorer_get_path()
    img_name := _explorer_create_on_paste_find_name(current_path)

    title := "ExplorerCreateFile: Image from Clipboard"
    subtitle := "The extension might be .png, .jpg, .gif, .bmp or .tif..."
    if !explorer_create_file_dialog(img_name, current_path, ".png", "Image file", title, subtitle)
    {
        gdip_shutdown(token)
        Return
    }

    ext := path_split_ext(img_name)[2]
    if ext
        img_path := path_join(current_path, img_name)
    else
    {
        if (ExplorerCreateFile_DefaultImageExt)
            ext := ExplorerCreateFile_DefaultImageExt
        else
            ext := ".png"
        img_path := path_join(current_path, img_name ext)
    }

    a2tip("Creating image from clipboard ...")
    gdipbitmap_to_file(bitmap, img_path)
    gdip_shutdown(token)
    explorer_select(img_name)
}

_is_bitmap(bitmap) {
    for _, error_code in [-1, -2, -3, -4] {
        if (error_code == bitmap)
            Return false
    }
    Return true
}

_explorer_create_on_paste_find_name(current_path) {
    base := ExplorerCreateFile_DefaultImageName
    if (ExplorerCreateFile_DefaultImageExt)
        ext := ExplorerCreateFile_DefaultImageExt
    else
        ext := ".png"

    img_name := base ext
    img_path := path_join(current_path, img_name)
    index := 1
    While, FileExist(img_path) {
        index++
        img_name := base index ext
        img_path := path_join(current_path, img_name)
    }
    return img_name
}
