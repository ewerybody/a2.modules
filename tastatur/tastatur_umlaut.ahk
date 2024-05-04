tastatur_umlaut() {
    letters := ["o", "O", "a", "A", "u", "U", "e", "E", "s", "S"]
    umlauts := ["ö", "Ö", "ä", "Ä", "ü", "Ü", "ë", "Ë", "ß", "ẞ"]

    a2tip("umlaut...", 100)
    ih := InputHook("L1 M", "{LControl}{RControl}{LAlt}{RAlt}{LWin}{RWin}{AppsKey}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}")
    ih.Start()
    ih.Wait()
    idx := string_is_in_array(ih.Input, letters)
    if (idx == 0) {
        a2tip("...", 0.6)
        return
    }

    umlaut := umlauts[idx]
    SendInput(umlaut)
    a2tip("Sending " umlaut, 0.5)
}

_umlaut_dummy_func() {
    return
}