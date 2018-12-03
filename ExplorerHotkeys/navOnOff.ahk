; ExplorerHotkeys - navOnOff.ahk
; author: Eric Werner
; created: 2018 5 9

ExplorerHotkeys_NavOnOff() {
    ; A little saver method to do this? I used to have trouble with
    ; direct send, now it seems good again :|
    tt("Toggle Navigation Pane", 0.5)
    
    Sleep, 100
    Send, {Alt Down}
    Sleep, 100
    Send, {Alt Up}
    Sleep, 100
    Send, v
    Sleep, 100
    Send, n
    Sleep, 100
    Send, {Enter}
}
