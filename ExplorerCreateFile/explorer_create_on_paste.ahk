explorer_create_on_paste() {
    token := gdip_startup()
    bitmap := gdipbitmap_from_clipboard()
    if !_is_bitmap(bitmap) {
        gdip_shutdown(token)
        Send, %A_ThisHotkey%
        return
    }

    current_path := explorer_get_path()
    img_name := "Clipboard Image.png"
    img_path := path_join(current_path, [img_name])
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
