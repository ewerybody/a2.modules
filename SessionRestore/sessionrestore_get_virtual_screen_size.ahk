get_virtual_screen_size.(_x, _y, vs_width, vs_height)
this_vs_size := vs_width "," vs_height

MsgBox this_vs_size: %this_vs_size%

FileAppend, %this_vs_size%, *
ExitApp
