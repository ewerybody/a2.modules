explorer_create_on_paste() {
    token := gdip_startup()
    bitmap := gdipbitmap_from_clipboard()
    if !_is_bitmap(bitmap) {
        gdip_shutdown(token)
        Send, %A_ThisHotkey%
        return
    }

    if (ExplorerCreateFile_DefaultImageExt)
        default_ext := ExplorerCreateFile_DefaultImageExt
    else
        default_ext := ".png"

    current_path := explorer_get_path()
    img_name := path_get_free_name(current_path, ExplorerCreateFile_DefaultImageName, default_ext)

    title := "ExplorerCreateFile: Image from Clipboard"
    subtitle := "The extension might be .png, .jpg, .gif, .bmp or .tif..."
    if !explorer_create_file_dialog(img_name, current_path, ".png", "Image file", title, subtitle)
    {
        gdip_shutdown(token)
        Return
    }

    ext := path_split_ext(img_name)[2]
    if !ext
        img_name := img_name default_ext
    img_path := path_join(current_path, img_name)

    a2tip("Creating image from clipboard ...")
    gdipbitmap_to_file(bitmap, img_path)
    gdip_shutdown(token)

    Send, F5
    Sleep, 1000
    if FileExist(img_path)
        explorer_select(img_name)
    else
        msgbox_error("Could not create image file """ img_name """!", "ExplorerCreateFile: ERROR")
}

_is_bitmap(bitmap) {
    for _, error_code in [-1, -2, -3, -4] {
        if (error_code == bitmap)
            Return false
    }
    Return true
}
