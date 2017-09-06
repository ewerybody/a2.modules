; commandLine - commandLine.ahk
; author: Oliver Lipkau
; created: 2016 11 11

commandLine_selectAll() {
    CoordMode, Mouse, Relative
    MouseGetPos, xpos, ypos
    Click Right 10, 10
    Send, {up}{up}{up}{right}{up}{up}{up}{enter}
    MouseMove, %xpos%, %ypos%
}

