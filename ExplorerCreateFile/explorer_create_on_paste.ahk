explorer_create_on_paste() {
    token := gdip_startup()
    bitmap := gdipbitmap_from_clipboard()
    if !_is_bitmap(bitmap) {
        gdip_shutdown(token)
        Send, %A_ThisHotkey%
        return
    }

    ; file_name := this["file_name"]
    img_name := "Clipboard Image.png"
    msg := "Please enter a name for the new image file:`n"
    msg .= "The extension might be .png, .jpg, .gif, .bmp or .tif..."
    InputBox, img_name, Clipboard Image File Name, %msg%,, 420, 140,,,,, %img_name%

    if ErrorLevel {
        gdip_shutdown(token)
        Return
    }

    current_path := explorer_get_path()
    img_path := path_join(current_path, img_name)
    tt("Creating image from clipboard ...", 1)
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
