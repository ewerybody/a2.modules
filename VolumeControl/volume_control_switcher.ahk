#include <audio>

volume_control_switcher_menu(*) {
    devices := audio_get_output_devices()
    if !devices.Length {
        a2tip("⚠ No audio output devices found!")
        return
    }

    current_id := audio_get_default_output()
    prev_id    := _volume_control_switcher_load_prev(current_id, devices)

    t := i18n_domain('general')
    switcher_menu := Menu()

    ; Top section: current (greyed) + previous as one-click toggle
    current_name := ""
    prev_name    := ""
    for d in devices {
        if d.id = current_id
            current_name := d.name
        if d.id = prev_id
            prev_name := d.name
    }

    label := current_name " (" t['current'] ")"
    switcher_menu.Add(label, (*) => 0)
    switcher_menu.SetIcon(label, A2Icons.check)
    switcher_menu.Disable(label)

    if prev_id != "" && prev_id != current_id {
        switcher_menu.Add(prev_name, _volume_control_switcher_to.Bind(prev_id, current_id))
        switcher_menu.SetIcon(prev_name, A2Icons.switch)
        switcher_menu.Default := prev_name
    }

    ; Separator + all other active devices
    other_count := 0
    for d in devices {
        if d.id = current_id || d.id = prev_id
            continue
        if !other_count
            switcher_menu.Add()  ; separator
        switcher_menu.Add(d.name, _volume_control_switcher_to.Bind(d.id, current_id))
        switcher_menu.SetIcon(d.name, A2Icons.arrow_right)
        other_count++
    }

    switcher_menu.Add()
    switcher_menu.Add(t['cancel'], (*) => 0)
    switcher_menu.SetIcon(t['cancel'], A2Icons.clear)
    switcher_menu.Show()
}

_volume_control_switcher_to(new_id, old_id, *) {
    audio_set_default_output(new_id)
    _volume_control_switcher_save_prev(new_id, old_id)

    ; Resolve friendly name for tooltip
    new_name := new_id
    for d in audio_get_output_devices() {
        if d.id = new_id {
            new_name := d.name
            break
        }
    }
    a2tip("🔊 " new_name)
}


_volume_control_switcher_load_prev(current_id, devices) {
    prev_new := a2.db.find(A_LineFile, "prev_new_id")
    prev_old := a2.db.find(A_LineFile, "prev_old_id")

    ; Cold start: nothing stored yet
    if prev_new = "" && prev_old = ""
        return ""

    prev_id := (prev_new = current_id) ? prev_old : prev_new

    ; Validate: device must still be active
    for d in devices {
        if d.id = prev_id
            return prev_id
    }
    return ""
}

_volume_control_switcher_save_prev(new_id, old_id) {
    a2.db.find_set(A_LineFile, "prev_new_id", new_id)
    a2.db.find_set(A_LineFile, "prev_old_id", old_id)
}
