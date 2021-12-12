commandLine_invoke() {
    path := explorer_get_path()

    ControlGetFocus, cl_control, A
    if (cl_control != "Edit1")
        Return

    ControlGetText, cmd, Edit1, A
    If (SubStr(cmd, 1, 2) == "<<")
        hidden := 1
    Else if (!SubStr(cmd, 1, 1))
        Return

    Send,{ESC}

    cl_CommandParameterC := "/k"
    cmd_exe := ComSpec
    if (hidden) {
        cmd := SubStr(cmd, 3)
        Run, %cmd_exe% %cl_CommandParameterC% %cmd%, %path%, hide
    }
    else {
        cmd := SubStr(cmd, 2)
        Run, %cmd_exe% %cl_CommandParameterC% %cmd%, %path%
    }
}
