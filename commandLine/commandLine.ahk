; commandLine - commandLine.ahk
; author: Oliver Lipkau
; created: 2016 11 11

selectAll() {
    CoordMode, Mouse, Relative
    MouseGetPos, xpos, ypos
    Click, 10, 10
    Send, {up}{up}{up}{right}{up}{up}{up}{enter}
    MouseMove, %xpos%, %ypos%
}

