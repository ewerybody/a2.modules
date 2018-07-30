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
    sel := "#SingleInstance force`n" sel
    testfile = %A_Temp%\_a2_test_ahk.ahk
    FileDelete, %testfile%
    FileAppend, %sel%, %testfile%, UTF-8
    Run, %A_AhkPath% %testfile%
}
