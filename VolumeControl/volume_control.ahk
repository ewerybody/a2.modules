; VolumeControl - volume_control.ahk
; author: eric
; created: 2021 2 23

volume_control_up() {
    master_volume := SoundGet()

    if(volume_control_log_change) {
        new_volume := master_volume*1.445
        if (new_volume < 0.1)
            new_volume := 0.14
    }
    else
        new_volume := master_volume + VolumeControl_Increment
    if (new_volume > 99)
        new_volume := 100

    _volume_control_set(new_volume)
}


_volume_control_set(new_volume) {
    a2tip("Master Volume: " Round(new_volume))
    SoundSet, %new_volume%
    Sleep, 25
}


volume_control_down() {
    master_volume := SoundGet()

    if(volume_control_log_change)
        new_volume := master_volume*0.694
    else
        new_volume := master_volume - VolumeControl_Increment

    if (new_volume < 0.1)
        new_volume := 0

    _volume_control_set(new_volume)
}

volume_control_toggle_mute() {
    SoundSet, +1,, Mute
    if SoundGet(, "Mute") == "On"
        a2tip("Master: Muted")
    else
        a2tip("Master Volume: " Round(SoundGet()))
}
