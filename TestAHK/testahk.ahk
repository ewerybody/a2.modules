; TestAHK - testahk.ahk
; author: Eric Werner
; created: 2017 7 6

testahk() {
    sel := clipboard_get()

    if (sel == "") {
        a2tip("testahk: Nothing selected!", 1)
        Return
    }

    a2tip("testahk...", 1)
    sel := "#SingleInstance force`n" sel
    testfile := A_Temp . "\_a2_test_ahk.ahk"
    if FileExist(testfile)
        FileDelete(testfile)
    FileAppend(sel, testfile, "UTF-8")
    cmd := '"' A_AhkPath '" "' testfile '"'

    if (TestAHK_AHKPath != "." AND FileExist(TestAHK_AHKPath))
        ahk_path := TestAHK_AHKPath
    else
        ahk_path := A_AhkPath
    Run '"' . ahk_path . '" "' . testfile . '"'
}
