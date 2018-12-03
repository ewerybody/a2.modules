screen_get_virtual_size(_x, _y, vs_width, vs_height)
this_vs_size := vs_width "," vs_height

FileAppend, %this_vs_size%, *
ExitApp
