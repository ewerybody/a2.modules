; VolumeControl - volume_control.ahk
; author: eric
; created: 2021 2 23

volume_control_up() {
    master_volume := SoundGet()

    global volume_control_log_change, VolumeControl_Increment
    if(volume_control_log_change) {
        new_volume := master_volume*1.445
        if (new_volume < 0.1)
            new_volume := 0.14
    }
    else
        new_volume := master_volume + VolumeControl_Increment
    if (new_volume > 99)
        new_volume := 100

    tt("Master Volume: " Round(new_volume) , 1)
    SoundSet, %new_volume%
}

volume_control_down() {
    master_volume := SoundGet()

    global volume_control_log_change, VolumeControl_Increment
    if(volume_control_log_change)
        new_volume := master_volume*1.445
    else
        new_volume := master_volume - VolumeControl_Increment

    if (new_volume < 0.1)
        new_volume := 0

    tt("Master Volume: " Round(new_volume), 1)
    SoundSet, %new_volume%
}

volume_control_toggle_mute() {
    SoundSet, +1,, Mute
    if SoundGet(, "Mute") == "On"
        tt("Master: Muted", 1)
    else
        tt("Master Volume: " Round(SoundGet()), 1)
}
