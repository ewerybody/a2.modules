; TestAHK - testahk.ahk
; author: Eric Werner
; created: 2017 7 6

testahk() {
    sel := get_selection()
    
    if (sel == "") {
        tt("testahk: Nothing selected!", 1)
        Return
    }
    
    tt("testahk...", 1)
    testfile = %A_Temp%\_test_ahk.ahk
    FileDelete, %testfile%
    FileAppend, %sel%, %testfile%
    Run, %A_AhkPath% %testfile%
}
